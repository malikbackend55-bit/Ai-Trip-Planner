import 'package:flutter/material.dart';
import '../../core/theme.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('User Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(160, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildUserStatsRow(),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildUsersTable(),
        ],
      ),
    );
  }

  Widget _buildUserStatsRow() {
    return Row(
      children: [
        _buildMiniStat('Total Users', '8,210', Icons.people, AppColors.primary),
        const SizedBox(width: 16),
        _buildMiniStat('Premium', '1,245', Icons.star, AppColors.accent),
        const SizedBox(width: 16),
        _buildMiniStat('Active Today', '3,120', Icons.trending_up, AppColors.success),
        const SizedBox(width: 16),
        _buildMiniStat('Banned', '47', Icons.block, AppColors.error),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
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
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: AppColors.textDim, size: 20),
                hintText: 'Search users by name or email...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14, color: AppColors.textDim),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildRoleChip('All', true),
          _buildRoleChip('Admin', false),
          _buildRoleChip('Premium', false),
          _buildRoleChip('Standard', false),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textDim)),
        selected: isSelected,
        onSelected: (_) {},
        selectedColor: AppColors.primary,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildUsersTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DataTable(
        headingRowHeight: 56,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 64,
        horizontalMargin: 24,
        columnSpacing: 20,
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 13),
        columns: const [
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Trips')),
          DataColumn(label: Text('Joined')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: List.generate(8, (i) => _buildUserRow(i)),
      ),
    );
  }

  DataRow _buildUserRow(int i) {
    final names = ['Alice Johnson', 'Bob Smith', 'Charlie Brown', 'Diana Prince', 'Evan Wright', 'Fiona Davis', 'George Lee', 'Hannah Kim'];
    final emails = ['alice@mail.com', 'bob@mail.com', 'charlie@mail.com', 'diana@mail.com', 'evan@mail.com', 'fiona@mail.com', 'george@mail.com', 'hannah@mail.com'];
    final roles = ['Admin', 'Premium', 'Standard', 'Premium', 'Standard', 'Admin', 'Standard', 'Premium'];
    final trips = ['24', '18', '7', '32', '3', '15', '9', '21'];
    final statuses = ['Active', 'Active', 'Active', 'Active', 'Inactive', 'Active', 'Banned', 'Active'];

    return DataRow(cells: [
      DataCell(Row(children: [
        CircleAvatar(radius: 14, backgroundColor: AppColors.primary.withValues(alpha: 0.15), child: Text(names[i][0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))),
        const SizedBox(width: 10),
        Text(names[i], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ])),
      DataCell(Text(emails[i], style: const TextStyle(fontSize: 12, color: AppColors.textDim))),
      DataCell(_buildRoleBadge(roles[i])),
      DataCell(Text(trips[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
      DataCell(Text('Jan ${10 + i}, 2024', style: const TextStyle(fontSize: 12, color: AppColors.textDim))),
      DataCell(_buildStatusDot(statuses[i])),
      DataCell(Row(children: [
        IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textDim), onPressed: () {}),
        IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), onPressed: () {}),
      ])),
    ]);
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role) {
      case 'Admin': color = AppColors.error; break;
      case 'Premium': color = AppColors.accent; break;
      default: color = AppColors.textDim;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(role, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusDot(String status) {
    Color color;
    switch (status) {
      case 'Active': color = AppColors.success; break;
      case 'Inactive': color = AppColors.warning; break;
      case 'Banned': color = AppColors.error; break;
      default: color = AppColors.textDim;
    }
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}
