import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';

class ItineraryView extends StatefulWidget {
  final Map<String, dynamic> trip;

  const ItineraryView({super.key, required this.trip});

  @override
  State<ItineraryView> createState() => _ItineraryViewState();
}

class _ItineraryViewState extends State<ItineraryView> {
  int _currentTab = 0;

  List<Map<String, dynamic>> get _itineraries => _asMapList(widget.trip['itineraries']);

  List<Map<String, dynamic>> get _activities {
    final items = <Map<String, dynamic>>[];
    for (final day in _itineraries) {
      items.addAll(_asMapList(day['activities']));
    }
    return items;
  }

  double get _budget => double.tryParse(widget.trip['budget']?.toString() ?? '') ?? 0;

  int get _guestCount {
    return int.tryParse(
          widget.trip['guests']?.toString() ??
              widget.trip['travelers']?.toString() ??
              widget.trip['people']?.toString() ??
              '',
        ) ??
        2;
  }

  int get _durationDays {
    final start = DateTime.tryParse(widget.trip['start_date']?.toString() ?? '');
    final end = DateTime.tryParse(widget.trip['end_date']?.toString() ?? '');

    if (start != null && end != null) {
      return math.max(1, end.difference(start).inDays + 1);
    }

    return math.max(1, _itineraries.length);
  }

  String get _destination => (widget.trip['destination'] ?? 'Unknown destination').toString();

  String get _startDateLabel => _formatIsoDate(widget.trip['start_date']);

  String get _endDateLabel => _formatIsoDate(widget.trip['end_date']);

  List<String> get _locations {
    final seen = <String>{};
    final locations = <String>[];

    for (final activity in _activities) {
      final location = _activityLocation(activity);
      if (location == 'Various locations') continue;
      final key = location.toLowerCase();
      if (seen.add(key)) {
        locations.add(location);
      }
    }

    return locations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildTabContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat', extra: widget.trip),
        backgroundColor: AppColors.g600,
        child: const Icon(Icons.smart_toy_rounded),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Hero(
      tag: 'trip_${widget.trip['id']}',
      child: Material(
        color: AppColors.g800,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 56, left: 16, right: 16, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _shareTrip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.g300,
                    ),
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: const Text(
                      'Share',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.g700,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.public, color: AppColors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _destination,
                          style: GoogleFonts.fraunces(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _HeaderMeta(
                              icon: Icons.calendar_month_outlined,
                              text: '$_startDateLabel - $_endDateLabel',
                            ),
                            _HeaderMeta(
                              icon: Icons.group_outlined,
                              text: '$_guestCount people',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildTabs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      ('Overview', 0),
      ('Map', 1),
      ('Budget', 2),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: tabs
            .map(
              (tab) => Expanded(
                child: _TabButton(
                  label: tab.$1,
                  isActive: _currentTab == tab.$2,
                  onTap: () => setState(() => _currentTab = tab.$2),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 1:
        return _buildMapContent();
      case 2:
        return _buildBudgetContent();
      default:
        return _buildOverviewContent();
    }
  }

  Widget _buildOverviewContent() {
    if (_itineraries.isEmpty) {
      return const _CenteredEmptyState(
        icon: Icons.route_outlined,
        title: 'No itinerary yet',
        subtitle: 'Create or regenerate this trip to see the daily plan.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: _itineraries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final day = _itineraries[index];
        final activities = _asMapList(day['activities']);
        final dayLabel = 'Day ${day['day_number'] ?? index + 1}';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.gray100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.g50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      dayLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.g700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formatDayDate(index),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                  Text(
                    '${activities.length} stops',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (activities.isEmpty)
                const _InlineEmptyState(
                  icon: Icons.pending_actions_outlined,
                  title: 'No activities saved for this day',
                  subtitle: 'This day exists, but no itinerary stops were returned.',
                )
              else
                ...activities.map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ActivityCard(
                      title: _activityName(activity),
                      location: _activityLocation(activity),
                      note: _activityNote(activity),
                      slot: (activity['time_slot'] ?? 'Anytime').toString(),
                      icon: _iconForSlot(activity['time_slot']?.toString()),
                      accent: _colorForSlot(activity['time_slot']?.toString()),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapContent() {
    final stops = _locations;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        _SummaryPanel(
          title: 'Trip route',
          subtitle: '$_destination - ${stops.length} saved stops',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Open the destination or any saved stop in your map app.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openMapSearch(_destination),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open destination in maps'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (stops.isEmpty)
          const _CenteredEmptyState(
            icon: Icons.location_off_outlined,
            title: 'No saved map stops',
            subtitle: 'This itinerary does not have activity locations yet.',
          )
        else
          ...stops.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MapStopCard(
                index: entry.key + 1,
                location: entry.value,
                onTap: () => _openMapSearch(entry.value),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBudgetContent() {
    final totalBudget = _budget;
    final dayCount = math.max(1, _durationDays);
    final guestCount = math.max(1, _guestCount);
    final stopCount = math.max(1, _activities.length);

    final perDay = totalBudget / dayCount;
    final perGuest = totalBudget / guestCount;
    final perStop = totalBudget / stopCount;

    final breakdown = <_BudgetSlice>[
      _BudgetSlice('Stay', totalBudget * 0.40, const Color(0xFF166534)),
      _BudgetSlice('Food', totalBudget * 0.25, const Color(0xFF22C55E)),
      _BudgetSlice('Transport', totalBudget * 0.15, const Color(0xFF6EE7B7)),
      _BudgetSlice('Activities', totalBudget * 0.20, const Color(0xFFA7F3D0)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        _SummaryPanel(
          title: 'Budget summary',
          subtitle: totalBudget > 0
              ? 'This estimate is based on the saved trip budget.'
              : 'No budget is saved on this trip yet.',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Total',
                      value: _formatMoney(totalBudget),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'Per day',
                      value: _formatMoney(perDay),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Per person',
                      value: _formatMoney(perGuest),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'Per stop',
                      value: _formatMoney(perStop),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SummaryPanel(
          title: 'Estimated breakdown',
          subtitle: '$dayCount days - $guestCount people - $stopCount itinerary stops',
          child: Column(
            children: [
              for (final slice in breakdown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BudgetBar(
                    label: slice.label,
                    amount: _formatMoney(slice.amount),
                    percent: totalBudget > 0 ? slice.amount / totalBudget : 0,
                    color: slice.color,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _activityName(Map<String, dynamic> activity) {
    return (activity['activity_name'] ?? activity['title'] ?? activity['name'] ?? 'Activity').toString();
  }

  String _activityLocation(Map<String, dynamic> activity) {
    final location = (activity['location'] ?? '').toString().trim();
    return location.isEmpty ? 'Various locations' : location;
  }

  String? _activityNote(Map<String, dynamic> activity) {
    final note = (activity['notes'] ?? activity['note'] ?? '').toString().trim();
    return note.isEmpty ? null : note;
  }

  IconData _iconForSlot(String? slot) {
    switch (slot?.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'afternoon':
        return Icons.light_mode_outlined;
      case 'evening':
        return Icons.nightlight_round;
      default:
        return Icons.place_outlined;
    }
  }

  Color _colorForSlot(String? slot) {
    switch (slot?.toLowerCase()) {
      case 'morning':
        return const Color(0xFFFDE68A);
      case 'afternoon':
        return const Color(0xFFFCD34D);
      case 'evening':
        return const Color(0xFFC4B5FD);
      default:
        return AppColors.gray100;
    }
  }

  String _formatIsoDate(dynamic raw) {
    final value = raw?.toString() ?? '';
    if (value.isEmpty) return 'TBD';

    final date = DateTime.tryParse(value);
    if (date == null) return value.split('T').first;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDayDate(int index) {
    final start = DateTime.tryParse(widget.trip['start_date']?.toString() ?? '');
    if (start == null) return 'Schedule';

    final date = start.add(Duration(days: index));
    return _formatIsoDate(date.toIso8601String());
  }

  String _formatMoney(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '\$$formatted';
  }

  Future<void> _openMapSearch(String query) async {
    if (query.trim().isEmpty) {
      _showSnack('No location is available for this trip.');
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showSnack('Could not open maps.');
    }
  }

  Future<void> _shareTrip() async {
    final buffer = StringBuffer()
      ..writeln('My AI Trip')
      ..writeln('Destination: $_destination')
      ..writeln('Dates: $_startDateLabel - $_endDateLabel')
      ..writeln('Budget: ${_formatMoney(_budget)}')
      ..writeln('Travelers: $_guestCount')
      ..writeln();

    if (_itineraries.isEmpty) {
      buffer.writeln('No itinerary has been generated for this trip yet.');
    } else {
      for (final day in _itineraries) {
        final dayNumber = day['day_number'] ?? '';
        final description = (day['description'] ?? '').toString().trim();

        buffer.writeln(
          'Day $dayNumber${description.isNotEmpty ? ': $description' : ''}',
        );

        for (final activity in _asMapList(day['activities'])) {
          final slot = (activity['time_slot'] ?? 'Anytime').toString();
          buffer.writeln(
            '- $slot: ${_activityName(activity)} @ ${_activityLocation(activity)}',
          );
        }

        buffer.writeln();
      }
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: buffer.toString().trim(),
          subject: 'AITP itinerary for $_destination',
        ),
      );
    } catch (_) {
      if (mounted) {
        _showSnack('Could not open the share sheet.');
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderMeta({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.g300),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.g200,
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isActive ? AppColors.g800 : AppColors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SummaryPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.g700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String location;
  final String? note;
  final String slot;
  final IconData icon;
  final Color accent;

  const _ActivityCard({
    required this.title,
    required this.location,
    required this.note,
    required this.slot,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.gray800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    note!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Text(
              slot,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.g700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStopCard extends StatelessWidget {
  final int index;
  final String location;
  final VoidCallback onTap;

  const _MapStopCard({
    required this.index,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.g50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.g700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              location,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.gray800,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  final String label;
  final String amount;
  final double percent;
  final Color color;

  const _BudgetBar({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percent.clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.gray800,
              ),
            ),
            const Spacer(),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.g700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clampedPercent,
            minHeight: 10,
            backgroundColor: AppColors.gray100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _CenteredEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CenteredEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _InlineEmptyState(
          icon: icon,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InlineEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.gray400),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSlice {
  final String label;
  final double amount;
  final Color color;

  const _BudgetSlice(this.label, this.amount, this.color);
}
