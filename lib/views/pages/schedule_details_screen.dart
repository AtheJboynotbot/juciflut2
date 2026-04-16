import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/schedule_model.dart';
import '../../providers/faculty_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../dashboard_shell.dart';

/// Detail view for a single schedule slot.
/// This fulfills the "Details from an Item" screen requirement.
class ScheduleDetailsScreen extends StatelessWidget {
  const ScheduleDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! ScheduleModel) {
      // Arguments lost (e.g. web page refresh) — go back to dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      });
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final schedule = args;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/Juci Univ2.png', fit: BoxFit.cover),
              Container(color: Colors.black.withValues(alpha: 0.35)),
            ],
          ),
          // Blue top stripe
          Positioned(
            top: 0, left: 0, right: 0, height: 4,
            child: Container(color: kTopStripe),
          ),
          // Content
          Column(
            children: [
              const SizedBox(height: 4),
              _buildTopBar(context),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _buildDetailsCard(context, schedule),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF000080),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          ClipOval(
            child: Image.asset(
              'assets/images/Logo.png',
              width: 36, height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Schedule Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, ScheduleModel schedule) {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title / Type header
          Row(
            children: [
              Container(
                width: 6,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor(schedule.type),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  schedule.title.isNotEmpty ? schedule.title : schedule.type,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kCardText,
                  ),
                ),
              ),
              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _typeColor(schedule.type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  schedule.type[0].toUpperCase() + schedule.type.substring(1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _typeColor(schedule.type),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          // Detail rows
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            schedule.date != null
                ? DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(schedule.date!))
                : schedule.displayDate,
          ),
          _buildDetailRow(
              Icons.access_time, 'Time', schedule.timeRange),
          _buildDetailRow(
              Icons.location_on_outlined, 'Location',
              schedule.location.isNotEmpty ? schedule.location : '—'),
          if (schedule.createdAt != null)
            _buildDetailRow(Icons.schedule, 'Created',
                '${schedule.createdAt!.day}/${schedule.createdAt!.month}/${schedule.createdAt!.year}'),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to Dashboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kVioletAccent,
                    side: const BorderSide(color: kVioletAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final prov = context.read<FacultyProvider>();
                    prov.deleteSchedule(schedule.id);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete Slot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kVioletAccent),
          const SizedBox(width: 14),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kCardText,
              ),
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
}
