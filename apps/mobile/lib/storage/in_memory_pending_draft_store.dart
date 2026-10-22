import 'pending_draft.dart';
import 'pending_draft_store.dart';

/// True in a release (product) build, false in debug, profile and test runs.
const bool _kIsReleaseBuild = bool.fromEnvironment('dart.vm.product');

/// A [PendingDraftStore] that holds one record in memory only.
///
/// It exists for tests and as the fallback when the platform keystore is
/// unavailable. It is never a silent production fallback over plaintext:
/// selecting it in a release build requires an explicit [releaseReason], which
/// is logged through [log] (T-11, FR-9.3). Nothing is persisted; the record is
/// lost when the process ends.
class InMemoryPendingDraftStore implements PendingDraftStore {
  InMemoryPendingDraftStore({
    String? releaseReason,
    void Function(String message)? log,
    bool isReleaseBuild = _kIsReleaseBuild,
  }) {
    if (!isReleaseBuild) return;
    if (releaseReason == null || releaseReason.trim().isEmpty) {
      throw StateError(
        'InMemoryPendingDraftStore cannot be used in a release build '
        'without an explicit reason',
      );
    }
    (log ?? _noLog)('InMemoryPendingDraftStore selected in release build: '
        '$releaseReason');
  }

  PendingDraft? _record;

  @override
  Future<PendingDraft?> read() async {
    final record = _record;
    if (record == null) return null;
    // A record that does not verify is never handed to the caller, exactly as
    // in the keystore-backed store (T-13, SR-4.2).
    if (!record.verifyChecksum()) {
      throw const PendingDraftCorrupt('checksum does not match');
    }
    return record;
  }

  @override
  Future<void> write(PendingDraft draft) async {
    _record = draft;
  }

  @override
  Future<void> delete() async {
    _record = null;
  }

  @override
  Future<bool> isAvailable() async => true;
}

void _noLog(String message) {}
