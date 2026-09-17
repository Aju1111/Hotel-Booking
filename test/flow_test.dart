import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking/data/front_desk_session.dart';
import 'package:hotel_booking/main.dart';
import 'package:hotel_booking/widgets/ui/compact_date_picker.dart';

Future<void> _pumpPhone(
  WidgetTester tester, {
  bool seedCheckedInGuests = false,
}) async {
  FrontDeskSession.instance.reset();
  if (seedCheckedInGuests) {
    FrontDeskSession.instance.seedCheckedInDemoGuests();
  }
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const HotelBookingApp());
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(NavigationDestination, label));
  await tester.pumpAndSettle();
}

Future<void> _pickBookingDates(WidgetTester tester) async {
  await tester.tap(find.byType(CompactDateField).at(0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Today'));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(CompactDateField).at(1));
  await tester.pumpAndSettle();
  await tester.tap(find.text('+3 days'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('check-in stepper advances through all three stages', (
    tester,
  ) async {
    await _pumpPhone(tester);
    await _openTab(tester, 'Check-in');

    expect(find.text('Select booking & guest'), findsOneWidget);
    await _openTab(tester, 'Booking');
    await _pickBookingDates(tester);
    final room = find.text('R102');
    await tester.dragUntilVisible(
      room,
      find.byType(SingleChildScrollView).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(room);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm booking'));
    await tester.pumpAndSettle();

    await _openTab(tester, 'Check-in');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Walk-in guest').first);
    await tester.pumpAndSettle();
    expect(find.text('Review & update details'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Finalize check-in & payment'), findsOneWidget);
    expect(find.text('Complete check-in'), findsWidgets);

    await tester.tap(find.text('Complete check-in').last);
    await tester.pump();
    expect(find.text('Completing…'), findsWidgets);
    await tester.pumpAndSettle();

    expect(find.text('Checked in'), findsWidgets);
    expect(find.text('Complete check-in'), findsNothing);

    await _openTab(tester, 'Check-out');
    await tester.pumpAndSettle();
    expect(find.text('1 room(s) selected'), findsOneWidget);

    await _openTab(tester, 'Check-in');
    await tester.pumpAndSettle();
    expect(find.text('Mathew Hyden'), findsNothing);
    expect(find.text('No booked rooms'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('check-out button switches to Checked out after payment', (
    tester,
  ) async {
    await _pumpPhone(tester, seedCheckedInGuests: true);
    await _openTab(tester, 'Check-out');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Payment & check-out'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Check out'));
    await tester.pump();
    expect(find.text('Processing…'), findsWidgets);
    await tester.pumpAndSettle();

    expect(find.text('Checked out'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Check out'), findsNothing);

    await tester.tap(find.text('Identify'));
    await tester.pumpAndSettle();

    expect(find.text('Mathew Hyden'), findsNothing);
    expect(find.text('Sarah Thompson'), findsWidgets);
    expect(find.text('201'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('check-out requires a room before processing payment', (
    tester,
  ) async {
    await _pumpPhone(tester, seedCheckedInGuests: true);
    await _openTab(tester, 'Check-out');

    expect(find.text('Identify departing guest'), findsOneWidget);

    expect(find.text('1 room(s) selected'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Room 101'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('adding a mini-bar charge increases the room total', (
    tester,
  ) async {
    await _pumpPhone(tester, seedCheckedInGuests: true);
    await _openTab(tester, 'Check-out');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final miniBar = find.widgetWithText(FilterChip, 'Mini-bar').first;
    await tester.dragUntilVisible(
      miniBar,
      find.byType(SingleChildScrollView).first,
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();

    await tester.tap(miniBar);
    await tester.pumpAndSettle();

    expect(find.textContaining('added to room'), findsOneWidget);
    expect(tester.widget<FilterChip>(miniBar).selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('room booked from Booking tab appears on Check-in', (
    tester,
  ) async {
    await _pumpPhone(tester);
    await _openTab(tester, 'Booking');
    await _pickBookingDates(tester);

    final room = find.text('R102');
    await tester.dragUntilVisible(
      room,
      find.byType(SingleChildScrollView).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(room);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm booking'));
    await tester.pumpAndSettle();

    await _openTab(tester, 'Check-in');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CompactDateField).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Walk-in guest'), findsWidgets);
    expect(find.text('102'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest can add another room after the first booking', (
    tester,
  ) async {
    await _pumpPhone(tester);
    await _openTab(tester, 'Booking');

    await _pickBookingDates(tester);

    final room = find.text('R102');
    await tester.dragUntilVisible(
      room,
      find.byType(SingleChildScrollView).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(room);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm booking'));
    await tester.pumpAndSettle();

    expect(find.text('Book another room'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Book another room'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Select one more room'), findsWidgets);
    expect(find.text('Add this room'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('booked rooms show as occupied on the dashboard', (tester) async {
    await _pumpPhone(tester);
    await _openTab(tester, 'Booking');

    await _pickBookingDates(tester);

    final room = find.text('R102');
    await tester.dragUntilVisible(
      room,
      find.byType(SingleChildScrollView).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(room);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm booking'));
    await tester.pumpAndSettle();

    await _openTab(tester, 'Home');
    await tester.pumpAndSettle();

    expect(find.text('2 of 5 rooms occupied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('booking screen blocks confirm until dates and room are set', (
    tester,
  ) async {
    await _pumpPhone(tester);
    await _openTab(tester, 'Booking');

    expect(find.text('Select dates & room'), findsOneWidget);

    final confirmButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm booking'),
    );
    expect(confirmButton.onPressed, isNull);

    expect(tester.takeException(), isNull);
  });

  testWidgets('More tab opens Rooms and Reports without highlighting Home', (
    tester,
  ) async {
    await _pumpPhone(tester);

    await _openTab(tester, 'More');
    expect(find.text('Rooms, reports and extra tools'), findsOneWidget);

    await tester.tap(find.text('Reports').last);
    await tester.pumpAndSettle();

    expect(find.text('Revenue trend'), findsOneWidget);

    final more = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(more.selectedIndex, 4);
  });

  testWidgets('rooms screen filters by status', (tester) async {
    await _pumpPhone(tester);
    await _openTab(tester, 'More');
    await tester.tap(find.text('Rooms').last);
    await tester.pumpAndSettle();

    expect(find.text('Inventory overview'), findsOneWidget);
    expect(find.text('Executive Suite'), findsWidgets);

    final occupiedPill = find.textContaining('Occupied (');
    await tester.dragUntilVisible(
      occupiedPill,
      find.byType(ListView).first,
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();

    await tester.tap(occupiedPill);
    await tester.pumpAndSettle();

    expect(find.text('101'), findsWidgets);
    expect(find.text('Executive Suite'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'maintenance filter shows the maintenance room and its work order',
    (tester) async {
      await _pumpPhone(tester);
      await _openTab(tester, 'More');
      await tester.tap(find.text('Rooms').last);
      await tester.pumpAndSettle();

      final maintenancePill = find.textContaining('Maintenance (');
      await tester.dragUntilVisible(
        maintenancePill,
        find.byType(ListView).first,
        const Offset(-160, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(maintenancePill);
      await tester.pumpAndSettle();

      expect(find.text('301'), findsWidgets);
      expect(find.text('Family Room'), findsWidgets);
      expect(find.text('Executive Suite'), findsNothing);

      await tester.tap(find.text('301').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('AC not cooling'), findsOneWidget);
      expect(find.text('Work done, ready to sell'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
