import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// Theme colors – glassmorphism palette from the JuCi reference design:
//   – Dark overlay on university building background
//   – Frosted translucent white cards
//   – Purple / violet accent (selected nav, buttons)
//   – Thin blue accent stripe at top
// ---------------------------------------------------------------------------
const Color _kVioletAccent = Color(0xFF7C4DFF);
const Color _kVioletLight = Color(0xFFB388FF);
const Color _kTopStripe = Color(0xFF3D5AFE);
const Color _kCardText = Color(0xFF2D2D3A);
const Color _kSubtleGrey = Color(0xFF757575);

// ---------------------------------------------------------------------------
// WebLoginScreen – glassmorphism login for the faculty web portal
// ---------------------------------------------------------------------------
class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  // ---- controllers & state ------------------------------------------------
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUp = false;
  String? _errorMessage;

  // ---- Firebase instances (lazy – avoids crash before Firebase.initializeApp) --
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'facconsult-firebase',
      );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // =========================================================================
  //  FIREBASE AUTH – Email / Password Sign In
  // =========================================================================
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential.user != null) {
        _handlePostLogin(credential.user!);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapFirebaseAuthError(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================================================================
  //  FIREBASE AUTH – Create Account
  // =========================================================================
  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential.user != null) {
        // Update display name if provided
        final name = _nameController.text.trim();
        if (name.isNotEmpty) {
          await credential.user!.updateDisplayName(name);
        }
        _handlePostLogin(credential.user!);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapFirebaseAuthError(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================================================================
  //  FIREBASE AUTH – Google Sign-In (web: uses signInWithPopup directly)
  // =========================================================================
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final userCredential = await _auth.signInWithPopup(googleProvider);

      if (userCredential.user != null) {
        _handlePostLogin(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapFirebaseAuthError(e.code));
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      setState(() => _errorMessage = 'Google sign-in error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================================================================
  //  FIRESTORE RBAC – Check / create user document with role
  // =========================================================================
  Future<void> _handlePostLogin(User user) async {
    // Navigate immediately — don't wait for Firestore
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }

    // Fire-and-forget: ensure a faculty doc exists for this email
    _ensureFacultyDoc(user);
  }

  /// Background task — creates a faculty doc if one doesn't exist yet.
  Future<void> _ensureFacultyDoc(User user) async {
    print('🔵 [ensureFacultyDoc] Checking for: ${user.email}');
    try {
      final query = await _firestore
          .collection('faculty')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('⚠️ [ensureFacultyDoc] No faculty doc found, creating one...');
        final nameParts = (user.displayName ?? '').split(' ');
        final docRef = await _firestore.collection('faculty').add({
          'email': user.email ?? '',
          'first_name': nameParts.isNotEmpty ? nameParts.first : '',
          'last_name': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          'department_id': '',
          'availability_status': 'away',
          'profile_image_url': user.photoURL ?? '',
          'phone_number': '',
          'office_location': '',
          'date_of_birth': null,
        });
        print('✅ [ensureFacultyDoc] Created faculty doc: ${docRef.id}');
      } else {
        print('✅ [ensureFacultyDoc] Faculty doc exists: ${query.docs.first.id}');
      }
    } catch (e) {
      print('❌ [ensureFacultyDoc] ERROR: $e');
      debugPrint('Firestore post-login error: $e');
    }
  }

  // =========================================================================
  //  Map Firebase error codes to user-friendly messages
  // =========================================================================
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try later.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'Authentication failed (code: $code).';
    }
  }

  // =========================================================================
  //  BUILD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-bleed dark background (simulates the building photo overlay)
          _buildBackground(),
          // Blue accent stripe at the very top (matches reference)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 4,
            child: Container(color: _kTopStripe),
          ),
          // Centered frosted login card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: _buildLoginCard(),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  //  Background – dark overlay simulating the university building photo
  // -------------------------------------------------------------------------
  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/Juci Univ2.png',
          fit: BoxFit.cover,
        ),
        // Dark overlay for glassmorphism contrast
        Container(color: Colors.black.withValues(alpha: 0.55)),
      ],
    );
  }

  // -------------------------------------------------------------------------
  //  Frosted Glass Login Card
  // -------------------------------------------------------------------------
  Widget _buildLoginCard() {
    final double cardWidth =
        MediaQuery.of(context).size.width > 600 ? 440 : double.infinity;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: cardWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCardHeader(),
                  const SizedBox(height: 32),
                  _buildLoginForm(),
                  const SizedBox(height: 24),
                  _buildLoginButton(),
                  const SizedBox(height: 12),
                  _buildAuthToggle(),
                  const SizedBox(height: 16),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildGoogleButton(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    _buildErrorBanner(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  //  Card Header – University branding with violet accent
  // -------------------------------------------------------------------------
  Widget _buildCardHeader() {
    return Column(
      children: [
        // University logo
        Image.asset(
          'assets/images/Logo.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        const Text(
          'JuCi University',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _kCardText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Faculty Consultation Scheduler',
          style: TextStyle(
            fontSize: 14,
            color: _kSubtleGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  //  Login Form – email & password fields with violet focus ring
  // -------------------------------------------------------------------------
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Display name field (sign-up only)
          if (_isSignUp) ...[
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Juan Dela Cruz',
                prefixIcon:
                    const Icon(Icons.person_outline, color: _kVioletAccent),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: _kVioletAccent, width: 2),
                ),
              ),
              validator: (value) {
                if (_isSignUp && (value == null || value.trim().isEmpty)) {
                  return 'Please enter your name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'faculty@juci.edu',
              prefixIcon:
                  const Icon(Icons.email_outlined, color: _kVioletAccent),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: _kVioletAccent, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address.';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _isSignUp ? _createAccount() : _signInWithEmail(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: '••••••••',
              prefixIcon:
                  const Icon(Icons.lock_outline, color: _kVioletAccent),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _kSubtleGrey,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: _kVioletAccent, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password.';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters.';
              }
              return null;
            },
          ),
          // Confirm password field (sign-up only)
          if (_isSignUp) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _createAccount(),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: '••••••••',
                prefixIcon:
                    const Icon(Icons.lock_outline, color: _kVioletAccent),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: _kVioletAccent, width: 2),
                ),
              ),
              validator: (value) {
                if (_isSignUp) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password.';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  //  Login Button – violet gradient matching reference accent
  // -------------------------------------------------------------------------
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kVioletAccent, _kVioletLight],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _kVioletAccent.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : (_isSignUp ? _createAccount : _signInWithEmail),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isSignUp ? 'Create Account' : 'Login',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  //  Toggle between Login and Sign Up
  // -------------------------------------------------------------------------
  Widget _buildAuthToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account?' : "Don't have an account?",
          style: const TextStyle(color: _kSubtleGrey, fontSize: 13),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isSignUp = !_isSignUp;
              _errorMessage = null;
              _formKey.currentState?.reset();
            });
          },
          child: Text(
            _isSignUp ? 'Login' : 'Sign Up',
            style: const TextStyle(
              color: _kVioletAccent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  //  OR Divider
  // -------------------------------------------------------------------------
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  // -------------------------------------------------------------------------
  //  Google Sign-In Button
  // -------------------------------------------------------------------------
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        icon: _buildGoogleLogo(),
        label: const Text(
          'Sign in with Google',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _kCardText,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  /// Multi-color Google "G" logo placeholder.
  /// For production, swap with an SVG/PNG asset of the official logo.
  Widget _buildGoogleLogo() {
    return const SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  //  Error Banner
  // -------------------------------------------------------------------------
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5C6CB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
