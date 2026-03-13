import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/trip_provider.dart';
import '../../core/theme.dart';
import '../trips/create_trip_form.dart';
import '../itinerary/itinerary_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 1200),
    );
    _controller.forward();
    
    // Fetch real trips on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).fetchTrips();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SingleChildScrollView(
        child: Column(
          children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     _buildAnimatedSection(0.1, _buildQuickActions(context)),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(0.2, _buildSectionHeader('Your Trips', 'See all →')),
                    const SizedBox(height: 12),
                    _buildAnimatedSection(0.3, _buildTripSection(tripProvider)),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(0.4, _buildSectionHeader('Suggested for You', 'More →')),
                    const SizedBox(height: 12),
                    _buildAnimatedSection(0.5, _buildSuggestedDestinations()),
                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),]
            ),
          ),
        );
  }

  Widget _buildAnimatedSection(double delay, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(delay, delay + 0.4, curve: Curves.easeOutQuart),
        ),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: Interval(delay, delay + 0.4, curve: Curves.easeIn),
        ),
        child: child,
      ),
    );
  }

  Widget _buildTripSection(TripProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.g600));
    }
    
    if (provider.trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          children: [
            const Text('⛰️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text(
              'No trips yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Start planning your first adventure!',
              style: TextStyle(color: AppColors.gray400, fontSize: 12),
            ),
             const SizedBox(height: 16),
             TextButton(
               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTripForm())),
               child: const Text('Create Trip'),
             ),
           ],
         ),
       );
    }

    // Just show the first one for now as a "hero" trip
    final trip = provider.trips.first;
    return _TripCard(trip: trip);
  }

  Widget _buildHeader(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?['name'] ?? 'Traveler';

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 18, right: 18, bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.g800, AppColors.g700],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back ✈️',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.g300,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$userName 👋',
            style: GoogleFonts.fraunces(
              fontSize: 24,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Where do you want to go?',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTripForm())),
          child: const _QuickAction(icon: '✈️', label: 'New Trip'),
        ),
        const _QuickAction(icon: '🗺️', label: 'Explore'),
        const _QuickAction(icon: '🤖', label: 'AI Chat'),
        const _QuickAction(icon: '📅', label: 'My Trips'),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.gray800,
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.g600,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedDestinations() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _DestCard(name: 'Tokyo', price: 'from \$2,800', emoji: '🗼', color: Colors.amber),
          _DestCard(name: 'Bali', price: 'from \$1,200', emoji: '🌴', color: Colors.teal),
          _DestCard(name: 'New York', price: 'from \$3,800', emoji: '🗽', color: Colors.blue),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String icon;
  final String label;
  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final dynamic trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final destination = trip['destination'] ?? 'Unknown';
    final budget = double.tryParse(trip['budget']?.toString() ?? '0') ?? 0;
    final status = trip['status'] ?? 'Upcoming';
    final startDate = trip['start_date']?.toString().split('T').first ?? '';

    return Hero(
      tag: 'trip_${trip['id']}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ItineraryView(trip: trip)),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.g700, AppColors.g500],
                    ),
                  ),
                  child: const Stack(
                    children: [
                      Center(child: Text('✈️', style: TextStyle(fontSize: 48))),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📅 $startDate · $status',
                        style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('Estimated Budget', style: TextStyle(fontSize: 10, color: AppColors.gray400)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: 1.0,
                                  backgroundColor: AppColors.gray100,
                                  valueColor: const AlwaysStoppedAnimation(AppColors.g500),
                                  borderRadius: BorderRadius.circular(10),
                                  minHeight: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '\$${budget.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.g700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DestCard extends StatelessWidget {
  final String name;
  final String price;
  final String emoji;
  final Color color;
  const _DestCard({required this.name, required this.price, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 75,
            width: double.infinity,
            color: color.withOpacity(0.2),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                Text(price, style: const TextStyle(fontSize: 10, color: AppColors.g600, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
