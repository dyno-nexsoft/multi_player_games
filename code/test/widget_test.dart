import 'package:flutter_test/flutter_test.dart';
import 'package:party_game_hub/main.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    await tester.pumpWidget(const PartyGameHubApp());
    expect(find.text('Party Game Hub'), findsOneWidget);
  });
}
