import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/report_draft.dart';
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
    if (_key == null || _signature != signature) {
      _key = newIdempotencyKey();
      _signature = signature;
    }
    final ticket = ++_ticket;
    _set(const Submitting());

    final outcome = await api.submit(body, _key!);
    if (ticket != _ticket) return; // reset (Quick Exit / Done) while in flight

    switch (outcome) {
      case SubmitAccepted(:final code):
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
        if (keyConflict) _forget(); // next attempt must use a fresh key
        _set(const UnexpectedResponse());
      case SubmitNotConfigured():
        _forget();
        _set(const NotConfigured());
    }
  }

  /// Reads the saved report and classifies it. This is the startup read.
  ///
  /// An expired record is deleted and reported as [PendingDraftExpired]; it is
  /// never offered for restore and its content is never shown (FR-4.2, FR-4.3).
  /// A corrupt record is deleted and raised as [PendingDraftCorrupt]; an
  /// unreachable store is raised as [PendingDraftUnavailable]. Neither is
  /// swallowed, so a report is never silently dropped.
  ///
  /// Reading the record is all this does: saving it, restoring it and
  /// discarding it on request are T-15 and later.
  Future<PendingDraftReadOutcome> readPendingReport() async {
    final store = pendingStore;
    if (store == null) {
      _pendingOutcome = const PendingDraftAbsent();
      return _pendingOutcome!;
    }
    final outcome = await store.readOrDiscardAt(_clock());
    _pendingOutcome = outcome;
    return outcome;
  }

  /// Drop an old failure message when the user opens the review screen again.
  void acknowledgeFailure() {
    if (_state is! Submitting && _state is! Succeeded && _state is! Idle) {
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
