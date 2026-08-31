import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thenexopp_agent/main.dart';
import 'package:thenexopp_agent/core/widgets/human_agent_logo.dart';

void main() {
  testWidgets('App initializes cleanly and renders splash/branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TheNexoppAgentApp(),
      ),
    );

    expect(find.byType(HumanAgentLogo), findsOneWidget);
  });
}
