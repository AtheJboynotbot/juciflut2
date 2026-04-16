import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/faculty_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glassmorphic_card.dart';
import '../dashboard_shell.dart';

/// My Account page – dynamically fetches and displays user data from Firestore.
/// Editable fields: Name, DOB, Phone, Office Location, Profile Picture.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _officeCtrl = TextEditingController();
  final _firestoreService = FirestoreService();
  String? _selectedDepartmentId;
  DateTime? _selectedDate;
  String? _newProfileImageUrl;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _officeCtrl.dispose();
    super.dispose();
  }

  /// Sync controllers with the latest Firestore data on first load.
  void _syncControllers(FacultyProvider prov) {
    if (!_initialized && prov.faculty != null) {
      _firstNameCtrl.text = prov.faculty!.firstName;
      _lastNameCtrl.text = prov.faculty!.lastName;
      _phoneCtrl.text = prov.faculty!.phoneNumber.isNotEmpty ? prov.faculty!.phoneNumber : '';
      _officeCtrl.text = prov.faculty!.officeLocation.isNotEmpty ? prov.faculty!.officeLocation : '';
      _selectedDepartmentId = prov.faculty!.departmentId.isNotEmpty ? prov.faculty!.departmentId : null;
      _selectedDate = prov.faculty!.dateOfBirth;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FacultyProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: kVioletAccent),
          );
        }

        if (prov.error != null) {
          return Center(
            child: GlassmorphicCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prov.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared! Please refresh.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear Cache & Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kVioletAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        _syncControllers(prov);
        final faculty = prov.faculty;

        return SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideLayout = constraints.maxWidth > 700;
              final isMobile = constraints.maxWidth < 500;
              
              return GlassmorphicCard(
                padding: EdgeInsets.all(isWideLayout ? 24 : (isMobile ? 16 : 20)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        padding: EdgeInsets.only(bottom: isWideLayout ? 20 : 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: kCardText.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              size: isWideLayout ? 28 : 24,
                              color: kVioletAccent,
                            ),
                            SizedBox(width: isWideLayout ? 12 : 8),
                            Text(
                              'My Account',
                              style: TextStyle(
                                fontSize: isWideLayout ? 24 : 20,
                                fontWeight: FontWeight.w700,
                                color: kCardText,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isWideLayout ? 28 : 20),
                  // ── Avatar + read-only info ───────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: kVioletAccent.withValues(alpha: 0.3),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kVioletAccent.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: isMobile ? 40 : 50,
                              backgroundColor: kVioletAccent.withValues(alpha: 0.08),
                              child: (_newProfileImageUrl != null || faculty?.profileImageUrl.isNotEmpty == true)
                                  ? ClipOval(
                                      child: kIsWeb
                                          ? Image.network(
                                              _newProfileImageUrl ?? faculty!.profileImageUrl,
                                              width: isMobile ? 80 : 100,
                                              height: isMobile ? 80 : 100,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 3,
                                                    color: kVioletAccent,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                print('❌ [ProfilePage] Failed to load image: $error');
                                                return Icon(
                                                  Icons.person,
                                                  color: kVioletAccent,
                                                  size: isMobile ? 40 : 48,
                                                );
                                              },
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: _newProfileImageUrl ?? faculty!.profileImageUrl,
                                              width: isMobile ? 80 : 100,
                                              height: isMobile ? 80 : 100,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 3,
                                                  color: kVioletAccent,
                                                ),
                                              ),
                                              errorWidget: (context, url, error) {
                                                print('❌ [ProfilePage] Failed to load image: $error');
                                                return Icon(
                                                  Icons.person,
                                                  color: kVioletAccent,
                                                  size: isMobile ? 40 : 48,
                                                );
                                              },
                                            ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      color: kVioletAccent,
                                      size: isMobile ? 40 : 48,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _isUploadingImage ? null : _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _newProfileImageUrl != null ? Colors.green : kVioletAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: _isUploadingImage
                                    ? const SizedBox(
                                        width: 12, height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        _newProfileImageUrl != null ? Icons.check : Icons.camera_alt,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              faculty?.displayName ?? 'No name set',
                              style: TextStyle(
                                fontSize: isMobile ? 15 : 16,
                                fontWeight: FontWeight.w700,
                                color: kCardText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              faculty?.email ?? '',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: isMobile ? 24 : 32),
                  // ── Dynamic info from Firestore ───────────────────
                  _buildInfoRow('Email', faculty?.email ?? '—'),
                  _buildInfoRow('Department ID',
                      faculty?.departmentId.isNotEmpty == true
                          ? faculty!.departmentId
                          : '—'),
                  _buildInfoRow('Status',
                      faculty?.availabilityStatus ?? 'away'),
                  const SizedBox(height: 12),
                  // Fix corrupted URL button
                  if (faculty?.profileImageUrl.isNotEmpty == true && faculty!.profileImageUrl.contains('\n'))
                    TextButton.icon(
                      onPressed: () async {
                        final cleanedUrl = faculty.profileImageUrl.replaceAll(RegExp(r'\s+'), '');
                        try {
                          await prov.updateProfile({'profile_image_url': cleanedUrl});
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile image URL fixed!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Fix failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.healing, color: Colors.orange),
                      label: const Text('Fix Corrupted Image URL', style: TextStyle(color: Colors.orange)),
                    ),
                  const SizedBox(height: 16),
                  // ── Editable fields ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: kCardText.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: kVioletAccent,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: kCardText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isWideLayout ? 24 : 20),
                  // First Name
                  TextFormField(
                    controller: _firstNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: const Icon(Icons.person_outline,
                          color: kVioletAccent),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: kVioletAccent, width: 2),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'First name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Last Name
                  TextFormField(
                    controller: _lastNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: const Icon(Icons.person_outline,
                          color: kVioletAccent),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: kVioletAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Phone Number
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined,
                          color: kVioletAccent),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: kVioletAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Office Location
                  TextFormField(
                    controller: _officeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Office Location',
                      prefixIcon: const Icon(Icons.location_on_outlined,
                          color: kVioletAccent),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: kVioletAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Department
                  StreamBuilder<List<Map<String, String>>>(
                    stream: _firestoreService.departmentsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Department',
                            prefixIcon: const Icon(Icons.business_outlined,
                                color: kVioletAccent),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kVioletAccent,
                              ),
                            ),
                          ),
                        );
                      }

                      final departments = snapshot.data ?? [];
                      
                      return DropdownButtonFormField<String>(
                        value: _selectedDepartmentId,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          prefixIcon: const Icon(Icons.business_outlined,
                              color: kVioletAccent),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: kVioletAccent, width: 2),
                          ),
                        ),
                        items: departments.map((dept) {
                          return DropdownMenuItem<String>(
                            value: dept['id'],
                            child: Text(dept['name'] ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartmentId = value;
                          });
                        },
                        hint: const Text('Select Department'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Date of Birth
                  InkWell(
                    onTap: () => _pickDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: const Icon(Icons.cake_outlined,
                            color: kVioletAccent),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: kVioletAccent, width: 2),
                        ),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                            : 'Tap to select',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate != null ? kCardText : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isWideLayout ? 32 : 24),
                  // Save button
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: isWideLayout ? 300 : double.infinity,
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _saveProfile(prov),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kVioletAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: kVioletAccent.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.save_outlined, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Read-only info row for displaying Firestore data.
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kCardText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kVioletAccent,
              onPrimary: Colors.white,
              onSurface: kCardText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickAndUploadImage() async {
    print('🔵 [ProfilePage] Opening file picker...');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      print('⚠️ [ProfilePage] No file selected');
      return;
    }

    setState(() => _isUploadingImage = true);

    try {
      final file = result.files.first;
      final bytes = file.bytes;
      
      if (bytes == null) {
        throw Exception('Could not read file bytes');
      }

      print('🔵 [ProfilePage] Uploading ${file.name} (${bytes.length} bytes)...');
      final fileName = 'faculty_${DateTime.now().millisecondsSinceEpoch}.${file.extension ?? "jpg"}';
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');
      
      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/${file.extension ?? "jpeg"}'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = (await snapshot.ref.getDownloadURL()).replaceAll(RegExp(r'\s+'), '');

      print('✅ [ProfilePage] Image uploaded! URL: $downloadUrl');

      if (mounted) {
        setState(() {
          _newProfileImageUrl = downloadUrl;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded! Click "Save Profile" to update.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [ProfilePage] Upload failed: $e');
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile(FacultyProvider prov) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = <String, dynamic>{
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
        'office_location': _officeCtrl.text.trim(),
        'department_id': _selectedDepartmentId ?? '',
      };

      // Add date of birth if selected
      if (_selectedDate != null) {
        data['date_of_birth'] = _selectedDate;
      }

      // Add new profile image URL if uploaded
      if (_newProfileImageUrl != null) {
        print('🔵 [ProfilePage] Including new image URL: $_newProfileImageUrl');
        data['profile_image_url'] = _newProfileImageUrl;
      } else {
        print('⚠️ [ProfilePage] No new image URL to save');
      }

      print('🔵 [ProfilePage] Saving profile data: $data');
      await prov.updateProfile(data);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _initialized = false; // re-sync on next build from Firestore stream
          _newProfileImageUrl = null; // clear temp URL
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: kVioletAccent,
          ),
        );
      }
    } catch (e) {
      print('❌ [ProfilePage] Save error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
