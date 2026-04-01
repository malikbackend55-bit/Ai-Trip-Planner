import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dashboard_provider.dart';
import '../../core/theme.dart';

class TripsView extends ConsumerStatefulWidget {
  const TripsView({super.key});

  @override
  ConsumerState<TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends ConsumerState<TripsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(dashboardProvider);
    
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
            if (provider.isLoading)
              const CircularProgressIndicator(),
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
        _buildFilters(provider),
        const SizedBox(height: 24),
        _buildTripsTable(context, ref, provider),
      ],
    );
  }

  Widget _buildFilters(DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildFilterChip('All Trips', provider.tripFilter == 'All Trips', provider),
          _buildFilterChip('Upcoming', provider.tripFilter == 'Upcoming', provider),
          _buildFilterChip('Completed', provider.tripFilter == 'Completed', provider),
          _buildFilterChip('Cancelled', provider.tripFilter == 'Cancelled', provider),
          const Spacer(),
          SizedBox(
            width: 200,
            child: TextField(
              onChanged: (value) => ref.read(dashboardProvider).setTripSearchQuery(value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textDim),
                hintText: 'Search trips...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 12, color: AppColors.textDim),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, DashboardProvider provider) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textDim)),
        selected: isSelected,
        onSelected: (_) => ref.read(dashboardProvider).setTripFilter(label),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildTripsTable(BuildContext context, WidgetRef ref, DashboardProvider provider) {
    final trips = provider.filteredTrips;
    final emptyMessage = provider.trips.isEmpty
        ? 'No trips exist in the backend yet.'
        : 'No trips match your filters.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: provider.isLoading 
        ? const Padding(
            padding: EdgeInsets.all(64.0),
            child: Center(child: CircularProgressIndicator()),
          )
        : trips.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(48.0),
              child: Center(child: Text(emptyMessage, style: const TextStyle(color: AppColors.textDim))),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
                  DataColumn(label: Text('Budget')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: trips.map((t) => _buildTripRow(context, ref, t)).toList(),
              ),
            ),
    );
  }

  DataRow _buildTripRow(BuildContext context, WidgetRef ref, dynamic trip) {
    final destination = trip['destination'] ?? 'Unknown';
    final budget = '\$${(double.tryParse(trip['budget']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}';
    final status = ref.read(dashboardProvider).displayTripStatus(trip);
    final startDate = trip['start_date']?.toString().split('T').first ?? 'N/A';
    final endDate = trip['end_date']?.toString().split('T').first ?? '';
    final date = endDate.isEmpty ? startDate : '$startDate -> $endDate';

    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            const Text('📍 ', style: TextStyle(fontSize: 16)),
            Text(destination, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        )),
        DataCell(Text(date, style: const TextStyle(fontSize: 13, color: AppColors.textDim))),
        DataCell(Text(budget, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
        DataCell(_buildStatusBadge(status)),
        DataCell(Row(
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textDim), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Trip'),
                    content: Text('Are you sure you want to delete this trip to $destination?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final id = trip['id'];
                  if (id != null) {
                    final success = await ref.read(dashboardProvider).deleteTrip(id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Trip deleted' : 'Failed to delete trip')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Upcoming':
        color = Colors.blue;
        break;
      case 'Completed':
        color = AppColors.success;
        break;
      case 'In Progress':
        color = AppColors.secondary;
        break;
      case 'Scheduled':
        color = Colors.blue;
        break;
      case 'Cancelled':
        color = AppColors.error;
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
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
