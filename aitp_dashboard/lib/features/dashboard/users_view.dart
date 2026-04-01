import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dashboard_provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';

class UsersView extends ConsumerStatefulWidget {
  const UsersView({super.key});

  @override
  ConsumerState<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends ConsumerState<UsersView>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider).refresh();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(dashboardProvider);
    final isMobile = AppBreakpoints.isMobile(context);

    return FadeTransition(
      opacity: _anim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'User Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateAdminDialog(context, ref),
                icon: const Icon(Icons.person_add, size: 18),
                label: Text(isMobile ? 'Add' : 'Add Admin'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(isMobile ? 120 : 160, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildUserStatsGrid(provider),
          const SizedBox(height: 24),
          _buildSearchBar(provider),
          const SizedBox(height: 16),
          _buildUsersBody(provider, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildUserStatsGrid(DashboardProvider provider) {
    final cards = [
      _MiniStatData('Total Users', provider.users.length.toString(),
          Icons.people, AppColors.primary),
      _MiniStatData('Premium', provider.premiumUserCount.toString(),
          Icons.star_outline, AppColors.accent),
      _MiniStatData('Active', provider.activeUserCount.toString(),
          Icons.trending_up, AppColors.success),
      _MiniStatData('Admins', provider.adminUserCount.toString(),
          Icons.admin_panel_settings_outlined, AppColors.error),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1400
            ? 4
            : width >= AppBreakpoints.mobile
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: width < AppBreakpoints.mobile ? 2.4 : 2.1,
          physics: const NeverScrollableScrollPhysics(),
          children: cards
              .map((item) => _MiniStatCard(data: item))
              .toList(),
        );
      },
    );
  }

  Widget _buildSearchBar(DashboardProvider provider) {
    final roles = ['All', 'Admin', 'Premium', 'User'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) =>
                ref.read(dashboardProvider).setUserSearchQuery(value),
            decoration: const InputDecoration(
              prefixIcon:
                  Icon(Icons.search, color: AppColors.textDim, size: 20),
              hintText: 'Search users by name or email...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: AppColors.border),
              ),
              hintStyle: TextStyle(fontSize: 14, color: AppColors.textDim),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roles
                .map(
                  (label) => ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: provider.userFilter == label
                            ? Colors.white
                            : AppColors.textDim,
                      ),
                    ),
                    selected: provider.userFilter == label,
                    onSelected: (_) =>
                        ref.read(dashboardProvider).setUserFilter(label),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: provider.userFilter == label
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersBody(DashboardProvider provider, {required bool isMobile}) {
    final users = provider.filteredUsers;

    if (provider.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(64),
        decoration: _bodyDecoration(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (users.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: _bodyDecoration(),
        child: const Center(
          child: Text(
            'No users match your filters.',
            style: TextStyle(color: AppColors.textDim),
          ),
        ),
      );
    }

    if (isMobile) {
      return Column(
        children: users
            .map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UserMobileCard(
                  user: user,
                  onEdit: () => _showEditRoleDialog(context, ref, user),
                  onDelete: () => _deleteUser(user),
                ),
              ),
            )
            .toList(),
      );
    }

    return Container(
      width: double.infinity,
      decoration: _bodyDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 56,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          horizontalMargin: 24,
          columnSpacing: 20,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
            fontSize: 13,
          ),
          columns: const [
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Joined')),
            DataColumn(label: Text('Actions')),
          ],
          rows: users.map((user) => _buildUserRow(user)).toList(),
        ),
      ),
    );
  }

  BoxDecoration _bodyDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    );
  }

  DataRow _buildUserRow(dynamic user) {
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? 'No email';
    final role = user['role']?.toString().toUpperCase() ?? 'USER';
    final joined = user['created_at']?.toString().split('T').first ?? 'N/A';

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  name[0],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            email,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
        ),
        DataCell(_buildRoleBadge(role)),
        DataCell(
          Text(
            joined,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textDim,
                ),
                onPressed: () => _showEditRoleDialog(context, ref, user),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
                onPressed: () => _deleteUser(user),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role) {
      case 'ADMIN':
        color = AppColors.error;
        break;
      case 'PREMIUM':
        color = AppColors.accent;
        break;
      default:
        color = AppColors.textDim;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _deleteUser(dynamic user) async {
    final name = user['name'] ?? 'this user';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final id = user['id'];
      if (id != null) {
        final success = await ref.read(dashboardProvider).deleteUser(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'User deleted' : 'Failed to delete user'),
            ),
          );
        }
      }
    }
  }

  void _showCreateAdminDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Admin User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty ||
                  emailCtrl.text.isEmpty ||
                  passCtrl.text.isEmpty) {
                return;
              }

              final navigator = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);

              final success = await ref
                  .read(dashboardProvider)
                  .createAdmin(nameCtrl.text, emailCtrl.text, passCtrl.text);
              if (!mounted) return;

              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Admin created' : 'Failed to create admin',
                  ),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context, WidgetRef ref, dynamic user) {
    final currentRole =
        (user['role']?.toString().toLowerCase() == 'admin') ? 'admin' : 'user';
    var selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Role for ${user['name']}'),
            content: DropdownButtonFormField<String>(
              initialValue: selectedRole,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedRole = value);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(context);

                  final success = await ref
                      .read(dashboardProvider)
                      .updateUserRole(user['id'], selectedRole);
                  if (!mounted) return;

                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'User role updated'
                            : 'Failed to update role',
                      ),
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatData(this.label, this.value, this.icon, this.color);
}

class _MiniStatCard extends StatelessWidget {
  final _MiniStatData data;

  const _MiniStatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textDim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserMobileCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserMobileCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? 'No email';
    final role = user['role']?.toString().toUpperCase() ?? 'USER';
    final joined = user['created_at']?.toString().split('T').first ?? 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  name[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              _CompactRoleBadge(role: role),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Joined: $joined',
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('Edit Role'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactRoleBadge extends StatelessWidget {
  final String role;

  const _CompactRoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'ADMIN':
        color = AppColors.error;
        break;
      case 'PREMIUM':
        color = AppColors.accent;
        break;
      default:
        color = AppColors.textDim;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
