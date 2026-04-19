import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_service.dart';
import 'app_localization.dart';
import 'language_provider.dart';

class Destination {
  final String name;
  final String subtitle;
  final String price;
  final String emoji;
  final String rating;
  final Color color;
  final String category;

  Destination({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.emoji,
    required this.rating,
    required this.color,
    required this.category,
  });
}

class ExploreProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Destination> _allDestinations = [];
  String _searchQuery = '';
  String _activeFilter = 'All';
  bool _isLoading = false;

  List<Destination> get destinations {
    var filtered = _allDestinations;
    if (_activeFilter != 'All') {
      filtered = filtered.where((d) => d.category == _activeFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((d) {
        return d.name.toLowerCase().contains(query) ||
            d.subtitle.toLowerCase().contains(query);
      }).toList();
    }
    return filtered;
  }

  String get searchQuery => _searchQuery;
  String get activeFilter => _activeFilter;
  bool get isLoading => _isLoading;

  ExploreProvider() {
    fetchDestinations();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  Future<void> fetchDestinations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getDestinations();
      final data = response.data;
      final topDestinations = data['topDestinations'] as List? ?? [];

      _allDestinations = [
        ...topDestinations.map((item) {
          final destination =
              item['destination']?.toString() ??
              AppStrings.current.tr('common.unknownDestination');
          final count =
              (double.tryParse(item['count']?.toString() ?? '1') ?? 1) * 500;
          return Destination(
            name: destination,
            subtitle: _getSubtitle(destination),
            price: '\$${count.toStringAsFixed(0)}',
            emoji: _getEmoji(destination),
            rating: '4.${(destination.hashCode % 3) + 7}',
            color: _getColor(destination),
            category: _getCategory(destination),
          );
        }),
        ..._getDefaultDestinations(),
      ];

      final seen = <String>{};
      _allDestinations = _allDestinations
          .where((d) => seen.add(d.name.toLowerCase()))
          .toList();
    } catch (error) {
      debugPrint('Error fetching destinations: $error');
      _allDestinations = _getDefaultDestinations();
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Destination> _getDefaultDestinations() {
    return [
      Destination(
        name: 'Paris, France',
        subtitle: AppStrings.current.tr('explore.parisSubtitle'),
        price: '\$2,500',
        emoji: '🗼',
        rating: '4.9',
        color: Colors.amber,
        category: 'City',
      ),
      Destination(
        name: 'Tokyo, Japan',
        subtitle: AppStrings.current.tr('explore.tokyoSubtitle'),
        price: '\$2,800',
        emoji: '⛩️',
        rating: '4.8',
        color: Colors.orange,
        category: 'City',
      ),
      Destination(
        name: 'Bali, Indonesia',
        subtitle: AppStrings.current.tr('explore.baliSubtitle'),
        price: '\$1,100',
        emoji: '🌴',
        rating: '4.7',
        color: Colors.teal,
        category: 'Beach',
      ),
      Destination(
        name: 'New York, USA',
        subtitle: AppStrings.current.tr('explore.newYorkSubtitle'),
        price: '\$3,800',
        emoji: '🗽',
        rating: '4.8',
        color: Colors.blue,
        category: 'City',
      ),
      Destination(
        name: 'Santorini, Greece',
        subtitle: AppStrings.current.tr('explore.santoriniSubtitle'),
        price: '\$2,200',
        emoji: '🏛️',
        rating: '4.9',
        color: Colors.indigo,
        category: 'Beach',
      ),
      Destination(
        name: 'Swiss Alps',
        subtitle: AppStrings.current.tr('explore.swissAlpsSubtitle'),
        price: '\$3,200',
        emoji: '⛰️',
        rating: '4.8',
        color: Colors.green,
        category: 'Nature',
      ),
      Destination(
        name: 'Maldives',
        subtitle: AppStrings.current.tr('explore.maldivesSubtitle'),
        price: '\$4,500',
        emoji: '🏝️',
        rating: '4.9',
        color: Colors.cyan,
        category: 'Luxury',
      ),
      Destination(
        name: 'Marrakech, Morocco',
        subtitle: AppStrings.current.tr('explore.marrakechSubtitle'),
        price: '\$900',
        emoji: '🐪',
        rating: '4.6',
        color: Colors.brown,
        category: 'Budget',
      ),
    ];
  }

  String _getSubtitle(String destination) {
    final lower = destination.toLowerCase();
    if (lower.contains('france') ||
        lower.contains('italy') ||
        lower.contains('spain')) {
      return AppStrings.current.tr('explore.iconicEurope');
    }
    if (lower.contains('japan') ||
        lower.contains('bali') ||
        lower.contains('thailand')) {
      return AppStrings.current.tr('explore.exoticAsia');
    }
    if (lower.contains('usa') ||
        lower.contains('mexico') ||
        lower.contains('brazil')) {
      return AppStrings.current.tr('explore.vibrantAmericas');
    }
    return AppStrings.current.tr('explore.adventureWorld');
  }

  String _getEmoji(String destination) {
    final lower = destination.toLowerCase();
    if (lower.contains('paris')) return '🗼';
    if (lower.contains('tokyo')) return '⛩️';
    if (lower.contains('bali')) return '🌴';
    if (lower.contains('new york')) return '🗽';
    if (lower.contains('london')) return '💂';
    if (lower.contains('rome') || lower.contains('italy')) return '🏛️';
    return '🌏';
  }

  Color _getColor(String destination) {
    final lower = destination.toLowerCase();
    if (lower.contains('paris')) return Colors.amber;
    if (lower.contains('tokyo')) return Colors.orange;
    if (lower.contains('bali')) return Colors.teal;
    if (lower.contains('new york')) return Colors.blue;
    return Colors.green;
  }

  String _getCategory(String destination) {
    final lower = destination.toLowerCase();
    if (lower.contains('bali') ||
        lower.contains('beach') ||
        lower.contains('maldives')) {
      return 'Beach';
    }
    if (lower.contains('alps') ||
        lower.contains('mountain') ||
        lower.contains('forest')) {
      return 'Nature';
    }
    return 'City';
  }
}

final exploreProvider = ChangeNotifierProvider<ExploreProvider>((ref) {
  ref.watch(languageProvider);
  return ExploreProvider();
});
