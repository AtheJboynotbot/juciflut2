import 'package:flutter/material.dart';

/// Professional empty state widget with icon, title, subtitle, and optional action
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize + 40,
              height: iconSize + 40,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF7C4DFF)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? const Color(0xFF7C4DFF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for no schedules
class EmptySchedulesState extends StatelessWidget {
  final VoidCallback? onAddSchedule;

  const EmptySchedulesState({
    super.key,
    this.onAddSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.calendar_today_outlined,
      title: 'No Schedules Yet',
      subtitle: 'Start by adding your first consultation slot or class schedule',
      actionLabel: onAddSchedule != null ? 'Add Schedule' : null,
      onAction: onAddSchedule,
      iconColor: const Color(0xFF7C4DFF),
    );
  }
}

/// Empty state for no bookings
class EmptyBookingsState extends StatelessWidget {
  final VoidCallback? onCreateBooking;

  const EmptyBookingsState({
    super.key,
    this.onCreateBooking,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.event_busy_outlined,
      title: 'No Bookings Yet',
      subtitle: 'When students book consultations, they will appear here',
      actionLabel: onCreateBooking != null ? 'Create Booking' : null,
      onAction: onCreateBooking,
      iconColor: Colors.orange,
    );
  }
}

/// Empty state for no search results
class EmptySearchState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onClearSearch;

  const EmptySearchState({
    super.key,
    required this.searchQuery,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'No Results Found',
      subtitle: 'We couldn\'t find any results for "$searchQuery".\nTry a different search term.',
      actionLabel: onClearSearch != null ? 'Clear Search' : null,
      onAction: onClearSearch,
      iconColor: Colors.grey,
    );
  }
}

/// Empty state for network error
class NetworkErrorState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? errorMessage;

  const NetworkErrorState({
    super.key,
    this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.wifi_off,
      title: 'Connection Error',
      subtitle: errorMessage ?? 
          'Unable to connect to the server.\nPlease check your internet connection and try again.',
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }
}

/// Empty state for general error
class ErrorState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Something Went Wrong',
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: title,
      subtitle: subtitle,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }
}

/// Empty state for no data on specific day
class EmptyDayScheduleState extends StatelessWidget {
  final String dayName;

  const EmptyDayScheduleState({
    super.key,
    required this.dayName,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.free_breakfast_outlined,
      title: 'Free on $dayName',
      subtitle: 'You have no scheduled activities for $dayName',
      iconColor: Colors.green,
    );
  }
}

/// Empty state for pending items
class EmptyPendingState extends StatelessWidget {
  final String itemType;

  const EmptyPendingState({
    super.key,
    this.itemType = 'items',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.check_circle_outline,
      title: 'All Clear!',
      subtitle: 'You have no pending $itemType',
      iconColor: Colors.green,
    );
  }
}
