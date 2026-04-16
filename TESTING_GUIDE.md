# Testing Guide - JuCi Faculty Portal

## Overview

This guide covers the testing infrastructure for the JuCi Faculty Portal application. We use a comprehensive testing strategy including unit tests, widget tests, and integration tests.

---

## 📦 Testing Dependencies

The following packages are used for testing:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.9
  fake_cloud_firestore: ^3.0.3
  firebase_auth_mocks: ^0.14.1
```

**Install dependencies:**
```powershell
flutter pub get
```

---

## 🧪 Test Structure

```
juciflut/
├── test/
│   ├── models/
│   │   ├── faculty_model_test.dart
│   │   └── schedule_model_test.dart
│   ├── widgets/
│   │   └── glassmorphic_card_test.dart
│   └── services/
│       └── (future tests)
├── integration_test/
│   └── login_flow_test.dart
└── TESTING_GUIDE.md (this file)
```

---

## 🔬 Unit Tests

### What We Test

Unit tests verify individual functions, methods, and classes in isolation.

#### **Model Tests**

**FacultyModel** (`test/models/faculty_model_test.dart`):
- ✅ `fromFirestore()` - Deserialization from Firestore
- ✅ `toFirestore()` - Serialization to Firestore
- ✅ `displayName` getter - Computed property
- ✅ `copyWith()` - Immutable updates
- ✅ URL whitespace handling
- ✅ Default values
- ✅ Date type handling

**ScheduleModel** (`test/models/schedule_model_test.dart`):
- ✅ `fromFirestore()` - Deserialization
- ✅ `toFirestore()` - Serialization
- ✅ `timeRange` getter - Formatted time display
- ✅ `copyWith()` - Immutable updates
- ✅ `isBooked` field handling
- ✅ Backwards compatibility (camelCase vs snake_case)
- ✅ Const constructor

### Running Unit Tests

```powershell
# Run all unit tests
flutter test

# Run specific test file
flutter test test/models/faculty_model_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests in watch mode (auto-rerun on changes)
flutter test --watch
```

### Test Output Example

```
00:01 +22: All tests passed!
```

---

## 🎨 Widget Tests

### What We Test

Widget tests verify UI components render correctly and respond to user interaction.

#### **GlassmorphicCard** (`test/widgets/glassmorphic_card_test.dart`):
- ✅ Renders child widget
- ✅ Applies default padding (20px)
- ✅ Applies custom padding
- ✅ Applies default border radius (20px)
- ✅ Applies custom border radius
- ✅ Has BackdropFilter for blur effect
- ✅ Renders complex child widgets
- ✅ Handles multiple instances
- ✅ Responds to tap events
- ✅ Const constructor support

### Running Widget Tests

```powershell
# Run all widget tests
flutter test test/widgets/

# Run specific widget test
flutter test test/widgets/glassmorphic_card_test.dart

# Run with verbose output
flutter test --verbose test/widgets/glassmorphic_card_test.dart
```

---

## 🔗 Integration Tests

### What We Test

Integration tests verify complete user flows and component interactions.

#### **Login Flow** (`integration_test/login_flow_test.dart`):
- ✅ Login screen displays on app launch
- ✅ Required UI elements present
- ✅ Navigation to dashboard after login
- ✅ Mock authentication state
- ✅ Faculty document creation
- ✅ Route transitions

### Running Integration Tests

```powershell
# Run integration tests on Chrome
flutter test integration_test/login_flow_test.dart -d chrome

# Run integration tests on Edge
flutter test integration_test/login_flow_test.dart -d edge

# Run integration tests on connected device
flutter test integration_test/login_flow_test.dart -d <device-id>
```

**Note:** Integration tests require a running environment (browser or device).

---

## 📊 Test Coverage

### Generating Coverage Reports

```powershell
# Generate coverage data
flutter test --coverage

# View coverage in browser (requires lcov)
# Install: choco install lcov (Windows) or brew install lcov (Mac)
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html
```

### Coverage Goals

- **Models:** 100% coverage (critical business logic)
- **Widgets:** 80%+ coverage (UI components)
- **Services:** 90%+ coverage (data layer)
- **Overall:** 85%+ coverage

---

## 🛠️ Writing New Tests

### Unit Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:juciflut/path/to/file.dart';

void main() {
  group('ClassName', () {
    test('should do something', () {
      // Arrange
      final instance = ClassName();
      
      // Act
      final result = instance.method();
      
      // Assert
      expect(result, expectedValue);
    });
  });
}
```

### Widget Test Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juciflut/widgets/my_widget.dart';

void main() {
  testWidgets('MyWidget should render correctly', (WidgetTester tester) async {
    // Arrange & Act
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MyWidget(),
        ),
      ),
    );
    
    // Assert
    expect(find.byType(MyWidget), findsOneWidget);
  });
}
```

---

## 🐛 Debugging Tests

### Enable Verbose Output

```powershell
flutter test --verbose test/models/faculty_model_test.dart
```

### Debug Specific Test

```dart
test('my test', () {
  debugPrint('Debug message here');
  // ... test code
}, skip: false); // Set to true to skip this test
```

### Run Single Test

```dart
test('my specific test', () {
  // ... test code
}, tags: 'focus');
```

Run with:
```powershell
flutter test --tags focus
```

---

## ✅ Best Practices

### 1. **Follow AAA Pattern**
- **Arrange:** Set up test data
- **Act:** Execute the code under test
- **Assert:** Verify the results

### 2. **Use Descriptive Test Names**
```dart
// Good ✅
test('should return formatted time range when valid times provided', () {});

// Bad ❌
test('test1', () {});
```

### 3. **Test Edge Cases**
```dart
test('should handle empty strings', () {});
test('should handle null values', () {});
test('should handle very long input', () {});
```

### 4. **Keep Tests Independent**
```dart
// Each test should set up its own data
setUp(() {
  // Common setup code
});

tearDown(() {
  // Cleanup code
});
```

### 5. **Use Mocks for External Dependencies**
```dart
// Use FakeFirebaseFirestore instead of real Firestore
final fakeFirestore = FakeFirebaseFirestore();
```

### 6. **Test One Thing at a Time**
```dart
// Good ✅
test('should set firstName correctly', () {});
test('should set lastName correctly', () {});

// Bad ❌
test('should set firstName and lastName and email', () {});
```

---

## 🚀 CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter test integration_test/
```

---

## 📝 Test Checklist

Before committing code:

- [ ] All unit tests pass
- [ ] All widget tests pass
- [ ] All integration tests pass
- [ ] Coverage meets minimum thresholds
- [ ] No skipped tests without justification
- [ ] New features have corresponding tests
- [ ] Tests are documented and readable

---

## 🔧 Troubleshooting

### Issue: "MissingPluginException"
**Solution:** Run tests with `flutter test` not `dart test`

### Issue: "Bad state: No element"
**Solution:** Check that widgets are properly pumped with `await tester.pumpWidget()`

### Issue: "Test timeout"
**Solution:** Add `await tester.pumpAndSettle()` to wait for animations

### Issue: "Firebase not initialized"
**Solution:** Use mocks (`FakeFirebaseFirestore`, `MockFirebaseAuth`)

### Issue: "Can't find widget"
**Solution:** Use `await tester.pumpAndSettle()` and verify widget is in tree

---

## 📚 Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

---

## 🎯 Quick Commands Reference

```powershell
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific file
flutter test test/models/faculty_model_test.dart

# Run integration tests
flutter test integration_test/ -d chrome

# Watch mode (auto-rerun)
flutter test --watch

# Verbose output
flutter test --verbose

# Run tests matching name
flutter test --name "FacultyModel"
```

---

## 📞 Support

For testing questions:
- Review this guide
- Check existing test files for examples
- See Flutter testing documentation
- Ask the development team

---

**Happy Testing!** 🧪✨
