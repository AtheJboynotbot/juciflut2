import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Bookings Page - displays and manages consultation bookings
/// 
/// Features:
/// - Filter by status (all, pending, approved, completed, etc.)
/// - Approve/reject pending requests
/// - Cancel bookings
/// - Mark bookings as completed
class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  static const Color kVioletAccent = Color(0xFF7C4DFF);
  static const Color kCardText = Color(0xFF2D2D44);
  static const Color kGreenAccent = Color(0xFF4CAF50);
  static const Color kRedAccent = Color(0xFFF44336);
  static const Color kOrangeAccent = Color(0xFFFF9800);
  static const Color kBlueAccent = Color(0xFF2196F3);
  static const Color kGreyAccent = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Consultation Bookings',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage student consultation requests',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // Stats cards
                _buildStatsRow(provider, isMobile),
                const SizedBox(height: 24),

                // Filter tabs
                _buildFilterTabs(provider, isMobile),
                const SizedBox(height: 16),

                // Bookings list
                if (provider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: kVioletAccent),
                    ),
                  )
                else if (provider.error != null)
                  _buildErrorCard(provider.error!)
                else if (provider.filteredBookings.isEmpty)
                  _buildEmptyState(provider.selectedStatus)
                else
                  _buildBookingsList(provider.filteredBookings, isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build statistics row showing counts by status
  Widget _buildStatsRow(BookingProvider provider, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Pending', provider.pendingCount, kOrangeAccent)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Approved', provider.approvedCount, kGreenAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Completed', provider.completedCount, kBlueAccent)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Total', provider.allBookings.length, kVioletAccent)),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildStatCard('Pending', provider.pendingCount, kOrangeAccent)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Approved', provider.approvedCount, kGreenAccent)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Completed', provider.completedCount, kBlueAccent)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Total', provider.allBookings.length, kVioletAccent)),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kCardText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// Build filter tabs
  Widget _buildFilterTabs(BookingProvider provider, bool isMobile) {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Pending', 'value': BookingStatus.pending},
      {'label': 'Approved', 'value': BookingStatus.approved},
      {'label': 'Completed', 'value': BookingStatus.completed},
      {'label': 'Rejected', 'value': BookingStatus.rejected},
      {'label': 'Cancelled', 'value': BookingStatus.cancelled},
    ];

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters
              .map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      f['label'] as String,
                      f['value'] as String,
                      provider.selectedStatus == f['value'],
                      () => provider.setFilter(f['value'] as String),
                    ),
                  ))
              .toList(),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: filters
          .map((f) => _buildFilterChip(
                f['label'] as String,
                f['value'] as String,
                provider.selectedStatus == f['value'],
                () => provider.setFilter(f['value'] as String),
              ))
          .toList(),
    );
  }

  /// Build individual filter chip
  Widget _buildFilterChip(String label, String value, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? kVioletAccent
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kVioletAccent : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : kCardText,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Build bookings list
  Widget _buildBookingsList(List<BookingModel> bookings, bool isMobile) {
    return Column(
      children: bookings.map((booking) => _buildBookingCard(booking, isMobile)).toList(),
    );
  }

  /// Build individual booking card
  Widget _buildBookingCard(BookingModel booking, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassmorphicCard(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kCardText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.studentEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.studentDepartment,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(booking.status),
            ],
          ),
          const SizedBox(height: 12),

          // Reason
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason for Consultation:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.reason,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kCardText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Metadata
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildMetaInfo(Icons.calendar_today, 'Requested', _formatDate(booking.createdAt)),
              _buildMetaInfo(Icons.update, 'Updated', _formatDate(booking.updatedAt)),
              if (booking.completedAt != null)
                _buildMetaInfo(Icons.check_circle, 'Completed', _formatDate(booking.completedAt!)),
            ],
          ),

          // Rejection/Cancellation reason
          if (booking.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kRedAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kRedAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: kRedAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rejection reason: ${booking.rejectionReason}',
                      style: TextStyle(fontSize: 12, color: kRedAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (booking.cancellationReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kGreyAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGreyAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: kGreyAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cancellation reason: ${booking.cancellationReason}',
                      style: TextStyle(fontSize: 12, color: kGreyAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          if (booking.canBeApproved || booking.canBeRejected || booking.canBeCancelled || booking.canBeCompleted) ...[
            const SizedBox(height: 16),
            _buildActionButtons(booking, isMobile),
          ],
        ],
        ),
      ),
    );
  }

  /// Build status badge
  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case BookingStatus.pending:
        color = kOrangeAccent;
        icon = Icons.schedule;
        break;
      case BookingStatus.approved:
        color = kGreenAccent;
        icon = Icons.check_circle;
        break;
      case BookingStatus.rejected:
        color = kRedAccent;
        icon = Icons.cancel;
        break;
      case BookingStatus.completed:
        color = kBlueAccent;
        icon = Icons.done_all;
        break;
      case BookingStatus.cancelled:
        color = kGreyAccent;
        icon = Icons.block;
        break;
      default:
        color = kGreyAccent;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            BookingStatus.getDisplayName(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build metadata info
  Widget _buildMetaInfo(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BookingModel booking, bool isMobile) {
    return Builder(
      builder: (context) {
        final provider = Provider.of<BookingProvider>(context, listen: false);

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (booking.canBeApproved)
              ElevatedButton.icon(
                onPressed: () => _handleApprove(context, provider, booking),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreenAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            if (booking.canBeRejected)
              OutlinedButton.icon(
                onPressed: () => _handleReject(context, provider, booking),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kRedAccent,
                  side: const BorderSide(color: kRedAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            if (booking.canBeCompleted)
              ElevatedButton.icon(
                onPressed: () => _handleComplete(context, provider, booking),
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('Mark Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            if (booking.canBeCancelled)
              OutlinedButton.icon(
                onPressed: () => _handleCancel(context, provider, booking),
                icon: const Icon(Icons.block, size: 16),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kGreyAccent,
                  side: BorderSide(color: kGreyAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Build empty state
  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;

    if (filter == 'all') {
      message = 'No bookings yet';
      icon = Icons.event_available;
    } else if (filter == BookingStatus.pending) {
      message = 'No pending requests';
      icon = Icons.schedule;
    } else if (filter == BookingStatus.approved) {
      message = 'No approved bookings';
      icon = Icons.check_circle;
    } else if (filter == BookingStatus.completed) {
      message = 'No completed consultations';
      icon = Icons.done_all;
    } else {
      message = 'No ${BookingStatus.getDisplayName(filter).toLowerCase()} bookings';
      icon = Icons.search_off;
    }

    return GlassmorphicCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(icon, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build error card
  Widget _buildErrorCard(String error) {
    return GlassmorphicCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kRedAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kRedAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: kRedAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: TextStyle(color: kRedAccent, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // ACTION HANDLERS
  // =========================================================================

  void _handleApprove(BuildContext context, BookingProvider provider, BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Booking'),
        content: Text('Approve consultation request from ${booking.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kGreenAccent),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.approveBooking(booking.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking approved successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to approve: $e')),
          );
        }
      }
    }
  }

  void _handleReject(BuildContext context, BookingProvider provider, BookingModel booking) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject consultation request from ${booking.studentName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kRedAccent),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.rejectBooking(
          booking.id,
          rejectionReason: controller.text.trim().isEmpty ? null : controller.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking rejected')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject: $e')),
          );
        }
      }
    }
  }

  void _handleCancel(BuildContext context, BookingProvider provider, BookingModel booking) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel booking for ${booking.studentName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kGreyAccent),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.cancelBooking(
          booking.id,
          cancellationReason: controller.text.trim().isEmpty ? null : controller.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e')),
          );
        }
      }
    }
  }

  void _handleComplete(BuildContext context, BookingProvider provider, BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: Text('Mark consultation with ${booking.studentName} as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kBlueAccent),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.completeBooking(booking.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking marked as completed')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to complete: $e')),
          );
        }
      }
    }
  }

  // =========================================================================
  // UTILITY METHODS
  // =========================================================================

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }
}
