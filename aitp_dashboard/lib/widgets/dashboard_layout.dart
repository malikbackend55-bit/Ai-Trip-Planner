import 'package:flutter/material.dart';
import '../../core/theme.dart';

class DashboardLayout extends StatefulWidget {
  final Widget content;
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final String pageTitle;

  const DashboardLayout({
    super.key,
    required this.content,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.pageTitle = 'Dashboard Overview',
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  bool isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: widget.content,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSidebarCollapsed ? 80 : 260,
      color: AppColors.sidebar,
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildLogo(),
          const SizedBox(height: 40),
          _buildSidebarItem(0, '📊', 'Overview'),
          _buildSidebarItem(1, '✈️', 'Trips'),
          _buildSidebarItem(2, '👥', 'Users'),
          _buildSidebarItem(3, '📈', 'Analytics'),
          _buildSidebarItem(4, '⚙️', 'Settings'),
          const Spacer(),
          _buildLogoutButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('🌍', style: TextStyle(fontSize: 20)),
        ),
        if (!isSidebarCollapsed) ...[
          const SizedBox(width: 12),
          const Text(
            'AITP Dash',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSidebarItem(int index, String icon, String label) {
    bool isSelected = widget.selectedIndex == index;
    return InkWell(
      onTap: () => widget.onIndexChanged(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            if (!isSidebarCollapsed) ...[
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.secondary : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isSidebarCollapsed ? Icons.menu_open : Icons.menu),
            onPressed: () => setState(() => isSidebarCollapsed = !isSidebarCollapsed),
          ),
          const SizedBox(width: 16),
          Text(
            widget.pageTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          _buildSearchBar(),
          const SizedBox(width: 24),
          _buildProfileAvatar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search, size: 20, color: AppColors.textDim),
          hintText: 'Search trips, users...',
          border: InputBorder.none,
          hintStyle: TextStyle(fontSize: 14, color: AppColors.textDim),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Row(
      children: [
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('Super Admin', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('👨‍💻', style: TextStyle(fontSize: 20))),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Logout'),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            const Text('🚪', style: TextStyle(fontSize: 20)),
            if (!isSidebarCollapsed) ...[
              const SizedBox(width: 16),
              const Text('Logout', style: TextStyle(color: Colors.white70)),
            ],
          ],
        ),
      ),
    );
  }
}
