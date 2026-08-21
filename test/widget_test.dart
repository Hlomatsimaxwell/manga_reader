import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/main.dart'; // Adjust if your main widget has a different name

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope for Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: MangaReaderApp(), // Ensure this matches your root widget class in main.dart
      ),
    );

    // Basic assertion
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}