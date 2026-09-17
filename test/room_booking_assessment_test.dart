import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking/data/front_desk_session.dart';
import 'package:hotel_booking/main.dart';
import 'package:hotel_booking/widgets/ui/compact_date_picker.dart';

Future<void> _openBooking(WidgetTester tester) async {
  FrontDeskSession.instance.reset();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const HotelBookingApp());
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(NavigationDestination, 'Booking'));
  await tester.pumpAndSettle();
}

Future<void> _pickDates(WidgetTester tester) async {
  await tester.tap(find.byType(CompactDateField).at(0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Today'));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(CompactDateField).at(1));
  await tester.pumpAndSettle();
  await tester.tap(find.text('+3 days'));
  await tester.pumpAndSettle();
}

/// Widget tests for the coding-assessment booking requirements.
void main() {
  group('Room booking assessment requirements', () {
    testWidgets('displays sample room list from hardcoded data', (tester) async {
      await _openBooking(tester);

      for (final code in ['R101', 'R102', 'R201', 'R202', 'R301']) {
        expect(find.text(code), findsWidgets);
      }
    });

    testWidgets('lets user pick check-in and check-out dates', (tester) async {
      await _openBooking(tester);

      expect(find.text('Check-in'), findsWidgets);
      expect(find.text('Check-out'), findsWidgets);
      expect(find.byType(CompactDateField), findsNWidgets(2));
      expect(
        find.text('Pick both dates to see live availability and pricing.'),
        findsOneWidget,
      );

      await _pickDates(tester);
      expect(
        find.text('Pick both dates to see live availability and pricing.'),
        findsNothing,
      );
      expect(
        find.text('Please select a room to continue.'),
        findsOneWidget,
      );
    });

    testWidgets('shows nights and total price when selection is valid', (
      tester,
    ) async {
      await _openBooking(tester);
      await _pickDates(tester);

      final room = find.text('R102');
      await tester.dragUntilVisible(
        room,
        find.byType(SingleChildScrollView).first,
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
      await tester.tap(room);
      await tester.pumpAndSettle();

      expect(find.text('Nights (current selection)'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
      expect(find.text('Total price'), findsOneWidget);
      expect(find.textContaining('₹'), findsWidgets);
      expect(find.textContaining('10,500'), findsWidgets);
    });

    testWidgets('blocks confirm until dates and room are valid', (
      tester,
    ) async {
      await _openBooking(tester);

      var confirmButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm booking'),
      );
      expect(confirmButton.onPressed, isNull);

      await _pickDates(tester);
      confirmButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm booking'),
      );
      expect(confirmButton.onPressed, isNull);

      final room = find.text('R102');
      await tester.dragUntilVisible(
        room,
        find.byType(SingleChildScrollView).first,
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
      await tester.tap(room);
      await tester.pumpAndSettle();

      confirmButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm booking'),
      );
      expect(confirmButton.onPressed, isNotNull);
    });
  });
}
