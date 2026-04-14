import 'package:flutter_test/flutter_test.dart';

import 'package:kampusapp/features/shell/app_entry.dart';

void main() {
  testWidgets('renders Kampusapp login title', (tester) async {
    await tester.pumpWidget(const KampusApp());

    expect(find.text('Kampusapp'), findsOneWidget);
    expect(find.text('Giris yap'), findsOneWidget);
  });
}
