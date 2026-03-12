import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/trip_provider.dart';
import '../main_navigation.dart';

class CreateTripForm extends StatefulWidget {
  const CreateTripForm({super.key});

  @override
  State<CreateTripForm> createState() => _CreateTripFormState();
}

class _CreateTripFormState extends State<CreateTripForm> {
  int _currentStep = 1;
  bool _isGenerating = false;
  String _aiStatus = 'Initializing Gemini AI...';

  // State Data
  final TextEditingController _destinationController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  double _budget = 3500;
  List<String> _selectedInterests = ['Museums', 'Fine Dining', 'Walking Tours', 'Nature'];
  int _guests = 2;

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) return _buildAiLoading();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStepContent(),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildAiLoading() {
    return Scaffold(
      backgroundColor: AppColors.g800,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 32),
            Text(
              _aiStatus,
              style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(color: AppColors.g400, backgroundColor: AppColors.g700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
      color: AppColors.g700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.white),
              ),
              const SizedBox(width: 16),
              const Text(
                'Plan Your Trip 🌍',
                style: TextStyle(fontFamily: 'Fraunces', fontSize: 20, color: AppColors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(4, (index) {
              final stepNum = index + 1;
              final isDone = stepNum < _currentStep;
              final isActive = stepNum == _currentStep;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isDone || isActive ? AppColors.white : AppColors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Step $_currentStep of 4 — ${_getStepTitle()}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.g300),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1: return 'Where?';
      case 2: return 'When?';
      case 3: return 'Budget';
      case 4: return 'Interests';
      default: return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      case 4: return _buildStep4();
      default: return Container();
    }
  }

  Widget _buildStep1() {
    return ListView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(20),
      children: [
        _buildLabel('FROM'),
        _buildInput('📍 New York, USA', isFilled: true),
        _buildLabel('TO (DESTINATION)'),
        TextField(
          controller: _destinationController,
          decoration: InputDecoration(
            hintText: '🌍 Search destination...',
            filled: true,
            fillColor: AppColors.gray50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
          ),
        ),
        _buildLabel('POPULAR DESTINATIONS'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _DestSmall(emoji: '🗼', label: 'Paris', color: Colors.amber),
              _DestSmall(emoji: '🌴', label: 'Bali', color: Colors.teal),
              _DestSmall(emoji: '⛩️', label: 'Tokyo', color: Colors.orange),
            ],
          ),
        ),
        _buildLabel('GROUP SIZE'),
        Row(
          children: [
            _CounterBtn(icon: Icons.remove),
            const Expanded(child: Text('2 People 👥', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            _CounterBtn(icon: Icons.add, isPrimary: true),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return ListView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.g200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DateInfo(label: 'FROM', date: 'Jul 1'),
              const Text('✈️', style: TextStyle(fontSize: 24)),
              _DateInfo(label: 'TO', date: 'Jul 10'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('July 2025', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // Mock Calendar Placeholder
        Container(height: 200, color: AppColors.gray50, child: const Center(child: Text('Calendar View'))),
      ],
    );
  }

  Widget _buildStep3() {
    return ListView(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.g300)),
          child: Column(
            children: const [
              Text('\$3,500', style: TextStyle(fontFamily: 'Fraunces', fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.g700)),
              Text('Total budget for 2 people · 9 days', style: TextStyle(fontSize: 11, color: AppColors.g600)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Slider(
          value: _budget, 
          min: 500,
          max: 10000,
          divisions: 19,
          onChanged: (v) {
            setState(() => _budget = v);
          }, 
          activeColor: AppColors.g500, 
          inactiveColor: AppColors.gray200
        ),
        _buildLabel('ACCOMMODATION TYPE'),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: [
             _Option(emoji: '🏨', label: 'Hotel', isSelected: true),
             _Option(emoji: '🏠', label: 'Airbnb'),
             _Option(emoji: '🛏️', label: 'Hostel'),
             _Option(emoji: '🏖️', label: 'Resort'),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return ListView(
      key: const ValueKey(4),
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Select everything you enjoy — Gemini AI will tailor your itinerary!', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
        const SizedBox(height: 16),
        _buildLabel('INTERESTS'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '🏛️ Museums', '🍽️ Fine Dining', '🥾 Hiking', '🚶 Walking Tours', '🌿 Nature', '🛍️ Shopping', '🎨 Art'
          ].map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest);
                  } else {
                    _selectedInterests.add(interest);
                  }
                });
              },
              child: _Interest(label: interest, isOn: isSelected),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _handleGenerate() async {
    setState(() {
      _isGenerating = true;
    });

    final statuses = [
      'Analyzing your interests...',
      'Mapping destinations in ${_destinationController.text}...',
      'Calculating optimal routes...',
      'Polishing your premium itinerary...',
    ];

    for (var status in statuses) {
      if (!mounted) return;
      setState(() => _aiStatus = status);
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final success = await tripProvider.generateTrip({
      'destination': _destinationController.text.isEmpty ? 'Paris, France' : _destinationController.text,
      'start_date': _startDate.toIso8601String(),
      'end_date': _endDate.toIso8601String(),
      'budget': _budget,
      'interests': _selectedInterests,
    });

    if (success) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    } else {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generation failed. Please try again.')),
        );
      }
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.gray100))),
      child: ElevatedButton(
        onPressed: () {
          if (_currentStep < 4) {
            setState(() => _currentStep++);
          } else {
            _handleGenerate();
          }
        },
        child: Text(_currentStep < 4 ? 'Next → ${_getStepTitle()}' : '✨ Generate My Itinerary'),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray600)));
  Widget _buildInput(String text, {bool isFilled = false}) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: isFilled ? AppColors.g50 : AppColors.gray50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isFilled ? AppColors.g400 : AppColors.gray200)), child: Text(text, style: TextStyle(fontSize: 13, color: isFilled ? AppColors.g800 : AppColors.gray400)));
}

class _DestSmall extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  const _DestSmall({required this.emoji, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 90, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gray100)), child: Column(children: [Text(emoji, style: const TextStyle(fontSize: 24)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]));
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final bool isPrimary;
  const _CounterBtn({required this.icon, this.isPrimary = false});
  @override
  Widget build(BuildContext context) => Container(width: 36, height: 36, decoration: BoxDecoration(color: isPrimary ? AppColors.g600 : AppColors.g50, borderRadius: BorderRadius.circular(10), border: isPrimary ? null : Border.all(color: AppColors.g300)), child: Icon(icon, size: 18, color: isPrimary ? Colors.white : AppColors.g700));
}

class _DateInfo extends StatelessWidget {
  final String label;
  final String date;
  const _DateInfo({required this.label, required this.date});
  @override
  Widget build(BuildContext context) => Column(children: [Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.gray400)), const SizedBox(height: 4), Text(date, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.g800)), const Text('2025', style: TextStyle(fontSize: 10, color: AppColors.gray400))]);
}

class _Option extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  const _Option({required this.emoji, required this.label, this.isSelected = false});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isSelected ? AppColors.g50 : AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppColors.g500 : AppColors.gray200)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(emoji, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? AppColors.g700 : AppColors.gray600))]));
}

class _Interest extends StatelessWidget {
  final String label;
  final bool isOn;
  const _Interest({required this.label, this.isOn = false});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isOn ? AppColors.g600 : AppColors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: isOn ? AppColors.g600 : AppColors.gray200)), child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isOn ? Colors.white : AppColors.gray600)));
}
