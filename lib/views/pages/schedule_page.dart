import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/faculty_provider.dart';
import '../../models/schedule_filter.dart';
import '../../models/schedule_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/time_validator.dart';
import '../../services/notification_service.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/skeleton_card.dart';
import '../../widgets/empty_state.dart';
import '../dashboard_shell.dart';

/// My Schedule page – displays all schedule slots grouped by day with CRUD.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // ── Filter state ──────────────────────────────────────────────────────────
  ScheduleFilter _filter = ScheduleFilter.defaults;
  bool _showFilters = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _searchController.addListener(() {
      setState(() {
        _filter = _filter.copyWith(
            searchQuery: _searchController.text.toLowerCase());
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<FacultyProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return SingleChildScrollView(
            child: GlassmorphicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonCard(height: 24, width: 150),
                  const SizedBox(height: 20),
                  SkeletonList(
                    itemCount: 5,
                    skeletonItem: const SkeletonScheduleCard(),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: GlassmorphicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(context, prov),
                const SizedBox(height: 12),
                _buildSearchBar(),
                if (_filter.hasActiveFilters) ...[
                  const SizedBox(height: 6),
                  _buildActiveFilterChips(),
                ],
                if (_showFilters) ...[
                  const SizedBox(height: 10),
                  _buildFilterPanel(),
                ],
                const SizedBox(height: 14),
                _buildFilteredList(context, prov),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildPageHeader(BuildContext context, FacultyProvider prov) {
    return Row(
      children: [
        const Text(
          'My Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kCardText,
          ),
        ),
        const Spacer(),
        // Filter toggle button with badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: _filter.hasActiveFilters
                    ? kVioletAccent
                    : Colors.grey.shade600,
              ),
              tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
              onPressed: () =>
                  setState(() => _showFilters = !_showFilters),
            ),
            if (_filter.activeFilterCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '${_filter.activeFilterCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
        ElevatedButton.icon(
          onPressed: () => _showAddDialog(context, prov),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Slot'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kVioletAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by title, location or type…',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        prefixIcon:
            const Icon(Icons.search, color: kVioletAccent, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() =>
                      _filter = _filter.copyWith(searchQuery: ''));
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }

  // ── Active filter chips ────────────────────────────────────────────────────
  Widget _buildActiveFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (_filter.startDate != null || _filter.endDate != null)
          _filterChip(
            icon: Icons.date_range,
            label: _getDateRangeLabel(),
            color: kVioletAccent,
            onDeleted: () => setState(
                () => _filter = _filter.clearDateRange()),
          ),
        ..._filter.types.map((t) => _filterChip(
              icon: _typeIconData(t),
              label: t[0].toUpperCase() + t.substring(1),
              color: _typeColor(t),
              onDeleted: () => setState(() => _filter =
                  _filter.copyWith(types: [..._filter.types]..remove(t))),
            )),
        if (_filter.statuses.length != 1 ||
            !_filter.statuses.contains('active'))
          ..._filter.statuses.map((s) => _filterChip(
                icon: s == 'active' ? Icons.check_circle : Icons.cancel,
                label: s[0].toUpperCase() + s.substring(1),
                color: s == 'active' ? Colors.green : Colors.red,
                onDeleted: () {
                  final ns = [..._filter.statuses]..remove(s);
                  setState(() => _filter = _filter.copyWith(
                      statuses: ns.isEmpty ? ['active'] : ns));
                  _saveFilters();
                },
              )),
        ActionChip(
          avatar: const Icon(Icons.clear_all, size: 14),
          label: const Text('Clear all',
              style: TextStyle(fontSize: 11)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onPressed: () {
            setState(() {
              _filter = ScheduleFilter.defaults;
              _searchController.clear();
            });
            _saveFilters();
          },
        ),
      ],
    );
  }

  Widget _filterChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onDeleted,
  }) {
    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label,
          style: TextStyle(fontSize: 11, color: color)),
      deleteIcon: Icon(Icons.close, size: 13, color: color),
      onDeleted: onDeleted,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ── Filter panel ──────────────────────────────────────────────────────────
  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Row(children: [
            const Text('Filters',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              child: const Text('Reset'),
              onPressed: () {
                setState(() {
                  _filter = ScheduleFilter.defaults;
                  _searchController.clear();
                });
                _saveFilters();
              },
            ),
          ]),
          const Divider(height: 16),

          // ── Date range ──────────────────────────────────────────────────
          _panelLabel('Date Range'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _presetChip('Today', () {
                final t = DateTime.now();
                setState(() => _filter = _filter.copyWith(
                      startDate: DateTime(t.year, t.month, t.day),
                      endDate:
                          DateTime(t.year, t.month, t.day, 23, 59, 59),
                    ));
                _saveFilters();
              }),
              _presetChip('This Week', () {
                final n = DateTime.now();
                final s =
                    n.subtract(Duration(days: n.weekday - 1));
                final e = s.add(const Duration(days: 6));
                setState(() => _filter = _filter.copyWith(
                      startDate:
                          DateTime(s.year, s.month, s.day),
                      endDate: DateTime(
                          e.year, e.month, e.day, 23, 59, 59),
                    ));
                _saveFilters();
              }),
              _presetChip('This Month', () {
                final n = DateTime.now();
                final s = DateTime(n.year, n.month);
                final e = DateTime(n.year, n.month + 1, 0);
                setState(() => _filter = _filter.copyWith(
                      startDate: s,
                      endDate: DateTime(
                          e.year, e.month, e.day, 23, 59, 59),
                    ));
                _saveFilters();
              }),
              _presetChip('Custom…', _pickCustomDateRange),
              if (_filter.startDate != null ||
                  _filter.endDate != null)
                ActionChip(
                  avatar:
                      const Icon(Icons.clear, size: 13),
                  label: const Text('Clear date',
                      style: TextStyle(fontSize: 11)),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  onPressed: () => setState(
                      () => _filter =
                          _filter.clearDateRange()),
                ),
            ],
          ),
          if (_filter.startDate != null ||
              _filter.endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kVioletAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          kVioletAccent.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.date_range,
                      size: 16, color: kVioletAccent),
                  const SizedBox(width: 8),
                  Text(_getDateRangeLabel(),
                      style: const TextStyle(
                          color: kVioletAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ]),
              ),
            ),

          const Divider(height: 24),

          // ── Type ────────────────────────────────────────────────────────
          _panelLabel('Schedule Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _typeFilterChip(
                  'consultation', 'Consultation', Icons.people),
              _typeFilterChip('class', 'Class', Icons.school),
              _typeFilterChip(
                  'meeting', 'Meeting', Icons.meeting_room),
            ],
          ),

          const Divider(height: 24),

          // ── Status ──────────────────────────────────────────────────────
          _panelLabel('Status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _statusFilterChip(
                  'active', 'Active', Icons.check_circle,
                  Colors.green),
              _statusFilterChip(
                  'cancelled', 'Cancelled', Icons.cancel,
                  Colors.red),
            ],
          ),

          const Divider(height: 24),

          // ── Sort ────────────────────────────────────────────────────────
          _panelLabel('Sort By'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _filter.sortBy,
                isDense: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'date', child: Text('Date')),
                  DropdownMenuItem(
                      value: 'time', child: Text('Time')),
                  DropdownMenuItem(
                      value: 'type', child: Text('Type')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() =>
                        _filter = _filter.copyWith(sortBy: v));
                    _saveFilters();
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(_filter.sortAscending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward),
              tooltip: _filter.sortAscending
                  ? 'Ascending'
                  : 'Descending',
              onPressed: () {
                setState(() => _filter = _filter.copyWith(
                    sortAscending: !_filter.sortAscending));
                _saveFilters();
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _panelLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
      );

  Widget _presetChip(String label, VoidCallback onTap) =>
      ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
        backgroundColor: Colors.grey.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  Widget _typeFilterChip(
      String value, String label, IconData icon) {
    final sel = _filter.types.contains(value);
    return FilterChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 14,
            color:
                sel ? _typeColor(value) : Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(label),
      ]),
      selected: sel,
      onSelected: (v) {
        final nt = [..._filter.types];
        v ? nt.add(value) : nt.remove(value);
        setState(() => _filter = _filter.copyWith(types: nt));
        _saveFilters();
      },
      selectedColor: _typeColor(value).withValues(alpha: 0.15),
      checkmarkColor: _typeColor(value),
      labelStyle: TextStyle(
        fontSize: 12,
        color: sel ? _typeColor(value) : Colors.black87,
        fontWeight:
            sel ? FontWeight.w600 : FontWeight.normal,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _statusFilterChip(String value, String label,
      IconData icon, MaterialColor color) {
    final sel = _filter.statuses.contains(value);
    return FilterChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 14,
            color: sel ? color.shade700 : Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(label),
      ]),
      selected: sel,
      onSelected: (v) {
        final ns = [..._filter.statuses];
        v ? ns.add(value) : ns.remove(value);
        if (ns.isEmpty) ns.add('active');
        setState(
            () => _filter = _filter.copyWith(statuses: ns));
        _saveFilters();
      },
      selectedColor: color.withValues(alpha: 0.15),
      checkmarkColor: color.shade700,
      labelStyle: TextStyle(
        fontSize: 12,
        color: sel ? color.shade900 : Colors.black87,
        fontWeight:
            sel ? FontWeight.w600 : FontWeight.normal,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // ── Filtered schedule list ─────────────────────────────────────────────────
  Widget _buildFilteredList(
      BuildContext context, FacultyProvider prov) {
    final all = prov.allSchedules;

    if (all.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: EmptySchedulesState(
          onAddSchedule: () => _showAddDialog(context, prov),
        ),
      );
    }

    final filtered = _applyFilters(all);
    if (filtered.isEmpty) {
      return _buildNoResultsState(context, prov);
    }

    final sorted = _applySorting(filtered);

    // Group by date label (date-based first, then legacy day-based)
    final grouped = <String, List<ScheduleModel>>{};
    for (final s in sorted) {
      if (s.date != null) {
        grouped
            .putIfAbsent(_formatDateLabel(s.date!), () => [])
            .add(s);
      } else if (s.day != null) {
        grouped.putIfAbsent(s.day!, () => []).add(s);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries
          .map((e) =>
              _buildDaySection(context, prov, e.key, e.value))
          .toList(),
    );
  }

  Widget _buildNoResultsState(
      BuildContext context, FacultyProvider prov) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(children: [
          Icon(Icons.search_off,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No schedules match your filters',
            style: TextStyle(
                fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
            onPressed: () {
              setState(() {
                _filter = ScheduleFilter.defaults;
                _searchController.clear();
              });
              _saveFilters();
            },
          ),
        ]),
      ),
    );
  }

  // ── Filter logic ──────────────────────────────────────────────────────────
  List<ScheduleModel> _applyFilters(List<ScheduleModel> list) {
    return list.where((s) {
      // Date range
      if (_filter.startDate != null || _filter.endDate != null) {
        if (s.date == null) return false;
        final dt = DateTime.tryParse(s.date!);
        if (dt == null) return false;
        if (_filter.startDate != null &&
            dt.isBefore(_filter.startDate!)) return false;
        if (_filter.endDate != null &&
            dt.isAfter(_filter.endDate!)) return false;
      }
      // Type
      if (_filter.types.isNotEmpty &&
          !_filter.types.contains(s.type)) return false;
      // Status
      if (!_filter.statuses.contains(s.status)) return false;
      // Search
      if (_filter.searchQuery.isNotEmpty) {
        final q = _filter.searchQuery;
        if (!s.title.toLowerCase().contains(q) &&
            !s.location.toLowerCase().contains(q) &&
            !s.type.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  List<ScheduleModel> _applySorting(List<ScheduleModel> list) {
    final sorted = List<ScheduleModel>.from(list);
    sorted.sort((a, b) {
      int cmp;
      switch (_filter.sortBy) {
        case 'time':
          cmp = a.timeStart.compareTo(b.timeStart);
          break;
        case 'type':
          cmp = a.type.compareTo(b.type);
          if (cmp == 0) {
            cmp = (a.date ?? '').compareTo(b.date ?? '');
          }
          break;
        default: // 'date'
          cmp = (a.date ?? '').compareTo(b.date ?? '');
          if (cmp == 0) {
            cmp = a.timeStart.compareTo(b.timeStart);
          }
      }
      return _filter.sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  // ── Persist filters ───────────────────────────────────────────────────────
  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'schedule_filter',
      jsonEncode({
        'types': _filter.types,
        'statuses': _filter.statuses,
        'sortBy': _filter.sortBy,
        'sortAscending': _filter.sortAscending,
      }),
    );
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('schedule_filter');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _filter = _filter.copyWith(
          types: List<String>.from(
              data['types'] as List? ?? []),
          statuses: List<String>.from(
              data['statuses'] as List? ?? ['active']),
          sortBy: data['sortBy'] as String? ?? 'date',
          sortAscending:
              data['sortAscending'] as bool? ?? true,
        );
      });
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _getDateRangeLabel() {
    final s = _filter.startDate;
    final e = _filter.endDate;
    if (s != null && e != null) {
      return '${DateFormat('MMM d').format(s)} – '
          '${DateFormat('MMM d, yyyy').format(e)}';
    } else if (s != null) {
      return 'From ${DateFormat('MMM d, yyyy').format(s)}';
    } else if (e != null) {
      return 'Until ${DateFormat('MMM d, yyyy').format(e)}';
    }
    return '';
  }

  IconData _typeIconData(String type) {
    switch (type) {
      case 'consultation':
        return Icons.people;
      case 'class':
        return Icons.school;
      case 'meeting':
        return Icons.meeting_room;
      default:
        return Icons.event;
    }
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate:
          DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: (_filter.startDate != null &&
              _filter.endDate != null)
          ? DateTimeRange(
              start: _filter.startDate!,
              end: _filter.endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kVioletAccent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _filter = _filter.copyWith(
            startDate: picked.start,
            endDate: picked.end,
          ));
      _saveFilters();
    }
  }

  // ==========================================================================
  //  Existing schedule-list builders (unchanged)
  // ==========================================================================

  Widget _buildDaySection(BuildContext context, FacultyProvider prov,
      String day, List<ScheduleModel> schedules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kVioletAccent,
            ),
          ),
        ),
        // Schedule rows
        ...schedules.map((s) => _buildRow(context, prov, s)),
        const Divider(height: 24),
      ],
    );
  }

  Widget _buildRow(
      BuildContext context, FacultyProvider prov, ScheduleModel schedule) {
    final isCancelled = schedule.isCancelled;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCancelled ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info row ───────────────────────────────────────
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            onTap: () => Navigator.of(context).pushNamed(
              '/schedule-details',
              arguments: schedule,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCancelled
                          ? Colors.red.shade400
                          : _typeColor(schedule.type),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    schedule.timeRange,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: kCardText,
                      decoration: isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _typeColor(schedule.type)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      schedule.type,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _typeColor(schedule.type),
                      ),
                    ),
                  ),
                  if (isCancelled) ...[  
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Cancelled',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${schedule.title}${schedule.location.isNotEmpty ? '  •  ${schedule.location}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCancelled
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Cancellation reason
          if (isCancelled &&
              (schedule.cancellationReason?.isNotEmpty ?? false))
            Padding(
              padding:
                  const EdgeInsets.only(left: 30, right: 12, bottom: 4),
              child: Text(
                'Reason: ${schedule.cancellationReason}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          // ── Action row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isCancelled) ...[  
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: kVioletAccent),
                    onPressed: () =>
                        _showEditDialog(context, prov, schedule),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 15),
                    label: const Text('Cancel',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.orange.shade700),
                    onPressed: () =>
                        _showCancelDialog(context, prov, schedule),
                  ),
                ] else ...[  
                  TextButton.icon(
                    icon: const Icon(Icons.restore, size: 15),
                    label: const Text('Restore',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.green.shade700),
                    onPressed: () =>
                        _restoreSchedule(context, prov, schedule),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.redAccent,
                  tooltip: 'Delete',
                  onPressed: () =>
                      _confirmDelete(context, prov, schedule),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'consultation':
        return kVioletAccent;
      case 'class':
        return Colors.blueGrey;
      case 'meeting':
        return Colors.orange;
      default:
        return kVioletAccent;
    }
  }

  // ---- Dialogs ----

  void _showAddDialog(BuildContext context, FacultyProvider prov) {
    showDialog(
      context: context,
      builder: (_) => AddScheduleDialog(prov: prov),
    );
  }

  void _showEditDialog(
      BuildContext context, FacultyProvider prov, ScheduleModel schedule) {
    _showSlotDialog(context, prov, schedule);
  }

  void _showCancelDialog(
      BuildContext context, FacultyProvider prov, ScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (_) =>
          _CancelScheduleDialog(schedule: schedule, prov: prov),
    );
  }

  Future<void> _restoreSchedule(
      BuildContext context, FacultyProvider prov, ScheduleModel schedule) async {
    if (schedule.date != null && prov.faculty != null) {
      try {
        final conflict = await FirestoreService().checkScheduleConflict(
          facultyId: prov.faculty!.id,
          date: schedule.date!,
          timeStart: schedule.timeStart,
          timeEnd: schedule.timeEnd,
          excludeScheduleId: schedule.id,
        );
        if (conflict != null && context.mounted) {
          _showConflictDialog(context, conflict);
          return;
        }
      } catch (_) {
        // Non-fatal — allow restore even if conflict check fails
      }
    }
    try {
      await prov.updateSchedule(schedule.id, {
        'status': 'active',
        'cancellation_reason': '',
        'cancelledAt': null,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule restored successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConflictDialog(BuildContext context, ScheduleModel conflicting) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 26),
            SizedBox(width: 10),
            Text('Time Conflict'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This time slot overlaps with an existing schedule:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 6),
                      Text(
                        conflicting.timeRange,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                  if (conflicting.title.isNotEmpty) ...[  
                    const SizedBox(height: 4),
                    Text(conflicting.title,
                        style: TextStyle(color: Colors.red.shade800)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    conflicting.type,
                    style: TextStyle(
                        color: Colors.red.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '💡 Choose a different time or date.',
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kVioletAccent,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK, Change Time'),
          ),
        ],
      ),
    );
  }

  /// Format an ISO date string for display as a section header.
  /// e.g. "2026-04-20" → "Monday, April 20, 2026"
  static String _formatDateLabel(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('EEEE, MMMM d, yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  /// Format a TimeOfDay as "8:00 AM".
  static String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Parse a stored time string (e.g. "8:00 AM" or "08:00") back to TimeOfDay.
  static TimeOfDay? _parseTime(String s) {
    if (s.isEmpty) return null;
    final upper = s.toUpperCase().trim();
    final isPm = upper.contains('PM');
    final cleaned = upper.replaceAll(RegExp(r'[APM ]'), '');
    final parts = cleaned.split(':');
    if (parts.length != 2) return null;
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _showSlotDialog(
      BuildContext context, FacultyProvider prov, ScheduleModel? existing) {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    String selectedType = existing?.type ?? 'consultation';
    // Pre-fill date from existing schedule (parse date or fall back to today)
    DateTime? selectedDate = (existing?.date != null)
        ? DateTime.tryParse(existing!.date!)
        : null;
    TimeOfDay? startTime = _parseTime(existing?.timeStart ?? '');
    TimeOfDay? endTime = _parseTime(existing?.timeEnd ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Slot' : 'Add New Slot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 8),
                // ── Date picker (replaces day dropdown) ──────────────────
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: kVioletAccent,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today, color: kVioletAccent),
                    ),
                    child: Text(
                      selectedDate != null
                          ? DateFormat('EEEE, MMM d, yyyy').format(selectedDate!)
                          : 'Select a date',
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedDate != null ? kCardText : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: startTime ?? const TimeOfDay(hour: 8, minute: 0),
                        );
                        if (picked != null) {
                          setDialogState(() => startTime = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Time'),
                        child: Text(
                          startTime != null ? _formatTime(startTime!) : 'Select',
                          style: TextStyle(
                            fontSize: 14,
                            color: startTime != null ? kCardText : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: endTime ?? const TimeOfDay(hour: 9, minute: 30),
                        );
                        if (picked != null) {
                          setDialogState(() => endTime = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End Time'),
                        child: Text(
                          endTime != null ? _formatTime(endTime!) : 'Select',
                          style: TextStyle(
                            fontSize: 14,
                            color: endTime != null ? kCardText : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'consultation', child: Text('Consultation')),
                    DropdownMenuItem(value: 'class', child: Text('Class')),
                    DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v ?? selectedType),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kVioletAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: (startTime == null || endTime == null || selectedDate == null || prov.faculty == null)
                  ? null
                  : () async {
                final startStr = _formatTime(startTime!);
                final endStr = _formatTime(endTime!);
                final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
                try {
                  // Check for time conflicts
                  final conflict =
                      await FirestoreService().checkScheduleConflict(
                    facultyId: prov.faculty!.id,
                    date: dateStr,
                    timeStart: startStr,
                    timeEnd: endStr,
                    excludeScheduleId: isEdit ? existing.id : null,
                  );
                  if (conflict != null) {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      _showConflictDialog(context, conflict);
                    }
                    return;
                  }
                  // NO CONFLICT - PROCEED WITH SAVE
                  if (isEdit) {
                    await prov.updateSchedule(existing.id, {
                      'title': titleCtrl.text.trim(),
                      'location': locationCtrl.text.trim(),
                      'date': dateStr,
                      'time_start': startStr,
                      'time_end': endStr,
                      'type': selectedType,
                    });
                  } else {
                    await prov.addSchedule(ScheduleModel(
                      id: '',
                      facultyId: prov.faculty!.id,
                      date: dateStr,
                      timeStart: startStr,
                      timeEnd: endStr,
                      type: selectedType,
                      title: titleCtrl.text.trim(),
                      location: locationCtrl.text.trim(),
                    ));
                  }
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit
                            ? 'Schedule updated!'
                            : 'Schedule added for ${DateFormat('MMM d, yyyy').format(selectedDate!)}'),
                        backgroundColor: kVioletAccent,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ [SchedulePage] Save error: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to save: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, FacultyProvider prov, ScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Slot'),
        content: Text(
            'Delete "${schedule.title.isNotEmpty ? schedule.title : schedule.type}"${schedule.formattedDate != null ? ' on ${schedule.formattedDate}' : ''}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              prov.deleteSchedule(schedule.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  Cancel Schedule Dialog
// =============================================================================

class _CancelScheduleDialog extends StatefulWidget {
  final ScheduleModel schedule;
  final FacultyProvider prov;

  const _CancelScheduleDialog(
      {required this.schedule, required this.prov});

  @override
  State<_CancelScheduleDialog> createState() =>
      _CancelScheduleDialogState();
}

class _CancelScheduleDialogState extends State<_CancelScheduleDialog> {
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;
  bool _loadingCount = true;
  int _bookingCount = 0;

  static FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'facconsult-firebase',
      );

  @override
  void initState() {
    super.initState();
    _loadBookingCount();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBookingCount() async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('schedule_id', isEqualTo: widget.schedule.id)
          .where('status', whereIn: ['pending', 'approved'])
          .get();
      if (mounted) {
        setState(() {
          _bookingCount = snap.docs.length;
          _loadingCount = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
          SizedBox(width: 10),
          Text('Cancel Schedule?'),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Schedule summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.schedule.formattedDate != null)
                    Text('\ud83d\udcc5 ${widget.schedule.formattedDate}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('\ud83d\udd50 ${widget.schedule.timeRange}'),
                  const SizedBox(height: 4),
                  Text('\ud83d\udcdd ${widget.schedule.type}'),
                  if (widget.schedule.location.isNotEmpty)
                    Text('\ud83d\udccd ${widget.schedule.location}'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Booking count warning
            if (_loadingCount)
              const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_bookingCount > 0)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.group,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '\u26a0\ufe0f $_bookingCount student${_bookingCount != 1 ? 's' : ''} will be notified',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                '\u2713 No active bookings for this schedule',
                style: TextStyle(
                    color: Colors.green.shade700, fontSize: 13),
              ),
            const SizedBox(height: 14),
            // Reason input
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g., Emergency, rescheduling...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Go Back'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _handleCancel,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Cancel Schedule'),
        ),
      ],
    );
  }

  Future<void> _handleCancel() async {
    setState(() => _isLoading = true);
    try {
      final reason = _reasonCtrl.text.trim();

      // Mark schedule cancelled + bulk-cancel bookings
      final affectedBookings =
          await widget.prov.cancelSchedule(widget.schedule.id, reason);

      // Queue notifications for affected students
      if (affectedBookings.isNotEmpty) {
        await NotificationService.sendCancellationNotifications(
          scheduleId: widget.schedule.id,
          bookings: affectedBookings,
          facultyName:
              widget.prov.faculty?.displayName ?? 'Faculty',
          scheduleDate: widget.schedule.formattedDate,
          timeStart: widget.schedule.timeStart,
          timeEnd: widget.schedule.timeEnd,
          location: widget.schedule.location,
          reason: reason,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_bookingCount > 0
                ? 'Schedule cancelled. $_bookingCount student${_bookingCount != 1 ? 's' : ''} notified.'
                : 'Schedule cancelled.'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// =============================================================================
//  Add Schedule Dialog  –  Single · Multiple · Recurring (multi-day)
// =============================================================================

class AddScheduleDialog extends StatefulWidget {
  final FacultyProvider prov;
  const AddScheduleDialog({super.key, required this.prov});

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  // ── form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _selectedType = 'consultation';

  // ── date mode ─────────────────────────────────────────────────────────────
  String _mode = 'single'; // 'single' | 'multiple' | 'recurring'

  // single
  DateTime? _singleDate;

  // multiple
  final List<DateTime> _multiDates = [];

  // recurring – multi-day (e.g. Mon/Wed/Fri + date range)
  final List<String> _recurringDays = []; // ["Monday", "Wednesday", "Friday"]
  DateTime? _recurStart;
  DateTime? _recurEnd;

  // ── time ──────────────────────────────────────────────────────────────────
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoading = false;

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  static const _weekdayNums = {
    'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
    'Friday': 5, 'Saturday': 6, 'Sunday': 7,
  };

  static final _isoFmt = DateFormat('yyyy-MM-dd');

  List<DateTime> _calcRecurring() {
    if (_recurringDays.isEmpty || _recurStart == null || _recurEnd == null) {
      return [];
    }
    final targets = _recurringDays
        .map((d) => _weekdayNums[d]!)
        .toSet();
    final result = <DateTime>[];
    var cur = _recurStart!;
    while (!cur.isAfter(_recurEnd!)) {
      if (targets.contains(cur.weekday)) result.add(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return result;
  }

  List<String> _datesToCreate() {
    switch (_mode) {
      case 'single':
        return _singleDate != null ? [_isoFmt.format(_singleDate!)] : [];
      case 'multiple':
        return _multiDates.map(_isoFmt.format).toList();
      case 'recurring':
        return _calcRecurring().map(_isoFmt.format).toList();
      default:
        return [];
    }
  }

  int get _scheduleCount => _datesToCreate().length;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Add New Schedule',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Mode selector
                _buildModeSelector(),
                const SizedBox(height: 18),

                // Date input (mode-specific)
                _buildDateSection(),
                const SizedBox(height: 18),

                // Time row
                _buildTimeRow(),
                const SizedBox(height: 14),

                // Type
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'consultation', child: Text('Consultation')),
                    DropdownMenuItem(value: 'class', child: Text('Class')),
                    DropdownMenuItem(
                        value: 'meeting', child: Text('Meeting')),
                  ],
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: 12),

                // Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Title (optional)',
                    hintText: 'e.g., Office Hours',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Location
                TextFormField(
                  controller: _locationCtrl,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g., Room 301',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a location'
                      : null,
                ),
                const SizedBox(height: 16),

                // Summary
                if (_scheduleCount > 0) _buildSummary(),
                if (_scheduleCount > 0) const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kVioletAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _handleCreate,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              'Create${_scheduleCount > 1 ? ' ($_scheduleCount)' : ''}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── mode selector ─────────────────────────────────────────────────────────
  Widget _buildModeSelector() {
    return Row(
      children: [
        _modeChip('single', Icons.event, 'Single'),
        const SizedBox(width: 8),
        _modeChip('multiple', Icons.date_range, 'Multiple'),
        const SizedBox(width: 8),
        _modeChip('recurring', Icons.repeat, 'Recurring'),
      ],
    );
  }

  Widget _modeChip(String value, IconData icon, String label) {
    final sel = _mode == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          _mode = value;
          _singleDate = null;
          _multiDates.clear();
          _recurringDays.clear();
          _recurStart = null;
          _recurEnd = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? kVioletAccent : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? kVioletAccent : Colors.grey.shade300,
              width: sel ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22,
                  color: sel ? Colors.white : Colors.grey.shade600),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? Colors.white : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── date section (mode-specific) ──────────────────────────────────────────
  Widget _buildDateSection() {
    switch (_mode) {
      case 'single':
        return _dateTile(
          label: _singleDate != null
              ? DateFormat('EEEE, MMMM d, yyyy').format(_singleDate!)
              : 'Select a date',
          filled: _singleDate != null,
          onTap: () async {
            final d = await _pickDate(context);
            if (d != null) setState(() => _singleDate = d);
          },
        );
      case 'multiple':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Date'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kVioletAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final d = await _pickDate(context);
                if (d != null && !_multiDates.any((x) =>
                    x.year == d.year &&
                    x.month == d.month &&
                    x.day == d.day)) {
                  setState(() {
                    _multiDates
                      ..add(d)
                      ..sort();
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            if (_multiDates.isEmpty)
              Text('No dates selected',
                  style: TextStyle(color: Colors.grey.shade500))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _multiDates.map((d) {
                  return Chip(
                    label:
                        Text(DateFormat('MMM d, yyyy').format(d)),
                    onDeleted: () =>
                        setState(() => _multiDates.remove(d)),
                    deleteIcon:
                        const Icon(Icons.close, size: 16),
                    backgroundColor:
                        kVioletAccent.withValues(alpha: 0.1),
                    labelStyle:
                        const TextStyle(color: kVioletAccent),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
          ],
        );
      case 'recurring':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Day chips
            Text('Select Days of Week',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weekdays
                  .map((day) => _dayChip(day))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // ── Quick presets
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.school, size: 15),
                  label: const Text('Weekdays',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4)),
                  onPressed: () => setState(() {
                    _recurringDays
                      ..clear()
                      ..addAll([
                        'Monday', 'Tuesday', 'Wednesday',
                        'Thursday', 'Friday'
                      ]);
                  }),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 15),
                  label: const Text('Clear',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4)),
                  onPressed: () =>
                      setState(() => _recurringDays.clear()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Date range
            Text('Date Range',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _dateTile(
                    label: _recurStart != null
                        ? DateFormat('MMM d, yyyy')
                            .format(_recurStart!)
                        : 'From',
                    filled: _recurStart != null,
                    onTap: () async {
                      final d = await _pickDate(context,
                          last: _recurEnd);
                      if (d != null) {
                        setState(() => _recurStart = d);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateTile(
                    label: _recurEnd != null
                        ? DateFormat('MMM d, yyyy')
                            .format(_recurEnd!)
                        : 'To',
                    filled: _recurEnd != null,
                    onTap: () async {
                      final d = await _pickDate(context,
                          first: _recurStart ?? DateTime.now());
                      if (d != null) {
                        setState(() => _recurEnd = d);
                      }
                    },
                  ),
                ),
              ],
            ),
            // ── Preview count
            if (_recurringDays.isNotEmpty &&
                _recurStart != null &&
                _recurEnd != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kVioletAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: kVioletAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '📅 ${_calcRecurring().length} date(s) will be created',
                    style: const TextStyle(
                        color: kVioletAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _dayChip(String day) {
    final sel = _recurringDays.contains(day);
    return FilterChip(
      label: Text(day.substring(0, 3)),
      selected: sel,
      onSelected: (v) => setState(() {
        if (v) {
          _recurringDays.add(day);
        } else {
          _recurringDays.remove(day);
        }
      }),
      selectedColor: kVioletAccent,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: sel ? Colors.white : Colors.black87,
        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
          color: sel ? kVioletAccent : Colors.grey.shade300),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _dateTile({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: filled ? kVioletAccent : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                color: filled ? kVioletAccent : Colors.grey.shade400,
                size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: filled ? kCardText : Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── time row ──────────────────────────────────────────────────────────────
  // Returns the first "representative" date in the current selection,
  // used to decide whether to show the "today" hint and to validate times.
  DateTime? get _firstDate {
    switch (_mode) {
      case 'single':
        return _singleDate;
      case 'multiple':
        return _multiDates.isNotEmpty ? _multiDates.first : null;
      case 'recurring':
        return _recurStart;
      default:
        return null;
    }
  }

  Widget _buildTimeRow() {
    final first = _firstDate;
    final isToday = first != null && _isToday(first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _startTimeTile()),
            const SizedBox(width: 10),
            Expanded(child: _endTimeTile()),
          ],
        ),
        // ── Hint when today is selected
        if (isToday) ...
          [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 15, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only future times are allowed for today\'s date',
                      style: TextStyle(
                          fontSize: 11, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }

  Widget _startTimeTile() {
    final first = _firstDate;
    return InkWell(
      onTap: () async {
        final initial = (first != null && _isToday(first))
            ? TimeValidator.getNextAvailableTime()
            : (_startTime ?? const TimeOfDay(hour: 8, minute: 0));

        final t = await showTimePicker(
          context: context,
          initialTime: initial,
          helpText: 'Select Start Time',
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: kVioletAccent,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (t == null) return;

        // Reject past times on today
        if (first != null && TimeValidator.isTimePast(date: first, time: t)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      '${TimeValidator.formatTimeOfDay(t)} has already passed today'),
                ),
              ]),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ));
          }
          return;
        }

        setState(() {
          _startTime = t;
          // Clear end time if it's no longer after start
          if (_endTime != null &&
              !TimeValidator.isEndTimeValid(
                  startTime: t, endTime: _endTime!)) {
            _endTime = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: _timeTileContainer(
        label: 'Start Time',
        value: _startTime,
        dimmed: false,
      ),
    );
  }

  Widget _endTimeTile() {
    return InkWell(
      onTap: _startTime == null
          ? null
          : () async {
              final suggested = TimeOfDay(
                hour: (_startTime!.hour + 1) % 24,
                minute: _startTime!.minute,
              );
              final t = await showTimePicker(
                context: context,
                initialTime: _endTime ?? suggested,
                helpText: 'Select End Time',
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: kVioletAccent,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (t == null) return;

              if (!TimeValidator.isEndTimeValid(
                  startTime: _startTime!, endTime: t)) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        const Text('End time must be after start time'),
                    backgroundColor: Colors.orange.shade600,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
                return;
              }
              setState(() => _endTime = t);
            },
      borderRadius: BorderRadius.circular(12),
      child: _timeTileContainer(
        label: 'End Time',
        value: _endTime,
        dimmed: _startTime == null,
        hint: _startTime == null ? 'Select start first' : null,
      ),
    );
  }

  Widget _timeTileContainer({
    required String label,
    required TimeOfDay? value,
    required bool dimmed,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dimmed ? Colors.grey.shade50 : Colors.white,
        border: Border.all(
          color: value != null ? kVioletAccent : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 14,
                  color: dimmed
                      ? Colors.grey.shade400
                      : Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: dimmed
                          ? Colors.grey.shade400
                          : Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value != null
                ? TimeValidator.formatTimeOfDay(value)
                : (hint ?? 'Select'),
            style: TextStyle(
              fontSize: 14,
              color: value != null
                  ? kCardText
                  : Colors.grey.shade400,
              fontWeight: value != null
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  // ── summary ───────────────────────────────────────────────────────────────
  Widget _buildSummary() {
    String detail = 'Will create $_scheduleCount schedule${_scheduleCount > 1 ? 's' : ''}';
    if (_mode == 'recurring' && _recurringDays.isNotEmpty &&
        _recurStart != null && _recurEnd != null) {
      final days = _recurringDays.map((d) => d.substring(0, 3)).join(', ');
      detail += '\n$days  '
          '${DateFormat('MMM d').format(_recurStart!)} – '
          '${DateFormat('MMM d').format(_recurEnd!)}';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kVioletAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kVioletAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: kVioletAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail,
              style: const TextStyle(
                  color: kVioletAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── date picker helper ────────────────────────────────────────────────────
  Future<DateTime?> _pickDate(BuildContext context,
      {DateTime? first, DateTime? last}) {
    return showDatePicker(
      context: context,
      initialDate: first ?? DateTime.now(),
      firstDate: first ?? DateTime.now(),
      lastDate: last ?? DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kVioletAccent,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
  }

  // ── submit ────────────────────────────────────────────────────────────────
  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final dates = _datesToCreate();
    if (dates.isEmpty) {
      _snack('Please select at least one date', Colors.red);
      return;
    }
    if (_startTime == null || _endTime == null) {
      _snack('Please select start and end times', Colors.red);
      return;
    }

    // Validate each date's time against the clock
    for (final dateStr in dates) {
      final date = DateTime.parse(dateStr);
      final err = TimeValidator.validateTime(
          date: date, startTime: _startTime, endTime: _endTime);
      if (err != null) {
        _snack('$err (${DateFormat('MMM d, yyyy').format(date)})',
            Colors.red);
        return;
      }
    }

    final startStr = TimeValidator.formatTimeOfDay(_startTime!);
    final endStr = TimeValidator.formatTimeOfDay(_endTime!);
    final faculty = widget.prov.faculty;
    if (faculty == null) {
      _snack('Faculty not loaded', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirestoreService().batchCreateSchedules(
        dates: dates,
        facultyId: faculty.id,
        timeStart: startStr,
        timeEnd: endStr,
        type: _selectedType,
        title: _titleCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Created ${ dates.length} schedule${dates.length > 1 ? 's' : ''}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ));
      }
    } on Exception catch (e) {
      if (mounted) _showConflictError(e.toString());
    } catch (e) {
      if (mounted) _snack('Failed to create: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _showConflictError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 26),
            SizedBox(width: 10),
            Text('Schedule Conflict'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You already have active schedules at the same time on:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.replaceFirst(
                    'Exception: Conflicts found on: ', ''),
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\ud83d\udca1 Remove those dates or choose a different time slot.',
              style: TextStyle(
                  color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }
}
