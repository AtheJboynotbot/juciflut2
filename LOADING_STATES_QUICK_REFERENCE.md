# Loading & Empty States - Quick Reference

## 🚀 Quick Usage Guide

### **Skeleton Loaders**

```dart
// Generic skeleton
SkeletonCard(height: 100)

// Schedule card skeleton
const SkeletonScheduleCard()

// Stats card skeleton
const SkeletonStatsCard()

// Booking card skeleton
const SkeletonBookingCard()

// Multiple skeletons
SkeletonList(
  itemCount: 3,
  skeletonItem: const SkeletonScheduleCard(),
)
```

---

### **Empty States**

```dart
// No schedules
EmptySchedulesState(
  onAddSchedule: () => showDialog(),
)

// No bookings
EmptyBookingsState(
  onCreateBooking: () => createBooking(),
)

// Free day
EmptyDayScheduleState(dayName: 'Monday')

// No search results
EmptySearchState(
  searchQuery: 'query',
  onClearSearch: () => clear(),
)

// Network error
NetworkErrorState(onRetry: () => retry())

// Generic error
ErrorState(
  subtitle: 'Error message',
  onRetry: () => retry(),
)

// Custom empty state
EmptyStateWidget(
  icon: Icons.icon,
  title: 'Title',
  subtitle: 'Subtitle',
  actionLabel: 'Action',
  onAction: () {},
)
```

---

### **Loading Overlays**

```dart
// Full-screen overlay
LoadingOverlay(
  isLoading: true,
  message: 'Saving...',
  child: YourWidget(),
)

// Inline loader
const InlineLoader(message: 'Loading...')

// Full page loading
const LoadingScreen(message: 'Please wait...')

// Glass loading card
const GlassLoadingCard(message: 'Processing...')

// Loading button
LoadingButton(
  isLoading: _isLoading,
  label: 'Save',
  loadingLabel: 'Saving...',
  onPressed: () => save(),
)

// Pull to refresh
RefreshLoader(
  onRefresh: () async => refresh(),
  child: ListView(...),
)
```

---

## 📁 Import Statements

```dart
// For skeleton loaders
import '../../widgets/skeleton_card.dart';

// For empty states
import '../../widgets/empty_state.dart';

// For loading overlays
import '../../widgets/loading_overlay.dart';
```

---

## 🎨 Color Themes

| Widget | Color |
|--------|-------|
| SkeletonCard | Grey shimmer |
| EmptySchedulesState | Violet (#7C4DFF) |
| EmptyBookingsState | Orange |
| EmptyDayScheduleState | Green |
| EmptySearchState | Grey |
| NetworkErrorState | Red |
| LoadingOverlay | Violet |

---

## ✅ Checklist

**Replace loading spinners:**
- [✓] DashboardPage
- [✓] SchedulePage
- [ ] ProfilePage (if needed)
- [ ] BookingsPage (if needed)

**Add empty states:**
- [✓] No schedules
- [ ] No bookings
- [ ] No search results
- [ ] Network errors

---

## 📚 Full Documentation

See `LOADING_STATES_COMPLETE.md` for complete documentation and examples.
