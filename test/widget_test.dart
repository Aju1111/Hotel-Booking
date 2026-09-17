import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking/data/front_desk_session.dart';
import 'package:hotel_booking/main.dart';

/// Phone sizes the app must fit: small Android, iPhone 14, large Android.
const _phoneSizes = <String, Size>{
  'small phone (360)': Size(360, 640),
  'iphone (390)': Size(390, 844),
  'large phone (430)': Size(430, 932),
};

/// Bottom navigation labels in order.
const _navLabels = ['Home', 'Check-in', 'Booking', 'Check-out', 'More'];

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  FrontDeskSession.instance.reset();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const HotelBookingApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard shows its key sections', (tester) async {
    await _pumpApp(tester, const Size(390, 844));

    expect(find.text('Main Dashboard'), findsOneWidget);
    expect(find.text('Raintech'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Room Status'), findsOneWidget);
    expect(find.text('Weekly Revenue'), findsOneWidget);
  });

  testWidgets('dashboard shows a skeleton before data arrives', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const HotelBookingApp());
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Room Status'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Room Status'), findsOneWidget);
  });

  testWidgets('tapping a room opens the quick status sheet', (tester) async {
    await _pumpApp(tester, const Size(390, 844));

    final roomTile = find.text('101').first;
    await tester.dragUntilVisible(
      roomTile,
      find.byType(SingleChildScrollView).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    await tester.tap(roomTile);
    await tester.pumpAndSettle();

    expect(find.text('Change status'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back button walks through bottom-nav history', (tester) async {
    await _pumpApp(tester, const Size(390, 844));

    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Check-in'));
    await tester.pumpAndSettle();
    expect(find.text('Guest Check-in'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Check-out'));
    await tester.pumpAndSettle();
    expect(find.text('Identify departing guest'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
    await tester.pumpAndSettle();
    expect(find.text('Main Dashboard'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Guest Check-out'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Guest Check-in'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Main Dashboard'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation reaches every screen', (tester) async {
    await _pumpApp(tester, const Size(390, 844));

    for (final label in ['Home', 'Check-in', 'Booking', 'Check-out']) {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'navigating to $label');
    }

    await tester.tap(find.widgetWithText(NavigationDestination, 'More'));
    await tester.pumpAndSettle();
    expect(find.text('Rooms, reports and extra tools'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('renders without overflow', () {
    for (final entry in _phoneSizes.entries) {
      testWidgets('every screen on ${entry.key}', (tester) async {
        await _pumpApp(tester, entry.value);
        expect(tester.takeException(), isNull, reason: 'dashboard');

        for (final label in _navLabels.skip(1)) {
          await tester.tap(find.widgetWithText(NavigationDestination, label));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: label);
          if (label == 'More') {
            await tester.tap(find.text('Rooms').last);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'Rooms from More');
          }
        }
      });
    }
  });
}
