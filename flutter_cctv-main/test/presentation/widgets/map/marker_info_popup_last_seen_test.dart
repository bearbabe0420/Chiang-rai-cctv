import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:central_command/presentation/widgets/map/views/marker_info_popup_widget.dart';

void main() {
  Future<void> pumpPopup(
    WidgetTester tester, {
    required Map<String, dynamic> cameraData,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkerInfoPopupWidget(
            cameraData: cameraData,
            onCloseTapped: () async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('MarkerInfoPopupWidget lastSeen behavior', () {
    testWidgets('shows "Last seen ล่าสุด" when offline and lastSeen is recent DateTime',
        (tester) async {
      final recent = DateTime.now().subtract(const Duration(seconds: 30));

      await pumpPopup(
        tester,
        cameraData: {
          'id': 'cam-1',
          'name': 'Test Camera',
          'status': 'offline',
          'lastSeen': recent,
          'categories': <String>[],
          'rtspUrl': '',
          'address': 'Test Address',
          'latLong': '18.7883,98.9853',
        },
      );

      expect(find.textContaining('Last seen'), findsOneWidget);
      expect(find.text('Last seen ล่าสุด'), findsOneWidget);
    });

    testWidgets('shows lastSeen text when offline and lastSeen is epoch seconds',
        (tester) async {
      final secondsEpoch =
          DateTime.now().subtract(const Duration(minutes: 2)).millisecondsSinceEpoch ~/
              1000;

      await pumpPopup(
        tester,
        cameraData: {
          'id': 'cam-2',
          'name': 'Test Camera 2',
          'status': 'offline',
          'lastSeen': secondsEpoch,
          'categories': <String>[],
          'rtspUrl': '',
          'address': 'Test Address',
          'latLong': '18.7883,98.9853',
        },
      );

      expect(find.textContaining('Last seen'), findsOneWidget);
    });

    testWidgets('does not show lastSeen text when camera is online', (tester) async {
      await pumpPopup(
        tester,
        cameraData: {
          'id': 'cam-3',
          'name': 'Online Camera',
          'status': 'online',
          'lastSeen': DateTime.now().subtract(const Duration(minutes: 3)),
          'categories': <String>[],
          'rtspUrl': '',
          'address': 'Test Address',
          'latLong': '18.7883,98.9853',
        },
      );

      expect(find.textContaining('Last seen'), findsNothing);
    });
  });
}
