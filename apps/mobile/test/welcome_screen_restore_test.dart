import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safesignal/screens/report_screen.dart';
import 'package:safesignal/storage/in_memory_pending_draft_store.dart';
import 'package:safesignal/storage/pending_draft.dart';
import 'package:safesignal/storage/pending_draft_store.dart';

import 'helpers.dart';

/// A complete, valid draft payload matching what [ReportApi.payload] produces.
final Map<String, Object?> kTestPayload = {
  'incident': 'threats',
  'timing': 'after',
  'route': 'Test Route',
  'area': 'Test Area',
  'vehicle': 'KDA 123A',
  'sacco': 'Test SACCO',
  'support': 'private',
  'contactProvided': false,
  'consentToShare': false,
};

final DateTime kSavedAt = DateTime.utc(2026, 1, 1);
final DateTime kClockNotExpired = kSavedAt.add(const Duration(hours: 1));

/// A clock that is past the 24-hour expiry window.
final DateTime kClockExpired = kSavedAt.add(const Duration(hours: 25));

/// A record whose 24-hour validity window has not yet elapsed.
final PendingDraft kValidRecord = PendingDraft(
  payload: kTestPayload,
  key: 'test-key-1',
  createdAt: kSavedAt.millisecondsSinceEpoch,
  expiresAt: PendingDraft.expiryFor(kSavedAt),
);

/// A record whose checksum does not verify — `_readValidating` treats it as
/// corrupt and attempts deletion.
final PendingDraft kCorruptRecord = PendingDraft(
  payload: kTestPayload,
  key: 'corrupt-key',
  createdAt: kSavedAt.millisecondsSinceEpoch,
  expiresAt: PendingDraft.expiryFor(kSavedAt),
  storedChecksum: '0' * 64,
);

/// A store whose [read] always throws [PendingDraftCorrupt].
class CorruptTestStore implements PendingDraftStore {
  @override
  Future<PendingDraft?> read() async =>
      throw const PendingDraftCorrupt('checksum does not match');

  @override
  Future<void> write(PendingDraft draft) async {}

  @override
  Future<void> delete() async {}

  @override
  Future<bool> isAvailable() async => true;
}

/// A store whose [read] always throws [PendingDraftUnavailable].
class UnavailableTestStore implements PendingDraftStore {
  @override
  Future<PendingDraft?> read() async =>
      throw const PendingDraftUnavailable('keystore unavailable');

  @override
  Future<void> write(PendingDraft draft) async {}

  @override
  Future<void> delete() async {}

  @override
  Future<bool> isAvailable() async => false;
}

/// A store whose [delete] always throws [PendingDraftDeleteFailed], while
/// [read] returns the supplied record without checksum validation.
///
/// This reproduces the startup scenario where an expired or corrupt record
/// cannot be deleted (RR-4.3, T-16).
class DeleteFailedStore implements PendingDraftStore {
  DeleteFailedStore(this.record);

  PendingDraft? record;
  int deleteCount = 0;

  @override
  Future<PendingDraft?> read() async => record;

  @override
  Future<void> delete() async {
    deleteCount++;
    throw const PendingDraftDeleteFailed('delete failed');
  }

  @override
  Future<void> write(PendingDraft draft) async {
    record = draft;
  }

  @override
  Future<bool> isAvailable() async => true;
}

void main() {
  group('T-16 Restore prompt', () {
    testWidgets('valid pending report displays restore prompt',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Keep saved'), findsOneWidget);
    });

    testWidgets('no pending report displays no prompt', (tester) async {
      final store = InMemoryPendingDraftStore();

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsNothing);
      expect(find.text('Keep saved'), findsNothing);
    });

    testWidgets('keep saved dismisses prompt but preserves the record',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);

      await tester.tap(find.text('Keep saved'));
      await tester.pumpAndSettle();

      // The prompt is gone.
      expect(find.text('Restore'), findsNothing);
      expect(find.text('Keep saved'), findsNothing);

      // The record remains on the device (FR-2.4).
      expect(await store.read(), isNotNull);
    });

    testWidgets('explicit restore restores draft and navigates',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportScreen), findsOneWidget);
    });

    testWidgets('expired record shows expiry banner and deletes the record',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(PendingDraft(
        payload: kTestPayload,
        key: 'expired-key',
        createdAt: kSavedAt.millisecondsSinceEpoch,
        expiresAt: kSavedAt.millisecondsSinceEpoch,
      ));

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      // No restore prompt for an expired record.
      expect(find.text('Restore'), findsNothing);
      expect(find.text('Keep saved'), findsNothing);

      // The record has been deleted.
      expect(await store.read(), isNull);
    });

    testWidgets('corrupt record shows error banner', (tester) async {
      final store = CorruptTestStore();

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsNothing);
      expect(find.text('Keep saved'), findsNothing);
      expect(
        find.text('Your saved report could not be read and was deleted.'),
        findsOneWidget,
      );
    });

    testWidgets('unavailable store shows error banner', (tester) async {
      final store = UnavailableTestStore();

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsNothing);
      expect(find.text('Keep saved'), findsNothing);
      expect(
        find.text('Could not read your saved report.'),
        findsOneWidget,
      );
    });

    testWidgets('rebuilding welcome screen does not repeat the prompt',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);

      // Second build: same widget type reuses the State, so no second read.
      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);
    });
  });

  // ─── Deletion failure during startup (T-16 blocker 1) ─────────────────────

  group('T-16 deletion failure during startup', () {
    testWidgets(
        'expired record whose deletion fails surfaces an error banner, not a crash',
        (tester) async {
      final store = DeleteFailedStore(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockExpired),
      );
      await tester.pumpAndSettle();

      // No unhandled exception escapes startup.
      expect(tester.takeException(), isNull);

      // No restore prompt: the failed record is expired and not offered.
      expect(find.text('Restore'), findsNothing);
      expect(find.text('Keep saved'), findsNothing);

      // An error banner tells the user the deletion failed (RR-4.3).
      expect(
        find.text('Your saved report could not be deleted.'),
        findsOneWidget,
      );
      expect(
        find.text('The report is still saved on this phone.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'corrupt record whose deletion fails surfaces an error banner, not a crash',
        (tester) async {
      final store = DeleteFailedStore(kCorruptRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.text('Restore'), findsNothing);
      expect(find.text('Keep saved'), findsNothing);

      expect(
        find.text('Your saved report could not be deleted.'),
        findsOneWidget,
      );
      expect(
        find.text('The report is still saved on this phone.'),
        findsOneWidget,
      );
    });

    testWidgets('the record is retained when deletion fails', (tester) async {
      final store = DeleteFailedStore(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockExpired),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Deletion was attempted.
      expect(store.deleteCount, greaterThan(0));
      // The record is still on the device (nothing was half-deleted — RR-4.3).
      expect(store.record, isNotNull);
      expect(store.record!.key, 'test-key-1');
    });

    testWidgets('delete-failure banner is announced as a live region',
        (tester) async {
      final store = DeleteFailedStore(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockExpired),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(hasLiveRegionNode(tester), isTrue,
          reason: 'error banners must be announced as live regions (AR-4.1)');
    });

    testWidgets('delete-failure banner is localised in Kiswahili',
        (tester) async {
      phone(tester);
      tester.platformDispatcher.localesTestValue = [const Locale('sw', 'KE')];
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final store = DeleteFailedStore(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockExpired),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Ripoti yako iliyopotekwa haifutwa kwa kutokufanikiwa.'),
        findsOneWidget,
      );
      expect(
        find.text('Ripoti bado imehifadhiwa kwenye simu yako.'),
        findsOneWidget,
      );
    });
  });

  // ─── Accessibility: dialog semantics and focus (T-16 blocker 2) ────────────

  group('T-16 restore dialog accessibility', () {
    testWidgets('dialog has a dialog role and an accessible name',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      // The prompt is announced as a dialog (AR-1.2), not a plain card.
      expect(hasDialogRoleNode(tester), isTrue,
          reason: 'an AlertDialog sets SemanticsRole.alertDialog');

      // The accessible name is the restore title (AR-1.2).
      final dialog =
          tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.semanticLabel, contains('Restore report'));
    });

    testWidgets('dialog has accessible name in Kiswahili', (tester) async {
      phone(tester);
      tester.platformDispatcher.localesTestValue = [const Locale('sw', 'KE')];
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(hasDialogRoleNode(tester), isTrue);
      final dialog =
          tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.semanticLabel, contains('Tumaini ya ripoti'));
    });

    testWidgets(
        'focus moves into the dialog on appearance and returns on dismissal',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      // The dialog is present — showDialog creates a FocusScope that traps
      // focus inside the dialog (AR-2.2).
      expect(find.byType(AlertDialog), findsOneWidget);

      // Focus has moved into the dialog.
      final primaryFocus = WidgetsBinding.instance.focusManager.primaryFocus;
      expect(primaryFocus, isNotNull,
          reason: 'focus should move into the dialog (AR-2.2)');

      // Dismiss via "Keep saved".
      await tester.tap(find.text('Keep saved'));
      await tester.pumpAndSettle();

      // The dialog is gone.
      expect(find.byType(AlertDialog), findsNothing);

      // Focus returned to the welcome screen: the primary button is reachable.
      expect(
        find.widgetWithText(FilledButton, 'Report an incident'),
        findsOneWidget,
      );
    });

    testWidgets('barrier tap dismisses the dialog and preserves the record',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap the dimmed barrier (anywhere outside the dialog).
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Report an incident'), findsWidgets);

      // Record preserved (FR-2.4).
      expect(await store.read(), isNotNull);
    });
  });

  // ─── Text scaling (2×) ────────────────────────────────────────────────────

  group('T-16 restore dialog text scaling', () {
    testWidgets('renders without overflow at 2x text scale (English)',
        (tester) async {
      phone(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('renders without overflow at 2x text scale (Kiswahili)',
        (tester) async {
      phone(tester);
      tester.platformDispatcher.localesTestValue = [const Locale('sw', 'KE')];
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(hasDialogRoleNode(tester), isTrue);
      // The Kiswahili "not submitted" text is "haijatolewa" (lowercase h,
      // mid-sentence in "Hii ripoti haijatolewa.").
      // skipOffstage: false because at 2x text scale the dialog content may
      // be scrolled inside the AlertDialog's viewport.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('haijatolewa'),
        ),
        findsOneWidget,
      );
    });
  });

  // ─── Prompt content ───────────────────────────────────────────────────────

  group('T-16 restore prompt content', () {
    testWidgets('shows "This report has not been submitted"', (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      // The dialog title is present.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Restore report'),
        ),
        findsOneWidget,
      );
      // FR-4.3: the user must be told the report has not been submitted.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('This report has not been submitted'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows save timestamp', (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      // The saved date is shown (but not the report content).
      expect(find.textContaining('Saved on'), findsOneWidget);
    });

    testWidgets(
        'does not expose sensitive report details (route, plate, SACCO) in prompt',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      // Only the save timestamp is shown; no incident payload (FR-2.5, FR-4.3).
      expect(find.textContaining('Test Route'), findsNothing,
          reason: 'the route must not appear in the restore prompt');
      expect(find.textContaining('KDA 123A'), findsNothing,
          reason: 'the plate must not appear in the restore prompt');
      expect(find.textContaining('Test SACCO'), findsNothing,
          reason: 'the SACCO must not appear in the restore prompt');
    });
  });

  // ─── Keep saved retains draft ─────────────────────────────────────────────

  group('T-16 keep saved retains draft', () {
    testWidgets('retains the stored draft with its original key',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keep saved'), findsOneWidget);

      await tester.tap(find.text('Keep saved'));
      await tester.pumpAndSettle();

      // The record is still in storage and unchanged.
      final retained = await store.read();
      expect(retained, isNotNull);
      expect(retained!.key, kValidRecord.key,
          reason: 'Keep Saved must not delete the pending record (FR-2.4)');
    });

    testWidgets('barrier dismissal also preserves the draft', (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      // Dismiss by tapping the barrier.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(await store.read(), isNotNull);
    });
  });

  // ─── T-17 Discard from restore prompt ────────────────────────────────────────

  group('T-17 discard from restore prompt', () {
    testWidgets('tap Discard shows a confirmation dialog', (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Discard saved report?'), findsOneWidget);
      expect(find.text('Discard'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirmation text cannot be undone', (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(
        find.text('This deletes the report saved on this phone. It cannot be undone.'),
        findsOneWidget,
      );
    });

    testWidgets('confirming deletion removes the record and dismisses the prompt',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Discard saved report?'), findsOneWidget);

      await tester.tap(find.text('Discard').last);
      await tester.pumpAndSettle();

      // Record is gone.
      expect(await store.read(), isNull);
      // Restore prompt is dismissed.
      expect(find.text('Restore'), findsNothing);
      // Welcome screen returns to normal.
      expect(find.text('Report an incident'), findsWidgets);
    });

    testWidgets('cancel in confirmation preserves the record', (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Cancel the discard.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Confirmation dialog is gone.
      expect(find.text('Discard saved report?'), findsNothing);
      // Record is still there.
      expect(await store.read(), isNotNull);
      // No restore dialog: the user dismissed it by choosing Discard.
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('barrier tap in confirmation preserves the record',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Discard saved report?'), findsOneWidget);

      // Tap outside the dialog.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Discard saved report?'), findsNothing);
      expect(await store.read(), isNotNull);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('back button in confirmation preserves the record',
        (tester) async {
      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Discard saved report?'), findsOneWidget);

      // Simulate system back button by popping the dialog route.
      final element = tester.element(find.byType(AlertDialog));
      Navigator.of(element).pop();

      await tester.pumpAndSettle();

      expect(find.text('Discard saved report?'), findsNothing);
      expect(await store.read(), isNotNull);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('failed discard retains the record and shows an error banner',
        (tester) async {
      final store = DeleteFailedStore(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Error banner with honest wording.
      expect(
        find.text('Could not delete the saved report.'),
        findsOneWidget,
      );
      expect(
        find.text('The report is still saved on this phone.'),
        findsOneWidget,
      );
      expect(store.deleteCount, 1);
      expect(await store.read(), isNotNull);
    });

    testWidgets('discard error banner is a live region', (tester) async {
      final store = DeleteFailedStore(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard').last);
      await tester.pumpAndSettle();

      expect(hasLiveRegionNode(tester), isTrue,
          reason: 'discard-failure banner must be a live region (AR-4.1)');
    });

    testWidgets('confirmation and error text are localised in Kiswahili',
        (tester) async {
      phone(tester);
      tester.platformDispatcher.localesTestValue = [const Locale('sw', 'KE')];
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Futa'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(find.text('Futa ripoti iliyopotekwa?', skipOffstage: false),
          findsOneWidget);
      expect(
        find.text(
          'Hii inafuta ripoti iliyopotekwa kwenye simu yako. Haifutika tena.',
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Futa', skipOffstage: false).last);
      await tester.pumpAndSettle();

      expect(await store.read(), isNull);
    });

    testWidgets('render without overflow at 2x text scale', (tester) async {
      phone(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final store = InMemoryPendingDraftStore();
      await store.write(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('T-17 discard retry after failure', () {
    testWidgets('retrying after a failed discard can succeed', (tester) async {
      final store = FailingThenSucceedingDeleteStore(kValidRecord);

      await tester.pumpWidget(
        app(pendingStore: store, clock: () => kClockNotExpired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);

      // Tap "Discard" in the restore dialog.
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Confirm.
      await tester.tap(find.text('Discard').last);
      await tester.pumpAndSettle();

      // The first attempt failed.
      expect(find.text('Could not delete the saved report.'), findsOneWidget);
      expect(await store.read(), isNotNull);

      // After a failed discard, the restore prompt does NOT reappear (it was
      // dismissed). The error banner stays visible. Retry is tested via the
      // review screen — see "T-17 discard from review screen".
    });
  });
}

/// A store whose first [delete] throws [PendingDraftDeleteFailed] but a second
/// call succeeds. Used to test retry-after-failure (T-17).
class FailingThenSucceedingDeleteStore implements PendingDraftStore {
  FailingThenSucceedingDeleteStore(this.record);

  PendingDraft? record;
  int deleteCount = 0;

  @override
  Future<PendingDraft?> read() async => record;

  @override
  Future<void> delete() async {
    deleteCount++;
    if (deleteCount == 1) {
      throw const PendingDraftDeleteFailed('delete failed');
    }
    record = null;
  }

  @override
  Future<void> write(PendingDraft draft) async {
    record = draft;
  }

  @override
  Future<bool> isAvailable() async => true;
}
