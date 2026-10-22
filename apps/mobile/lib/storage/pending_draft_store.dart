import 'pending_draft.dart';

/// Base class for every failure the pending-draft store reports.
///
/// A store failure is always one of four kinds, and the kind tells the caller
/// what to do and what to say (T-13):
///
/// * [PendingDraftCorrupt] — the stored value is not the record we intended.
///   It is deleted and the user is told (SR-4.2, RR-4.2).
/// * [PendingDraftUnavailable] — the storage could not be reached. The stored
///   record may be perfectly good; it just could not be read now.
/// * [PendingDraftWriteFailed] — the record was not written.
/// * [PendingDraftDeleteFailed] — the record was not deleted.
///
/// None of these reasons ever contains an incident payload, a submission key or
/// a stored value (SR-5.1).
class PendingDraftStoreException implements Exception {
  const PendingDraftStoreException(this.reason, {this.cause});

  /// Why the operation failed. Never contains report content or a stored value.
  final String reason;

  /// The failure that led to this one, when there was one.
  final PendingDraftStoreException? cause;

  @override
  String toString() => '$runtimeType: $reason';
}

/// The stored value is not the record we intended: it does not parse, it is
/// written in a format this version does not understand, or its checksum does
/// not verify. Such a record is never returned to the caller and is deleted
/// (SR-4.2, SR-4.3, RR-4.2).
class PendingDraftCorrupt extends PendingDraftStoreException {
  const PendingDraftCorrupt(super.reason);
}

/// The storage could not be reached, so the operation could not be attempted.
/// This is not corruption: the stored record may be intact (T-13).
class PendingDraftUnavailable extends PendingDraftStoreException {
  const PendingDraftUnavailable(super.reason);
}

/// The record could not be written. The store is left as it was (T-13).
class PendingDraftWriteFailed extends PendingDraftStoreException {
  const PendingDraftWriteFailed(super.reason);
}

/// The record could not be deleted. The record is left intact — nothing is
/// half-deleted — and the failure is reported rather than swallowed (RR-4.3).
class PendingDraftDeleteFailed extends PendingDraftStoreException {
  const PendingDraftDeleteFailed(super.reason, {super.cause});
}

/// The source of "now" for expiry decisions.
///
/// Injected so that expiry is deterministic under test and follows the device
/// clock in the app. The device clock is a best-effort bound: a clock set far in
/// the future can expire a record early, a clock set far in the past can extend
/// its life. That is accepted and documented (`design.md` § 4.5).
typedef PendingDraftClock = DateTime Function();

/// The outcome of reading the stored pending report.
///
/// The three cases are deliberately distinct: an absent record, a record that
/// may be offered for restore, and a record that had expired and was deleted.
/// Corruption and an unavailable store are *not* outcomes — they are failures
/// and are raised, so a report is never silently dropped (T-13, T-14).
sealed class PendingDraftReadOutcome {
  const PendingDraftReadOutcome();
}

/// No record is stored. Nothing to restore and nothing to tell the user.
final class PendingDraftAbsent extends PendingDraftReadOutcome {
  const PendingDraftAbsent();
}

/// A valid record that has not expired. It may be offered for restore.
final class PendingDraftAvailable extends PendingDraftReadOutcome {
  const PendingDraftAvailable(this.draft);

  final PendingDraft draft;
}

/// The record had expired. It has been deleted, it is never offered for
/// restore, and its content is never shown (FR-4.2, FR-4.3).
///
/// Only the time the report was saved is kept, so the user can be told *when*
/// the report they had saved expired — never what it contained.
final class PendingDraftExpired extends PendingDraftReadOutcome {
  const PendingDraftExpired({required this.createdAt});

  /// When the report was saved, from the stored creation timestamp.
  final DateTime createdAt;
}

/// Where the one pending report is kept between launches.
///
/// The controller and the screens are written against this interface only, so
/// the storage mechanism can be replaced without touching them (SR-3.4).
///
/// Contract:
/// * One record at a time.
/// * [read] returns `null` when no record is stored.
/// * [read] throws [PendingDraftCorrupt] for a record that cannot be trusted,
///   and [PendingDraftUnavailable] when the storage could not be reached. A
///   storage failure is never reported as "no record" (T-13).
/// * [write] replaces any existing record, and throws
///   [PendingDraftWriteFailed] when it could not be written.
/// * [delete] is idempotent: deleting when nothing is stored succeeds. When it
///   fails it throws [PendingDraftDeleteFailed] and the record stays (T-13).
/// * [isAvailable] says whether the store can currently be used. When it is
///   `false`, saving is unavailable; an implementation never falls back to
///   plaintext storage.
abstract class PendingDraftStore {
  /// The stored record, or `null` when none is stored.
  Future<PendingDraft?> read();

  /// Store [draft], replacing any existing record.
  Future<void> write(PendingDraft draft);

  /// Remove the stored record. Succeeds when there is none.
  Future<void> delete();

  /// Whether the store can currently be used.
  Future<bool> isAvailable();
}

/// Reads a pending report and discards it if it cannot be trusted.
///
/// The sequence is read → validate → on corruption, delete the record and
/// rethrow a typed [PendingDraftCorrupt] so the caller can tell the user
/// (SR-4.2, SR-4.3, RR-4.2). The helper is defined against the interface, so it
/// works for any implementation and never reaches into a concrete store.
///
/// * A record that is absent returns `null` — absence is not a failure.
/// * A record whose checksum does not verify is never returned: it is deleted
///   and [PendingDraftCorrupt] is rethrown.
/// * A storage failure is propagated unchanged. It is never treated as an
///   absent record, and nothing is deleted, because the stored record may be
///   perfectly good.
/// * If the deletion of a corrupt record fails, [PendingDraftDeleteFailed] is
///   raised with the corruption as its cause. The failure is never reported as
///   success (RR-4.3).
extension PendingDraftStoreReadOrDiscard on PendingDraftStore {
  Future<PendingDraft?> readOrDiscard() async => _readValidating();

  /// Reads the stored record at [now] and applies the expiry policy.
  ///
  /// * A record that is absent gives [PendingDraftAbsent].
  /// * A valid record that has not expired gives [PendingDraftAvailable] and is
  ///   left in storage, so it can be offered for restore.
  /// * A record that has expired is deleted and gives [PendingDraftExpired]. It
  ///   is never offered for restore and its content is never shown (FR-4.2,
  ///   FR-4.3). A deletion that fails is raised as
  ///   [PendingDraftDeleteFailed] and the record is left in place — the
  ///   failure is never reported as success (RR-4.3).
  /// * A corrupt record is deleted and reported as [PendingDraftCorrupt], and an
  ///   unreachable store is reported as [PendingDraftUnavailable]. Neither is
  ///   turned into an outcome, so a report is never silently dropped.
  Future<PendingDraftReadOutcome> readOrDiscardAt(DateTime now) async {
    final draft = await _readValidating();
    if (draft == null) return const PendingDraftAbsent();
    if (draft.isExpired(now)) {
      await _deleteExpiredRecord();
      return PendingDraftExpired(
        createdAt: DateTime.fromMillisecondsSinceEpoch(draft.createdAt),
      );
    }
    return PendingDraftAvailable(draft);
  }

  /// Reads the record and checks that it can be trusted. A record that cannot
  /// is deleted and reported, never returned.
  Future<PendingDraft?> _readValidating() async {
    PendingDraft? draft;
    PendingDraftCorrupt? corrupt;

    try {
      draft = await read();
    } on PendingDraftCorrupt catch (e) {
      corrupt = e;
    }

    if (corrupt != null) {
      await _deleteCorruptRecord(corrupt);
      throw corrupt;
    }
    if (draft == null) return null;
    if (!draft.verifyChecksum()) {
      const mismatch = PendingDraftCorrupt('checksum does not match');
      await _deleteCorruptRecord(mismatch);
      throw mismatch;
    }
    return draft;
  }

  /// Deletes a corrupt record, keeping the failure explicit. A deletion that
  /// does not happen is never reported as a success.
  Future<void> _deleteCorruptRecord(PendingDraftCorrupt corrupt) async {
    try {
      await delete();
    } on PendingDraftDeleteFailed {
      throw PendingDraftDeleteFailed(
        'corrupt record could not be deleted',
        cause: corrupt,
      );
    }
  }

  /// Deletes an expired record. A deletion that fails is raised, never
  /// swallowed (RR-4.3).
  Future<void> _deleteExpiredRecord() async {
    try {
      await delete();
    } on PendingDraftDeleteFailed {
      throw const PendingDraftDeleteFailed(
        'expired record could not be deleted',
      );
    }
  }
}
