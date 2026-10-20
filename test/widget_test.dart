import 'package:flutter_test/flutter_test.dart';
import 'package:sqi_chess_club/app/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('SQI Checkmate Arena loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      CheckmateArenaApp(
        client: SupabaseClient(
          'https://example.supabase.co',
          'test-publishable-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      ),
    );

    expect(find.text('SQI CHECKMATE'), findsOneWidget);
  });
}
