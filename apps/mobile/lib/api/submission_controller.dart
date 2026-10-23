import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/report_draft.dart';
import '../storage/pending_draft.dart';
import '../storage/pending_draft_store.dart';
import 'report_api.dart';

sealed class SubmissionState {
  const SubmissionState();
}

class Idle extends SubmissionState {
  const Idle();
}

class Submitting extends SubmissionState {
  const Submitting();
}

/// Only ever created from a confirmed 2xx response containing a reference code.
class Succeeded extends SubmissionState {
  const Succeeded(this.code, this.support);
  final String code;
  final SupportOption? support;
}

/// An earlier submission was accepted after the draft had changed.
///
/// The report was filed and its reference code is kept, but the draft on screen
/// is a different one: it is left untouched, with its own key and its own saved
/// record. This is deliberately **not** a [Succeeded] state, so nothing treats
/// the older report as the current draft — the review screen does not navigate
/// to a confirmation screen for it, and the newer draft is not cleared.
class SucceededButDraftChanged extends SubmissionState {
  const SucceededButDraftChanged(this.code, this.support);
  final String code;
  final SupportOption? support;
}

class ValidationFailed extends SubmissionState {
  const ValidationFailed();
}

class NetworkFailed extends SubmissionState {
  const NetworkFailed({required this.timedOut});
  final bool timedOut;
}

class RateLimited extends SubmissionState {
  const RateLimited(this.retryAfterSeconds);
  final int? retryAfterSeconds;
}

class UnexpectedResponse extends SubmissionState {
  const UnexpectedResponse();
}

class NotConfigured extends SubmissionState {
  const NotConfigured();
}

/// The result of saving the pending report.
sealed class SaveOutcome {
  const SaveOutcome();
}

/// The record was written. Nothing about it is reported back: the key and the
/// payload never leave the controller.
final class SaveSucceeded extends SaveOutcome {
  const SaveSucceeded();
}

/// The draft was not complete enough to submit, so nothing was saved. Saving
/// is offered only when the draft would submit (FR-1.4).
final class SaveRefused extends SaveOutcome {
  const SaveRefused(this.reason);

  /// Why nothing was saved. Never contains report content.
  final String reason;
}

/// The result of restoring the pending report.
sealed class RestoreOutcome {
  const RestoreOutcome();
}

/// Nothing was stored, so there is nothing to restore.
final class RestoreNothingSaved extends RestoreOutcome {
  const RestoreNothingSaved();
}

/// The stored record had expired. It was deleted and nothing was restored
/// (FR-4.2, FR-4.3).
final class RestoreExpired extends RestoreOutcome {
  const RestoreExpired(this.createdAt);

  /// When the report was saved, so the user can be told. Never report content.
  final DateTime createdAt;
}

/// The stored record could not be trusted. It was deleted and nothing was
/// restored; the user is told it could not be read (SR-4.2, SR-4.3, RR-4.2).
final class RestoreCorrupt extends RestoreOutcome {
  const RestoreCorrupt();
}

/// The record was restored: the draft, the idempotency key and the payload
/// signature are back in place.
final class RestoreSucceeded extends RestoreOutcome {
  const RestoreSucceeded();
}

/// Owns the in-memory draft and one logical submission. State lives in memory only.
///
/// Idempotency: one random key per logical report. An unchanged retry (even after Back/Forward)
/// reuses the key; any edit to the payload gets a new key. The key is dropped after success,
/// reset, or a key conflict. Nothing is retried automatically.
class SubmissionController extends ChangeNotifier {
  SubmissionController({
    required this.api,
    ReportDraft? draft,
    this.pendingStore,
    PendingDraftClock? clock,
  })  : draft = draft ?? ReportDraft(),
        _clock = clock ?? DateTime.now;

  final ReportApi api;
  final ReportDraft draft;

  /// Where the saved report lives, when the app has a store to read from.
  /// Null when the app has no store, for example in tests that do not exercise
  /// the pending report.
  final PendingDraftStore? pendingStore;

  /// The source of "now" for expiry decisions. Injected so expiry is
  /// deterministic under test (T-14).
  final PendingDraftClock _clock;

  PendingDraftReadOutcome? _pendingOutcome;

  /// The outcome of the last [readPendingReport] call, so the UI can tell the
  /// user about an expired report (T-14, FR-4.3).
  PendingDraftReadOutcome? get pendingOutcome => _pendingOutcome;

  /// A store failure from [readPendingReport], if one happened.
  ///
  /// The startup read catches [PendingDraftCorrupt] and
  /// [PendingDraftUnavailable] rather than propagating them, so the app does
  /// not crash on launch and the welcome screen can show a banner. The error
  /// is surfaced here so T-16 and the UI can react to it (FR-4.3, SR-4.2).
  PendingDraftStoreException? _pendingReadError;
  PendingDraftStoreException? get pendingReadError => _pendingReadError;

  SubmissionState _state = const Idle();
  SubmissionState get state => _state;
  bool get isSubmitting => _state is Submitting;

  String? _key;
  String? _signature;
  int _ticket = 0;

  /// For tests: the key that the next retry of an unchanged report would use.
  @visibleForTesting
  String? get currentKey => _key;

  void _set(SubmissionState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> submit() async {
    if (_state is Submitting) return; // rapid double taps
    if (draft.incident == null || draft.support == null) {
      _set(const ValidationFailed());
      return;
    }
    final body = ReportApi.payload(draft);
    final signature = jsonEncode(body);
    // Captured before the request is sent: it describes the report that was
    // sent, even if the draft changes while the request is in flight.
    final submittedSupport = draft.support;
    if (_key == null || _signature != signature) {
      _key = newIdempotencyKey();
      _signature = signature;
    }
    final ticket = ++_ticket;
    _set(const Submitting());

    final outcome = await api.submit(body, _key!);
    if (ticket != _ticket) return; // reset (Quick Exit / Done) while in flight

    // The draft may have changed while the request was in flight. The result
    // still belongs to the report that was sent, so it is never applied to a
    // newer draft as if it were that draft's result.
    final draftChanged = jsonEncode(ReportApi.payload(draft)) != signature;

    switch (outcome) {
      case SubmitAccepted(:final code):
        if (draftChanged) {
          // The report that was sent is not the draft on screen. Keep the code,
          // keep the newer draft, its key and its saved record, and do not
          // navigate to a confirmation screen that would present the older
          // report as the current one.
          _set(SucceededButDraftChanged(code, submittedSupport));
          return;
        }
        final support = draft.support;
        _forget();
        draft.clear();
        _set(Succeeded(code, support));
      case SubmitRejected():
        _set(const ValidationFailed());
      case SubmitRateLimited(:final retryAfterSeconds):
        _set(RateLimited(retryAfterSeconds));
      case SubmitNetworkFailure(:final timedOut):
        _set(NetworkFailed(timedOut: timedOut));
      case SubmitUnexpected(:final keyConflict):
        // A key conflict only invalidates the key that was used for this
        // request. A newer draft keeps its own key.
        if (keyConflict && !draftChanged) _forget();
        _set(const UnexpectedResponse());
      case SubmitNotConfigured():
        if (!draftChanged) _forget();
        _set(const NotConfigured());
    }
  }

  /// Reads the saved report and classifies it. This is the startup read.
  ///
  /// The result is cached in [pendingOutcome] and the stored error in
  /// [pendingReadError], so the UI can rebuild without re-reading the store.
  /// [readPendingReport] may be called again (for example when the user taps
  /// Restore) and will re-read; each call reflects the current store state.
  ///
  /// * A record that is absent gives [PendingDraftAbsent].
  /// * A valid record that has not expired gives [PendingDraftAvailable] and is
  ///   left in storage, so it can be offered for restore.
  /// * A record that has expired is deleted and gives [PendingDraftExpired]. It
  ///   is never offered for restore and its content is never shown (FR-4.2,
  ///   FR-4.3). A deletion that fails is raised as [PendingDraftDeleteFailed]
  ///   and the record is left in place — the failure is never reported as
  ///   success (RR-4.3).
  /// * A corrupt record is deleted and stored in [pendingReadError] as
  ///   [PendingDraftCorrupt]; an unreachable store is stored as
  ///   [PendingDraftUnavailable]. Neither is swallowed — [restorePending]
  ///   re-raises or returns the appropriate outcome — and neither is turned
  ///   into silence, so the welcome screen can report it (T-13, T-14, T-16).
  ///
  /// Reading the record is all this does: saving it, restoring it and
  /// discarding it on request are T-15 and later.
  Future<PendingDraftReadOutcome> readPendingReport() async {
    final store = pendingStore;
    if (store == null) {
      _pendingOutcome = const PendingDraftAbsent();
      _pendingReadError = null;
      notifyListeners();
      return _pendingOutcome!;
    }

    try {
      final outcome = await store.readOrDiscardAt(_clock());
      _pendingOutcome = outcome;
      _pendingReadError = null;
      notifyListeners();
      return outcome;
    } on PendingDraftCorrupt catch (e) {
      // The record was deleted by the read; surface the failure so the UI
      // can tell the user (SR-4.2) instead of crashing the startup read (T-16).
      _pendingOutcome = const PendingDraftAbsent();
      _pendingReadError = e;
      notifyListeners();
      return _pendingOutcome!;
    } on PendingDraftDeleteFailed catch (e) {
      // Deletion of a corrupt or expired record failed: the record is still
      // on the device, but it is not safe to offer for restore. Catch it here
      // so it never crashes startup, surface it as an explicit error state,
      // and never report the deletion as successful (RR-4.3, T-16).
      _pendingOutcome = const PendingDraftAbsent();
      _pendingReadError = e;
      notifyListeners();
      return _pendingOutcome!;
    } on PendingDraftUnavailable catch (e) {
      // The store could not be reached: distinguish from "nothing saved"
      // (T-13, T-16).
      _pendingOutcome = const PendingDraftAbsent();
      _pendingReadError = e;
      notifyListeners();
      return _pendingOutcome!;
    }
  }

  /// Saves the current draft as the pending report.
  ///
  /// Saving is refused unless the draft would submit — an incident type and a
  /// support choice are chosen (FR-1.4). The stored record holds the exact
  /// payload that would be sent, the idempotency key issued for that payload,
  /// the creation time and the expiry time (FR-1.3, FR-1.2).
  ///
  /// The key written is the controller's current key when that key was issued
  /// for this exact payload; otherwise a key is generated for the record.
  ///
  /// Saving does not modify the in-memory draft or the in-flight submission
  /// state, and it never replaces a key the controller already holds. When the
  /// controller holds no key at all, the key the record now carries is
  /// installed — but only after the record has been written successfully, so a
  /// failed write leaves the controller exactly as it was (FR-1.5 as amended).
  ///
  /// That last step is what keeps a saved report and a same-session submission
  /// of identical content on one key. With two keys, an ambiguous outcome
  /// followed by a restart and a restore would send the retry under a second
  /// key, and the server would store a second report for the same content
  /// (RR-3.1).
  Future<SaveOutcome> savePending() async {
    final store = pendingStore;
    if (store == null) {
      return const SaveRefused('saving is not available on this device');
    }
    if (draft.incident == null || draft.support == null) {
      return const SaveRefused('the report is not finished yet');
    }

    final body = ReportApi.payload(draft);
    final signature = jsonEncode(body);
    // The current key applies only while it was issued for this exact payload;
    // an edited report is a different logical report and gets its own key.
    final keyAppliesToThisPayload = _key != null && _signature == signature;
    final candidate = keyAppliesToThisPayload ? _key! : newIdempotencyKey();
    final createdAt = _clock();
    final record = PendingDraft(
      payload: body,
      key: candidate,
      createdAt: createdAt.millisecondsSinceEpoch,
      expiresAt: PendingDraft.expiryFor(createdAt),
    );

    await store.write(record);

    // Only now that the record is safely stored. The controller's key always
    // belongs to the payload it is working on: when the current key applies to
    // this payload it is kept, and otherwise the key the record now carries is
    // installed. Either way the saved report and the next submission of the
    // same content share one key, so an ambiguous outcome followed by a restart
    // and a restore cannot send the retry under a second key (FR-1.5 as
    // amended, RR-3.1). A request already in flight is unaffected: it captured
    // its own key and body before it was sent.
    _key = candidate;
    _signature = signature;
    return const SaveSucceeded();
  }

  /// Restores the pending report: the draft, the idempotency key and the
  /// payload signature.
  ///
  /// Installing the stored signature alongside the stored key is what makes the
  /// first submit after a restore reuse that exact key (FR-2.3, RR-2.1,
  /// RR-3.2). Without it the next submit would see a missing or mismatched
  /// signature and mint a new key.
  ///
  /// An absent, expired or corrupt record gives its own outcome and restores
  /// nothing. A storage failure is raised, so it stays distinguishable from
  /// corruption and is never treated as "there was nothing saved".
  Future<RestoreOutcome> restorePending() async {
    // readPendingReport catches corrupt/unavailable storage failures and
    // caches them in _pendingReadError, so they do not crash the startup
    // read. restorePending surfaces them as outcomes or re-raises them here.
    final outcome = await readPendingReport();

    final error = _pendingReadError;
    if (error is PendingDraftCorrupt) {
      // The record was deleted by the read; the user is told it could not be
      // read (SR-4.2).
      return const RestoreCorrupt();
    }
    if (error is PendingDraftDeleteFailed) {
      // Deletion of a corrupt or expired record failed: the record is still
      // on the device but cannot be trusted or offered for restore. Tell the
      // user it could not be read or removed (RR-4.3, T-16).
      return const RestoreCorrupt();
    }
    if (error is PendingDraftUnavailable) {
      // The store could not be reached: distinguish from "nothing saved"
      // (T-13, T-14).
      throw error;
    }

    switch (outcome) {
      case PendingDraftAbsent():
        return const RestoreNothingSaved();
      case PendingDraftExpired(:final createdAt):
        return RestoreExpired(createdAt);
      case PendingDraftAvailable(draft: final stored):
        draft.restoreFrom(stored.payload);
        _key = stored.key;
        _signature = jsonEncode(stored.payload);
        return const RestoreSucceeded();
    }
  }

  /// Discards the pending report: the stored record is deleted, and the
  /// in-memory draft and key are cleared.
  ///
  /// The record is deleted first. If the deletion fails, the failure is raised
  /// and nothing is cleared, so the report is never reported as discarded when
  /// it is still stored (RR-4.3).
  Future<void> discardPending() async {
    final store = pendingStore;
    if (store != null) {
      await store.delete();
    }
    _forget();
    draft.clear();
  }

  /// Drop an old failure message when the user opens the review screen again.
  void acknowledgeFailure() {
    if (_state is! Submitting &&
        _state is! Succeeded &&
        _state is! SucceededButDraftChanged &&
        _state is! Idle) {
      _set(const Idle());
    }
  }

  /// Done / Quick Exit: forget the draft, key and any state.
  void reset() {
    _ticket++;
    _forget();
    draft.clear();
    _set(const Idle());
  }

  void _forget() {
    _key = null;
    _signature = null;
  }
}
