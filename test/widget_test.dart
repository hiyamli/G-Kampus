import 'package:flutter_test/flutter_test.dart';

import 'package:kampusapp/features/shell/app_entry.dart';

void main() {
  testWidgets('renders G Kampüs login title', (tester) async {
    await tester.pumpWidget(const KampusApp());

    expect(find.text('G Kampüs'), findsOneWidget);
    expect(find.text('Giriş yap'), findsOneWidget);
  });
}
