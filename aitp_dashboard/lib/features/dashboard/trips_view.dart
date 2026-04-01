import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dashboard_provider.dart';
import '../../core/responsive.dart';
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
    final isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(provider, isMobile: isMobile),
        const SizedBox(height: 24),
        _buildFilters(provider, isMobile: isMobile),
        const SizedBox(height: 24),
        _buildTripsBody(context, ref, provider, isMobile: isMobile),
      ],
    );
  }

  Widget _buildHeader(DashboardProvider provider, {required bool isMobile}) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Trip Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider.isLoading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
            ],
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: Text(isMobile ? 'Add' : 'Add New Trip'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(isMobile ? 120 : 180, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(DashboardProvider provider, {required bool isMobile}) {
    final chipItems = ['All Trips', 'Upcoming', 'Completed', 'Cancelled'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chipItems
                .map(
                  (label) => ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: provider.tripFilter == label
                            ? Colors.white
                            : AppColors.textDim,
                      ),
                    ),
                    selected: provider.tripFilter == label,
                    onSelected: (_) =>
                        ref.read(dashboardProvider).setTripFilter(label),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: provider.tripFilter == label
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (value) =>
                ref.read(dashboardProvider).setTripSearchQuery(value),
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color: AppColors.textDim,
              ),
              hintText: 'Search trips...',
              hintStyle: TextStyle(fontSize: 12, color: AppColors.textDim),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsBody(
    BuildContext context,
    WidgetRef ref,
    DashboardProvider provider, {
    required bool isMobile,
  }) {
    final trips = provider.filteredTrips;
    final emptyMessage = provider.trips.isEmpty
        ? 'No trips exist in the backend yet.'
        : 'No trips match your filters.';

    if (provider.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(64),
        decoration: _tableDecoration(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (trips.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: _tableDecoration(),
        child: Center(
          child: Text(
            emptyMessage,
            style: const TextStyle(color: AppColors.textDim),
          ),
        ),
      );
    }

    if (isMobile) {
      return Column(
        children: trips
            .map(
              (trip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TripMobileCard(
                  trip: trip,
                  status: ref.read(dashboardProvider).displayTripStatus(trip),
                  onDelete: () => _deleteTrip(context, ref, trip),
                ),
              ),
            )
            .toList(),
      );
    }

    return Container(
      width: double.infinity,
      decoration: _tableDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 56,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          horizontalMargin: 24,
          columnSpacing: 24,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
            fontSize: 13,
          ),
          columns: const [
            DataColumn(label: Text('Destination')),
            DataColumn(label: Text('Travel Dates')),
            DataColumn(label: Text('Budget')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: trips.map((trip) => _buildTripRow(context, ref, trip)).toList(),
        ),
      ),
    );
  }

  BoxDecoration _tableDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    );
  }

  DataRow _buildTripRow(BuildContext context, WidgetRef ref, dynamic trip) {
    final destination = trip['destination'] ?? 'Unknown';
    final budget =
        '\$${(double.tryParse(trip['budget']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}';
    final status = ref.read(dashboardProvider).displayTripStatus(trip);
    final startDate = trip['start_date']?.toString().split('T').first ?? 'N/A';
    final endDate = trip['end_date']?.toString().split('T').first ?? '';
    final date = endDate.isEmpty ? startDate : '$startDate -> $endDate';

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                destination,
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
            date,
            style: const TextStyle(fontSize: 13, color: AppColors.textDim),
          ),
        ),
        DataCell(
          Text(
            budget,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(_buildStatusBadge(status)),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textDim,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
                onPressed: () => _deleteTrip(context, ref, trip),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteTrip(
    BuildContext context,
    WidgetRef ref,
    dynamic trip,
  ) async {
    final destination = trip['destination'] ?? 'this trip';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Are you sure you want to delete $destination?'),
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
      final id = trip['id'];
      if (id != null) {
        final success = await ref.read(dashboardProvider).deleteTrip(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Trip deleted' : 'Failed to delete trip'),
            ),
          );
        }
      }
    }
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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TripMobileCard extends StatelessWidget {
  final dynamic trip;
  final String status;
  final VoidCallback onDelete;

  const _TripMobileCard({
    required this.trip,
    required this.status,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final destination = trip['destination'] ?? 'Unknown';
    final budget =
        '\$${(double.tryParse(trip['budget']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}';
    final startDate = trip['start_date']?.toString().split('T').first ?? 'N/A';
    final endDate = trip['end_date']?.toString().split('T').first ?? '';
    final date = endDate.isEmpty ? startDate : '$startDate -> $endDate';

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
              const Icon(Icons.place_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          _MetaLine(label: 'Dates', value: date),
          const SizedBox(height: 8),
          _MetaLine(label: 'Budget', value: budget),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Edit'),
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

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetaLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMain,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Upcoming':
        color = Colors.blue;
        break;
      case 'Completed':
        color = AppColors.success;
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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
