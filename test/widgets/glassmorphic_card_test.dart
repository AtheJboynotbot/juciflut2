import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juciflut/widgets/glassmorphic_card.dart';

void main() {
  group('GlassmorphicCard', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphicCard(
              child: testChild,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should apply default padding', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphicCard(
              child: testChild,
            ),
          ),
        ),
      );

      // Assert - default padding is 20
      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(GlassmorphicCard),
          matching: find.byType(Padding),
        ).last,
      );
      expect(padding.padding, const EdgeInsets.all(20));
    });

    testWidgets('should apply custom padding', (WidgetTester tester) async {
      // Arrange
      const customPadding = EdgeInsets.all(30);
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphicCard(
              padding: customPadding,
              child: testChild,
            ),
          ),
        ),
      );

      // Assert
      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(GlassmorphicCard),
          matching: find.byType(Padding),
        ).last,
      );
      expect(padding.padding, customPadding);
    });

    testWidgets('should apply default border radius', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphicCard(
              child: testChild,
            ),
          ),
        ),
      );

      // Assert - default borderRadius is 20
      final clipRRect = tester.widget<ClipRRect>(
        find.byType(ClipRRect),
      );
      expect(clipRRect.borderRadius, BorderRadius.circular(20));
    });

    testWidgets('should apply custom border radius', (WidgetTester tester) async {
      // Arrange
      const customRadius = 15.0;
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphicCard(
              borderRadius: customRadius,
              child: testChild,
            ),
          ),
        ),
      );

      // Assert
      final clipRRect = tester.widget<ClipRRect>(
        find.byType(ClipRRect),
      );
      expect(clipRRect.borderRadius, BorderRadius.circular(customRadius));
    });

    testWidgets('should have BackdropFilter for blur effect', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphicCard(
              child: testChild,
            ),
          ),
        ),
      );

      // Assert - BackdropFilter should be present
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('should render complex child widgets', (WidgetTester tester) async {
      // Arrange
      const complexChild = Column(
        children: [
          Text('Title'),
          SizedBox(height: 10),
          Text('Subtitle'),
          Icon(Icons.star),
        ],
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphicCard(
              child: complexChild,
            ),
          ),
        ),
      );

      // Assert - all child widgets should be rendered
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('should handle multiple GlassmorphicCards', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                GlassmorphicCard(child: Text('Card 1')),
                SizedBox(height: 10),
                GlassmorphicCard(child: Text('Card 2')),
                SizedBox(height: 10),
                GlassmorphicCard(child: Text('Card 3')),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(GlassmorphicCard), findsNWidgets(3));
      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
      expect(find.text('Card 3'), findsOneWidget);
    });

    testWidgets('should be tappable when wrapped in GestureDetector', (WidgetTester tester) async {
      // Arrange
      var tapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => tapped = true,
              child: const GlassmorphicCard(
                child: Text('Tap Me'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      // Assert
      expect(tapped, true);
    });

    test('GlassmorphicCard should be const constructible', () {
      // This test verifies that the widget can be created as const
      const card = GlassmorphicCard(
        child: Text('Const Widget'),
      );
      
      expect(card, isNotNull);
      expect(card.padding, const EdgeInsets.all(20));
      expect(card.borderRadius, 20);
    });
  });
}
