# Testing - JuCi Faculty Portal

Add this section to your main README.md

---

## 🧪 Testing

This project includes comprehensive testing infrastructure with unit tests, widget tests, and integration tests.

### Quick Start

```powershell
# Run all tests
.\run-tests.ps1

# Or use Flutter directly
flutter test

# Run with coverage
flutter test --coverage
```

### Test Structure

```
juciflut/
├── test/                          # Unit & Widget Tests
│   ├── models/
│   │   ├── faculty_model_test.dart
│   │   └── schedule_model_test.dart
│   └── widgets/
│       └── glassmorphic_card_test.dart
└── integration_test/              # Integration Tests
    └── login_flow_test.dart
```

### Test Coverage

| Category | Test Cases | Status |
|----------|------------|--------|
| Unit Tests (Models) | 22 | ✅ |
| Widget Tests | 10 | ✅ |
| Integration Tests | 6 | ✅ |
| **Total** | **38** | **✅** |

### Running Specific Tests

```powershell
# Unit tests only
flutter test test/models/

# Widget tests only
flutter test test/widgets/

# Integration tests (requires browser)
flutter test integration_test/ -d chrome

# Specific test file
flutter test test/models/faculty_model_test.dart
```

### Viewing Coverage Reports

```powershell
# Generate coverage
flutter test --coverage

# View HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html
```

### Testing Documentation

- **Comprehensive Guide:** See `TESTING_GUIDE.md`
- **Implementation Summary:** See `TESTING_IMPLEMENTATION_SUMMARY.md`
- **Test Runner Script:** `run-tests.ps1`

### Writing New Tests

See `TESTING_GUIDE.md` for:
- Unit test templates
- Widget test templates
- Best practices
- Mocking strategies
- Debugging tips

---

## 📊 Test Statistics

- ✅ 38 total test cases
- ✅ 100% model coverage
- ✅ Mocked Firebase operations
- ✅ Coverage reporting enabled
- ✅ CI/CD ready

---

**For detailed testing information, see [`TESTING_GUIDE.md`](./TESTING_GUIDE.md)**
