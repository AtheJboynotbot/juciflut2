/// Immutable filter/sort state for the Schedule page.
class ScheduleFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> types;     // "consultation" | "class" | "meeting"
  final List<String> statuses;  // "active" | "cancelled"
  final String searchQuery;
  final String sortBy;          // "date" | "time" | "type"
  final bool sortAscending;

  const ScheduleFilter({
    this.startDate,
    this.endDate,
    this.types = const [],
    this.statuses = const ['active'],
    this.searchQuery = '',
    this.sortBy = 'date',
    this.sortAscending = true,
  });

  ScheduleFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? types,
    List<String>? statuses,
    String? searchQuery,
    String? sortBy,
    bool? sortAscending,
  }) {
    return ScheduleFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      types: types ?? this.types,
      statuses: statuses ?? this.statuses,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// Return a copy with startDate and endDate cleared.
  ScheduleFilter clearDateRange() => ScheduleFilter(
        types: types,
        statuses: statuses,
        searchQuery: searchQuery,
        sortBy: sortBy,
        sortAscending: sortAscending,
      );

  /// True when any non-default filter is active.
  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      types.isNotEmpty ||
      statuses.length != 1 ||
      !statuses.contains('active') ||
      searchQuery.isNotEmpty;

  /// Number of active filter groups (for the badge count).
  int get activeFilterCount {
    int n = 0;
    if (startDate != null || endDate != null) n++;
    if (types.isNotEmpty) n++;
    if (statuses.length != 1 || !statuses.contains('active')) n++;
    if (searchQuery.isNotEmpty) n++;
    return n;
  }

  /// Factory that returns default filter values.
  static ScheduleFilter get defaults => const ScheduleFilter(
        statuses: ['active'],
        sortBy: 'date',
        sortAscending: true,
      );
}
