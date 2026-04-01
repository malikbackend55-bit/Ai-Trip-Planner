import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dashboard_provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';

class CatalogView extends ConsumerStatefulWidget {
  const CatalogView({super.key});

  @override
  ConsumerState<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends ConsumerState<CatalogView>
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
                'Trip Catalog',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: Text(isMobile ? 'Add' : 'Add Package'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(isMobile ? 130 : 160, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchBar(provider),
          const SizedBox(height: 16),
          _buildCatalogBody(provider, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildSearchBar(DashboardProvider provider) {
    final filters = ['All', 'Featured', 'Hidden'];

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
                ref.read(dashboardProvider).setCatalogSearchQuery(value),
            decoration: const InputDecoration(
              prefixIcon:
                  Icon(Icons.search, color: AppColors.textDim, size: 20),
              hintText: 'Search catalog packages...',
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
            children: filters
                .map(
                  (label) => ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: provider.catalogFilter == label
                            ? Colors.white
                            : AppColors.textDim,
                      ),
                    ),
                    selected: provider.catalogFilter == label,
                    onSelected: (_) =>
                        ref.read(dashboardProvider).setCatalogFilter(label),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: provider.catalogFilter == label
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

  Widget _buildCatalogBody(DashboardProvider provider, {required bool isMobile}) {
    final packages = provider.filteredCatalog;

    if (provider.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(64),
        decoration: _bodyDecoration(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (packages.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: _bodyDecoration(),
        child: const Center(
          child: Text(
            'No packages match your filters.',
            style: TextStyle(color: AppColors.textDim),
          ),
        ),
      );
    }

    if (isMobile) {
      return Column(
        children: packages
            .map(
              (pkg) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CatalogMobileCard(
                  pkg: pkg,
                  status: ref.read(dashboardProvider).displayTripStatus(pkg),
                  onDelete: () => _deletePackage(pkg),
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
            DataColumn(label: Text('Package Name')),
            DataColumn(label: Text('Base Price')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Dates')),
            DataColumn(label: Text('Actions')),
          ],
          rows: packages.map((pkg) => _buildPackageRow(pkg)).toList(),
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

  DataRow _buildPackageRow(dynamic pkg) {
    final destination = pkg['destination'] ?? 'Unknown';
    final budget =
        '\$${(double.tryParse(pkg['budget']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}';
    final status = ref.read(dashboardProvider).displayTripStatus(pkg);
    final date = pkg['start_date']?.toString().split('T').first ?? 'N/A';

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.luggage_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
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
            budget,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(_buildStatusBadge(status)),
        DataCell(
          Text(
            date,
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
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.visibility_off_outlined,
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
                onPressed: () => _deletePackage(pkg),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deletePackage(dynamic pkg) async {
    final destination = pkg['destination'] ?? 'this package';
    final id = pkg['id'];

    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Package'),
        content: Text('Are you sure you want to delete "$destination"?'),
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
      final success = await ref.read(dashboardProvider).deleteTrip(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(success ? 'Package deleted' : 'Failed to delete package'),
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Featured':
        color = AppColors.accent;
        break;
      case 'Active':
      case 'Upcoming':
      case 'Scheduled':
      case 'Completed':
        color = AppColors.success;
        break;
      case 'Hidden':
      case 'Cancelled':
        color = AppColors.textDim;
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

class _CatalogMobileCard extends StatelessWidget {
  final dynamic pkg;
  final String status;
  final VoidCallback onDelete;

  const _CatalogMobileCard({
    required this.pkg,
    required this.status,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final destination = pkg['destination'] ?? 'Unknown';
    final budget =
        '\$${(double.tryParse(pkg['budget']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}';
    final date = pkg['start_date']?.toString().split('T').first ?? 'N/A';

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
              const Icon(Icons.luggage_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CatalogStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Base Price: $budget',
            style: const TextStyle(fontSize: 13, color: AppColors.textMain),
          ),
          const SizedBox(height: 6),
          Text(
            'Start Date: $date',
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
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

class _CatalogStatusBadge extends StatelessWidget {
  final String status;

  const _CatalogStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Upcoming':
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
