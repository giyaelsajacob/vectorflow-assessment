import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vectorflow/app/app.dart';

void main() {
  testWidgets(
    'VectorFlow app starts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: VectorFlowApp(),
        ),
      );

      await tester.pump();

      expect(find.byType(VectorFlowApp), findsOneWidget);
    },
  );
}