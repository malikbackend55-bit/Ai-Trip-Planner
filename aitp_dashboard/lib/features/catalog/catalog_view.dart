import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dashboard_provider.dart';
import '../../core/theme.dart';

class CatalogView extends ConsumerStatefulWidget {
  const CatalogView({super.key});

  @override
  ConsumerState<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends ConsumerState<CatalogView> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();

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

    return FadeTransition(
      opacity: _anim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Trip Catalog', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Package'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchBar(provider),
          const SizedBox(height: 16),
          _buildCatalogTable(provider),
        ],
      ),
    );
  }

  Widget _buildSearchBar(DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => ref.read(dashboardProvider).setCatalogSearchQuery(value),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: AppColors.textDim, size: 20),
                hintText: 'Search catalog packages...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14, color: AppColors.textDim),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildFilterChip('All', provider.catalogFilter == 'All'),
          _buildFilterChip('Featured', provider.catalogFilter == 'Featured'),
          _buildFilterChip('Hidden', provider.catalogFilter == 'Hidden'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textDim)),
        selected: isSelected,
        onSelected: (_) => ref.read(dashboardProvider).setCatalogFilter(label),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildCatalogTable(DashboardProvider provider) {
    final packages = provider.filteredCatalog;

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
          : packages.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: Text('No packages match your filters.', style: TextStyle(color: AppColors.textDim))),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 56,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 64,
                    horizontalMargin: 24,
                    columnSpacing: 20,
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 13),
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

  DataRow _buildPackageRow(dynamic pkg) {
    final destination = pkg['destination'] ?? 'Unknown';
    final budget = '\$${(double.tryParse(pkg['budget']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}';
    final status = ref.read(dashboardProvider).displayTripStatus(pkg);
    final date = pkg['start_date']?.toString().split('T').first ?? 'N/A';

    return DataRow(cells: [
      DataCell(Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: const Text('🏝️', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Text(destination, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      )),
      DataCell(Text(budget, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
      DataCell(_buildStatusBadge(status)),
      DataCell(Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textDim))),
      DataCell(Row(
        children: [
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textDim), onPressed: () {}),
          IconButton(icon: const Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.textDim), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
            onPressed: () async {
              final id = pkg['id'];
              if (id != null) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Package'),
                    content: Text('Are you sure you want to delete "$destination"?'),
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
                  final success = await ref.read(dashboardProvider).deleteTrip(id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Package deleted' : 'Failed to delete package')),
                    );
                  }
                }
              }
            },
          ),
        ],
      )),
    ]);
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
