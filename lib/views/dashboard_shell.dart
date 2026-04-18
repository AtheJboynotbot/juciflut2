import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/booking_provider.dart';
import '../providers/faculty_provider.dart';
import '../services/auth_service.dart';
import '../widgets/glassmorphic_card.dart';
import 'pages/bookings_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/schedule_page.dart';
import 'pages/profile_page.dart';

// ---------------------------------------------------------------------------
// Theme constants matching the JuCi reference design
// ---------------------------------------------------------------------------
const Color kVioletAccent = Color(0xFF7C4DFF);
const Color kVioletLight = Color(0xFFB388FF);
const Color kDarkBg = Color(0xFF1A1A2E);
const Color kTopStripe = Color(0xFF3D5AFE);
const Color kCardText = Color(0xFF2D2D3A);

/// The main dashboard shell with sidebar navigation, top bar, and page content.
/// This is the root widget shown after a successful login.
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final AuthService _authService = AuthService();
  bool _bookingProviderInitialized = false;
  FacultyProvider? _facProv;
  VoidCallback? _onFacultyReady;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _facProv = context.read<FacultyProvider>();
      _facProv!.initForUser(user);
      _onFacultyReady = () {
        if (!mounted) return;
        final fac = _facProv!.faculty;
        if (fac != null && !_bookingProviderInitialized) {
          _bookingProviderInitialized = true;
          context.read<BookingProvider>().initForFaculty(fac.id);
          _facProv!.removeListener(_onFacultyReady!);
          _onFacultyReady = null;
        }
      };
      _facProv!.addListener(_onFacultyReady!);
    });
  }

  @override
  void dispose() {
    if (_onFacultyReady != null) {
      _facProv?.removeListener(_onFacultyReady!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        
        return Scaffold(
          body: Stack(
            children: [
              // Dark background with gradient (simulates building photo overlay)
              _buildBackground(),
              // Blue accent stripe at the very top
              Positioned(
                top: 0, left: 0, right: 0, height: 4,
                child: Container(color: kTopStripe),
              ),
              // Main layout
              Column(
                children: [
                  const SizedBox(height: 4), // space for top stripe
                  _buildTopBar(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ],
          ),
          // Bottom navigation for mobile
          bottomNavigationBar: isMobile ? _buildBottomNav() : null,
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  //  Dark gradient background
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
        Container(color: Colors.black.withValues(alpha: 0.35)),
      ],
    );
  }

  // -------------------------------------------------------------------------
  //  Top Bar – JuCi logo (left), user avatar (right)
  // -------------------------------------------------------------------------
  Widget _buildTopBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        
        return Container(
          height: isMobile ? 56 : 64,
          padding: EdgeInsets.only(left: isMobile ? 12 : 24),
          decoration: BoxDecoration(
            color: const Color(0xFF000080),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Logo + Title
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: isMobile ? 1.5 : 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Logo.png',
                        width: isMobile ? 32 : 40,
                        height: isMobile ? 32 : 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  if (!isMobile || constraints.maxWidth > 400)
                    Text(
                      isMobile ? 'JuCi' : 'JuCi Faculty Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              // Right side: User avatar
              Consumer<FacultyProvider>(
                  builder: (context, prov, _) {
                    // Debug: Check if profile image URL is loaded
                    final imageUrl = prov.faculty?.profileImageUrl ?? '';
                    final hasImage = imageUrl.isNotEmpty;
                    print('🖼️ [TopBar] Profile image URL: ${hasImage ? imageUrl : "EMPTY"}');
                    
                    return GestureDetector(
                      onTap: () => _showUserMenu(context),
                      child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: isMobile ? 1.5 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kVioletAccent.withValues(alpha: 0.3),
                            blurRadius: isMobile ? 4 : 8,
                            spreadRadius: isMobile ? 0 : 1,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: isMobile ? 16 : 20,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        child: hasImage
                            ? ClipOval(
                                child: kIsWeb
                                    ? Image.network(
                                        prov.faculty!.profileImageUrl,
                                        width: isMobile ? 32 : 40,
                                        height: isMobile ? 32 : 40,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          print('❌ [TopBar] Failed to load image: $error');
                                          print('❌ [TopBar] URL was: ${prov.faculty!.profileImageUrl}');
                                          return Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: isMobile ? 18 : 22,
                                          );
                                        },
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: prov.faculty!.profileImageUrl,
                                        width: isMobile ? 32 : 40,
                                        height: isMobile ? 32 : 40,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                        errorWidget: (context, url, error) {
                                          print('❌ [TopBar] Failed to load image: $error');
                                          print('❌ [TopBar] URL was: $url');
                                          return Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: isMobile ? 18 : 22,
                                          );
                                        },
                                      ),
                              )
                            : Icon(
                                Icons.person,
                                color: Colors.white,
                                size: isMobile ? 18 : 22,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  //  Body – Sidebar + Content (Responsive)
  // -------------------------------------------------------------------------
  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final isDesktop = constraints.maxWidth >= 900;
        
        if (isMobile) {
          // Mobile layout: Content only, navigation via bottom bar
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), // Extra bottom padding for bottom nav
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: _buildPageContent(),
            ),
          );
        }
        
        // Tablet and Desktop layout: Sidebar + Content
        final sidebarWidth = isDesktop ? 220.0 : 180.0;
        
        return Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 16,
            isDesktop ? 20 : 12,
            isDesktop ? 32 : 16,
            isDesktop ? 32 : 20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar with minimum width constraint
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 160,
                  maxWidth: sidebarWidth,
                ),
                child: SizedBox(
                  width: sidebarWidth,
                  child: _buildSidebar(),
                ),
              ),
              SizedBox(width: isDesktop ? 24 : 12),
              // Page content
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _buildPageContent(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  //  Sidebar – glassmorphic card with nav items
  // -------------------------------------------------------------------------
  Widget _buildSidebar() {
    return Consumer2<FacultyProvider, BookingProvider>(
      builder: (context, prov, bookProv, _) {
        return GlassmorphicCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', index: 0, selected: prov.selectedNavIndex == 0),
              const SizedBox(height: 8),
              _buildNavItem(icon: Icons.calendar_month_outlined, label: 'My Schedule', index: 1, selected: prov.selectedNavIndex == 1),
              const SizedBox(height: 8),
              _buildNavItem(icon: Icons.book_online_outlined, label: 'Bookings', index: 2, selected: prov.selectedNavIndex == 2, badgeCount: bookProv.pendingCount),
              const SizedBox(height: 8),
              _buildNavItem(icon: Icons.person_outline, label: 'Manage Profile', index: 3, selected: prov.selectedNavIndex == 3),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool selected,
    int badgeCount = 0,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.read<FacultyProvider>().setNavIndex(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? kVioletAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? [
              BoxShadow(
                color: kVioletAccent.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? Colors.white : kCardText.withValues(alpha: 0.7),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 15, minHeight: 15),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : kCardText,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  //  Page content – switches based on selected nav index
  // -------------------------------------------------------------------------
  Widget _buildPageContent() {
    return Consumer<FacultyProvider>(
      builder: (context, prov, _) {
        switch (prov.selectedNavIndex) {
          case 0:
            return const DashboardPage();
          case 1:
            return const SchedulePage();
          case 2:
            return const BookingsPage();
          case 3:
            return const ProfilePage();
          default:
            return const DashboardPage();
        }
      },
    );
  }

  // -------------------------------------------------------------------------
  //  Bottom Navigation (Mobile only)
  // -------------------------------------------------------------------------
  Widget _buildBottomNav() {
    return Consumer2<FacultyProvider, BookingProvider>(
      builder: (context, prov, bookProv, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 65,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    index: 0,
                    isSelected: prov.selectedNavIndex == 0,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.calendar_month_outlined,
                    activeIcon: Icons.calendar_month,
                    label: 'Schedule',
                    index: 1,
                    isSelected: prov.selectedNavIndex == 1,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.book_online_outlined,
                    activeIcon: Icons.book_online,
                    label: 'Bookings',
                    index: 2,
                    isSelected: prov.selectedNavIndex == 2,
                    badgeCount: bookProv.pendingCount,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    index: 3,
                    isSelected: prov.selectedNavIndex == 3,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSelected,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.read<FacultyProvider>().setNavIndex(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    size: 26,
                    color: isSelected ? kVioletAccent : Colors.grey.shade600,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        child: Text(
                          '$badgeCount',
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
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? kVioletAccent : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  //  User menu (logout)
  // -------------------------------------------------------------------------
  void _showUserMenu(BuildContext context) {
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    
    if (overlay == null || button == null) return;
    
    final position = button.localToGlobal(Offset.zero, ancestor: overlay);
    final size = button.size;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        overlay.size.width - position.dx - size.width,
        overlay.size.height - position.dy - size.height,
      ),
      items: [
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign Out'),
            dense: true,
          ),
          onTap: () async {
            // Reset provider to clear all data
            final provider = Provider.of<FacultyProvider>(context, listen: false);
            provider.reset();
            Provider.of<BookingProvider>(context, listen: false).reset();
            
            // Sign out from Firebase
            await _authService.signOut();
            
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
      ],
    );
  }
}
