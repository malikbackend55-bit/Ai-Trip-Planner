import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_session.dart';
import '../core/dashboard_provider.dart';
import '../core/responsive.dart';
import '../core/theme.dart';

class DashboardLayout extends StatefulWidget {
  final Widget content;
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final String pageTitle;
  final String adminName;
  final String adminRole;

  const DashboardLayout({
    super.key,
    required this.content,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.pageTitle = 'Dashboard Overview',
    this.adminName = 'Admin User',
    this.adminRole = 'Super Admin',
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final isTablet = AppBreakpoints.isTablet(context);
    final contentPadding = EdgeInsets.all(isMobile ? 16 : 24);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              width: 290,
              shape: const RoundedRectangleBorder(),
              child: SafeArea(
                child: _buildSidebarContent(collapsed: false, isDrawer: true),
              ),
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile)
              _buildSidebarShell(
                collapsed: isTablet ? isSidebarCollapsed : false,
              ),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(isMobile: isMobile, isTablet: isTablet),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: contentPadding,
                      child: widget.content,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarShell({required bool collapsed}) {
    final width = collapsed ? 88.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: width,
      child: _buildSidebarContent(collapsed: collapsed, isDrawer: false),
    );
  }

  Widget _buildSidebarContent({
    required bool collapsed,
    required bool isDrawer,
  }) {
    return Container(
      color: AppColors.sidebar,
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogo(collapsed),
          const SizedBox(height: 28),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarItem(
                  0,
                  Icons.dashboard_outlined,
                  'Overview',
                  collapsed,
                  isDrawer,
                ),
                _buildSidebarItem(
                  1,
                  Icons.flight_takeoff_outlined,
                  'Trips',
                  collapsed,
                  isDrawer,
                ),
                _buildSidebarItem(
                  2,
                  Icons.group_outlined,
                  'Users',
                  collapsed,
                  isDrawer,
                ),
                _buildSidebarItem(
                  3,
                  Icons.inventory_2_outlined,
                  'Catalog',
                  collapsed,
                  isDrawer,
                ),
                _buildSidebarItem(
                  4,
                  Icons.query_stats_outlined,
                  'Analytics',
                  collapsed,
                  isDrawer,
                ),
                _buildSidebarItem(
                  5,
                  Icons.settings_outlined,
                  'Settings',
                  collapsed,
                  isDrawer,
                ),
              ],
            ),
          ),
          _buildLogoutButton(collapsed, isDrawer),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLogo(bool collapsed) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 20),
      child: Row(
        mainAxisAlignment: collapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.public, color: Colors.white, size: 24),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 14),
            const Flexible(
              child: Text(
                'AITP Dash',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    int index,
    IconData icon,
    String label,
    bool collapsed,
    bool isDrawer,
  ) {
    final isSelected = widget.selectedIndex == index;

    return InkWell(
      onTap: () {
        if (isDrawer) {
          Navigator.of(context).pop();
        }
        widget.onIndexChanged(index);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(
          vertical: 13,
          horizontal: collapsed ? 0 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: collapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.secondary : Colors.white70,
            ),
            if (!collapsed) ...[
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? AppColors.secondary : Colors.white70,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar({required bool isMobile, required bool isTablet}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (isMobile) {
                    _scaffoldKey.currentState?.openDrawer();
                  } else {
                    setState(() => isSidebarCollapsed = !isSidebarCollapsed);
                  }
                },
                icon: Icon(
                  isMobile
                      ? Icons.menu
                      : (isSidebarCollapsed ? Icons.menu_open : Icons.menu),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.pageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                Flexible(
                  flex: isTablet ? 2 : 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 320 : 360),
                    child: _buildSearchBar(compact: false),
                  ),
                ),
                const SizedBox(width: 18),
              ],
              _buildProfileAvatar(compact: isMobile),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 12),
            _buildSearchBar(compact: true),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar({required bool compact}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 20, color: AppColors.textDim),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search trips, users...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14, color: AppColors.textDim),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar({required bool compact}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.adminName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                widget.adminRole,
                style: const TextStyle(color: AppColors.textDim, fontSize: 11),
              ),
            ],
          ),
        if (!compact) const SizedBox(width: 12),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.admin_panel_settings_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(bool collapsed, bool isDrawer) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final container = ProviderScope.containerOf(
                    context,
                    listen: false,
                  );
                  Navigator.of(ctx).pop();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('auth_token');
                  authSession.markLoggedOut();
                  container.read(dashboardProvider).clearSession();
                  if (mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: EdgeInsets.symmetric(
          vertical: 13,
          horizontal: collapsed ? 0 : 16,
        ),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: collapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            const Icon(Icons.logout_rounded, size: 22, color: Colors.white70),
            if (!collapsed) ...[
              const SizedBox(width: 14),
              const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
