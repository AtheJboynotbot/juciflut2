import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_model.dart';
import '../providers/booking_provider.dart';
import '../providers/faculty_provider.dart';

/// Dialog for creating a new booking request
/// 
/// Faculty can book consultation slots on behalf of students
class BookingRequestDialog extends StatefulWidget {
  final ScheduleModel schedule;

  const BookingRequestDialog({
    super.key,
    required this.schedule,
  });

  @override
  State<BookingRequestDialog> createState() => _BookingRequestDialogState();
}

class _BookingRequestDialogState extends State<BookingRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _studentEmailController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _studentEmailController.dispose();
    _studentNameController.dispose();
    _departmentController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Book Consultation Slot'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Schedule info
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
                      widget.schedule.title.isNotEmpty
                          ? widget.schedule.title
                          : 'Consultation',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.schedule.day} • ${widget.schedule.timeRange}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (widget.schedule.location.isNotEmpty)
                      Text(
                        widget.schedule.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Student Email
              TextFormField(
                controller: _studentEmailController,
                decoration: const InputDecoration(
                  labelText: 'Student Email',
                  hintText: 'student@addu.edu.ph',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Student Name
              TextFormField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Department
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  hintText: 'e.g., Computer Science',
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter department';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reason
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Consultation',
                  hintText: 'Brief description...',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter reason for consultation';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C4DFF),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Book Slot'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final facultyProvider = Provider.of<FacultyProvider>(context, listen: false);

      if (facultyProvider.faculty == null) {
        throw Exception('Faculty not loaded');
      }

      await bookingProvider.createBooking(
        scheduleId: widget.schedule.id,
        facultyId: widget.schedule.facultyId,
        studentEmail: _studentEmailController.text.trim(),
        studentName: _studentNameController.text.trim(),
        studentDepartment: _departmentController.text.trim(),
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request created successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
