import 'package:flutter_test/flutter_test.dart';
import 'package:aqdin/main.dart';

void main() {
  testWidgets('AQDIN welcome screen renders its core content', (tester) async {
    await tester.pumpWidget(const AqdinApp());

    expect(find.text('AQDIN'), findsOneWidget);
    expect(find.text('Find your person. Build your future.'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });
}
