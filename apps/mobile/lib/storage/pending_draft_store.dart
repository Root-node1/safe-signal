import 'pending_draft.dart';

/// Where the one pending report is kept between launches.
///
/// The controller and the screens are written against this interface only, so
/// the storage mechanism can be replaced without touching them (SR-3.4).
///
/// Contract:
/// * One record at a time.
/// * [read] returns `null` when no record is stored.
/// * [write] replaces any existing record.
/// * [delete] is idempotent: deleting when nothing is stored succeeds.
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
