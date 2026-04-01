import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/trip_provider.dart';
import '../../core/places_service.dart';

class CreateTripForm extends ConsumerStatefulWidget {
  final Map<String, dynamic>? trip;

  const CreateTripForm({super.key, this.trip});

  @override
  ConsumerState<CreateTripForm> createState() => _CreateTripFormState();
}

class _CreateTripFormState extends ConsumerState<CreateTripForm> {
  int _currentStep = 1;
  bool _isGenerating = false;
  String _aiStatus = 'Initializing Gemini AI...';
  
  final PlacesService _placesService = PlacesService();

  // State Data
  final TextEditingController _destinationController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  double _budget = 3500;
  final List<String> _selectedInterests = ['Museums', 'Fine Dining', 'Walking Tours', 'Nature'];
  int _guests = 2;
  String _accommodation = 'Hotel';
  bool get _isEditMode => widget.trip?['id'] != null;

  String _formatBudget(double b) {
    return b.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  void initState() {
    super.initState();
    _hydrateFromTrip();
  }

  void _hydrateFromTrip() {
    final trip = widget.trip;
    if (trip == null) return;

    _destinationController.text = trip['destination']?.toString() ?? '';
    _startDate = _parseTripDate(trip['start_date'], _startDate);
    _endDate = _parseTripDate(trip['end_date'], _endDate);
    _budget = double.tryParse(trip['budget']?.toString() ?? '') ?? _budget;
  }

  DateTime _parseTripDate(dynamic value, DateTime fallback) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed ?? fallback;
  }

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
                onTap: () => context.pop(),
                child: const Icon(Icons.close, color: AppColors.white),
              ),
              const SizedBox(width: 16),
              Text(
                _isEditMode ? 'Edit Trip' : 'Plan Your Trip 🌍',
                style: const TextStyle(fontFamily: 'Fraunces', fontSize: 20, color: AppColors.white, fontWeight: FontWeight.bold),
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
                    color: isDone || isActive ? AppColors.white : AppColors.white.withValues(alpha: 0.3),
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
        _buildLabel('TO (DESTINATION)'),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text == '') {
              return const Iterable<String>.empty();
            }
            return await _placesService.getAutocompleteSuggestions(textEditingValue.text);
          },
          onSelected: (String selection) {
            _destinationController.text = selection;
          },
          fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
            // Keep the controllers synced so user can also just type without picking
            textEditingController.addListener(() {
              _destinationController.text = textEditingController.text;
            });
            // Init text if we navigate back and forth
            if (textEditingController.text != _destinationController.text) {
              textEditingController.text = _destinationController.text;
            }

            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: '🌍 Search destination...',
                filled: true,
                fillColor: AppColors.gray50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                suffixIcon: textEditingController.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => textEditingController.clear()) 
                  : null,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return GestureDetector(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.gray100)),
                          ),
                          child: Text(option, style: const TextStyle(fontSize: 14)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildLabel('POPULAR DESTINATIONS'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(onTap: () => setState(() => _destinationController.text = 'Paris, France'), child: _DestSmall(emoji: '🗼', label: 'Paris', color: Colors.amber)),
              GestureDetector(onTap: () => setState(() => _destinationController.text = 'Bali, Indonesia'), child: _DestSmall(emoji: '🌴', label: 'Bali', color: Colors.teal)),
              GestureDetector(onTap: () => setState(() => _destinationController.text = 'Tokyo, Japan'), child: _DestSmall(emoji: '⛩️', label: 'Tokyo', color: Colors.orange)),
            ],
          ),
        ),
        _buildLabel('GROUP SIZE'),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_guests > 1) setState(() => _guests--);
              },
              child: const _CounterBtn(icon: Icons.remove),
            ),
            Expanded(child: Text('$_guests People 👥', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            GestureDetector(
              onTap: () => setState(() => _guests++),
              child: const _CounterBtn(icon: Icons.add, isPrimary: true),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
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
              _DateInfo(label: 'FROM', date: _formatDate(_startDate), year: _startDate.year.toString()),
              const Text('✈️', style: TextStyle(fontSize: 24)),
              _DateInfo(label: 'TO', date: _formatDate(_endDate), year: _endDate.year.toString()),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 350,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gray200),
          ),
          child: SfDateRangePicker(
            onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
              if (args.value is PickerDateRange) {
                final DateTime? start = args.value.startDate;
                final DateTime? end = args.value.endDate;
                if (start != null && end != null) {
                  setState(() {
                    _startDate = start;
                    _endDate = end;
                  });
                } else if (start != null) { // just picked start
                  setState(() {
                    _startDate = start;
                    _endDate = start; // temp same day
                  });
                }
              }
            },
            selectionMode: DateRangePickerSelectionMode.range,
            initialSelectedRange: PickerDateRange(_startDate, _endDate),
            minDate: DateTime.now(),
            todayHighlightColor: AppColors.g700,
            startRangeSelectionColor: AppColors.g700,
            endRangeSelectionColor: AppColors.g700,
            rangeSelectionColor: AppColors.g200.withValues(alpha: 0.5),
            selectionTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final days = _endDate.difference(_startDate).inDays + 1;
    return ListView(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.g300)),
          child: Column(
            children: [
              Text('\$${_formatBudget(_budget)}', style: const TextStyle(fontFamily: 'Fraunces', fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.g700)),
              Text('Total budget for $_guests people · $days days', style: const TextStyle(fontSize: 11, color: AppColors.g600)),
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
             GestureDetector(onTap: () => setState(() => _accommodation = 'Hotel'), child: _Option(emoji: '🏨', label: 'Hotel', isSelected: _accommodation == 'Hotel')),
             GestureDetector(onTap: () => setState(() => _accommodation = 'Airbnb'), child: _Option(emoji: '🏠', label: 'Airbnb', isSelected: _accommodation == 'Airbnb')),
             GestureDetector(onTap: () => setState(() => _accommodation = 'Hostel'), child: _Option(emoji: '🛏️', label: 'Hostel', isSelected: _accommodation == 'Hostel')),
             GestureDetector(onTap: () => setState(() => _accommodation = 'Resort'), child: _Option(emoji: '🏖️', label: 'Resort', isSelected: _accommodation == 'Resort')),
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
    if (_isEditMode) {
      final trip = widget.trip;
      final tripId = int.tryParse(trip?['id']?.toString() ?? '');

      if (tripId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip ID is missing.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isGenerating = true;
        _aiStatus = 'Saving your trip changes...';
      });

      final trips = ref.read(tripProvider);
      final errorMessage = await trips.updateTrip(tripId, {
        'destination': _destinationController.text.isEmpty ? 'Paris, France' : _destinationController.text,
        'start_date': _startDate.toIso8601String(),
        'end_date': _endDate.toIso8601String(),
        'budget': _budget,
        'status': trip?['status'] ?? 'Upcoming',
      });

      if (!mounted) return;

      if (errorMessage == null) {
        context.go('/home', extra: 2);
      } else {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

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

    final trips = ref.read(tripProvider);
    final errorMessage = await trips.generateTrip({
      'destination': _destinationController.text.isEmpty ? 'Paris, France' : _destinationController.text,
      'start_date': _startDate.toIso8601String(),
      'end_date': _endDate.toIso8601String(),
      'budget': _budget,
      'interests': _selectedInterests,
      'accommodation': _accommodation,
    });

    if (errorMessage == null) {
      if (mounted) {
        context.go('/home', extra: 2);
      }
    } else {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
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
        child: Text(
          _currentStep < 4
              ? 'Next → ${_getStepTitle()}'
              : (_isEditMode ? 'Save Changes' : '✨ Generate My Itinerary'),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray600)));
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
  final String year;
  const _DateInfo({required this.label, required this.date, required this.year});
  @override
  Widget build(BuildContext context) => Column(children: [Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.gray400)), const SizedBox(height: 4), Text(date, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.g800)), Text(year, style: const TextStyle(fontSize: 10, color: AppColors.gray400))]);
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
