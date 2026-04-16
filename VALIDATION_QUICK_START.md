# Validation - Quick Start Guide

## 🚀 How to Add Validation to Forms

### **Step 1: Import the utilities**

```dart
import '../../utils/validation_helper.dart';
import '../../utils/logger.dart';
import '../../widgets/error_dialog.dart';
```

---

### **Step 2: Add Form Key**

```dart
void _showAddSlotDialog(BuildContext context, FacultyProvider prov) {
  final formKey = GlobalKey<FormState>();  // Add this
  final titleCtrl = TextEditingController();
  // ... rest of controllers
```

---

### **Step 3: Wrap fields in Form**

```dart
Form(
  key: formKey,
  child: Column(
    children: [
      // Your form fields here
    ],
  ),
)
```

---

### **Step 4: Change TextField to TextFormField**

**Before:**
```dart
TextField(
  controller: titleCtrl,
  decoration: const InputDecoration(labelText: 'Title'),
)
```

**After:**
```dart
TextFormField(
  controller: titleCtrl,
  decoration: const InputDecoration(labelText: 'Title *'),
  validator: (v) => ValidationHelper.validateRequired(v, fieldName: 'Title'),
)
```

---

### **Step 5: Add validators to dropdowns**

```dart
DropdownButtonFormField<String>(
  decoration: const InputDecoration(labelText: 'Day *'),
  validator: (v) => ValidationHelper.validateSelection(v, fieldName: 'day'),
  items: [...],
)
```

---

### **Step 6: Validate before save**

**Before:**
```dart
onPressed: () async {
  final startStr = _formatTime(startTime!);
  final endStr = _formatTime(endTime!);
  await prov.addSchedule(schedule);
}
```

**After:**
```dart
onPressed: () async {
  // Validate form
  if (!formKey.currentState!.validate()) {
    return;
  }
  
  // Validate time range
  final timeError = ValidationHelper.validateTimeRange(startTime, endTime);
  if (timeError != null) {
    await ValidationErrorDialog.show(context, message: timeError);
    return;
  }
  
  // Log and proceed
  AppLogger.info('Saving schedule');
  final startStr = _formatTime(startTime!);
  final endStr = _formatTime(endTime!);
  await prov.addSchedule(schedule);
}
```

---

## 📝 Common Validators

```dart
// Required field
validator: (v) => ValidationHelper.validateRequired(v, fieldName: 'Title')

// Email
validator: ValidationHelper.validateEmail

// Phone number
validator: ValidationHelper.validatePhoneNumber

// Dropdown selection
validator: (v) => ValidationHelper.validateSelection(v, fieldName: 'type')

// Custom validation
validator: (v) {
  if (v == null || v.isEmpty) return 'Required';
  if (v.length < 3) return 'Too short';
  return null;
}
```

---

## 🔍 Replace print() Statements

**Before:**
```dart
print('🔵 [addSchedule] Saving...');
print('✅ [addSchedule] SUCCESS');
print('❌ [addSchedule] ERROR: $e');
```

**After:**
```dart
AppLogger.info('[addSchedule] Saving...');
AppLogger.info('[addSchedule] SUCCESS');
AppLogger.error('[addSchedule] ERROR', e, stackTrace);

// Or use specific loggers:
FirebaseLogger.addSchedule('Saving schedule', scheduleData);
UILogger.dialog('opened', 'Add Schedule');
ValidationLogger.success('email', 'test@example.com');
```

---

## 🎨 Show Error Dialogs

```dart
// Validation error
await ValidationErrorDialog.show(
  context,
  message: 'Please fill in all required fields',
);

// Network error
await NetworkErrorDialog.show(
  context,
  onRetry: () => retryOperation(),
);

// Success
await SuccessDialog.show(
  context,
  message: 'Schedule added successfully!',
);

// Confirm delete
final confirmed = await ConfirmDialog.show(
  context,
  title: 'Delete Schedule',
  message: 'Are you sure?',
  confirmLabel: 'Delete',
  confirmColor: Colors.red,
);
```

---

## ✅ Files to Update

1. **Dashboard Page** - Add slot dialog
2. **Dashboard Page** - Edit slot dialog
3. **Schedule Page** - Add/edit dialogs
4. **Profile Page** - Update form
5. **All service files** - Replace print() with logger

---

## 📚 Full Documentation

See `VALIDATION_COMPLETE.md` for comprehensive documentation and examples.
