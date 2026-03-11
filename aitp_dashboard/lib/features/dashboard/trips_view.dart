import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TripsView extends StatelessWidget {
  const TripsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trip Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New Trip'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildFilters(),
        const SizedBox(height: 24),
        _buildTripsTable(),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildFilterChip('All Trips', true),
          _buildFilterChip('Upcoming', false),
          _buildFilterChip('Completed', false),
          _buildFilterChip('Cancelled', false),
          const Spacer(),
          const Text('Show:', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: '10',
            underline: const SizedBox(),
            items: ['10', '20', '50'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 12)));
            }).toList(),
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
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

  Widget _buildTripsTable() {
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
        columnSpacing: 24,
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 13),
        columns: const [
          DataColumn(label: Text('Destination')),
          DataColumn(label: Text('Travel Dates')),
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Budget')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: List.generate(8, (index) => _buildTripRow(index)),
      ),
    );
  }

  DataRow _buildTripRow(int index) {
    final destinations = ['Paris, France', 'Tokyo, Japan', 'New York, USA', 'Bali, Indonesia', 'London, UK'];
    final users = ['Alice Johnson', 'Bob Smith', 'Charlie Brown', 'Diana Prince', 'Evan Wright'];
    final statuses = ['Scheduled', 'Completed', 'In Progress', 'Scheduled', 'Cancelled'];
    
    final destination = destinations[index % destinations.length];
    final user = users[index % users.length];
    final status = statuses[index % statuses.length];

    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            const Text('📍 ', style: TextStyle(fontSize: 16)),
            Text(destination, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        )),
        DataCell(const Text('Jul 12 – Jul 20, 2025', style: TextStyle(fontSize: 13, color: AppColors.textDim))),
        DataCell(Row(
          children: [
            CircleAvatar(radius: 12, backgroundColor: AppColors.background, child: const Text('👤', style: TextStyle(fontSize: 10))),
            const SizedBox(width: 8),
            Text(user, style: const TextStyle(fontSize: 13)),
          ],
        )),
        DataCell(const Text('\$3,500', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
        DataCell(_buildStatusBadge(status)),
        DataCell(Row(
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textDim), onPressed: () {}),
            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), onPressed: () {}),
          ],
        )),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Completed': color = AppColors.success; break;
      case 'In Progress': color = AppColors.secondary; break;
      case 'Scheduled': color = Colors.blue; break;
      case 'Cancelled': color = AppColors.error; break;
      default: color = AppColors.textDim;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
