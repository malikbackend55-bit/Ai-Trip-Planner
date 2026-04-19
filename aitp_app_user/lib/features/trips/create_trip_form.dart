import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../core/app_localization.dart';
import '../../core/places_service.dart';
import '../../core/theme.dart';
import '../../core/trip_provider.dart';

class CreateTripForm extends ConsumerStatefulWidget {
  final Map<String, dynamic>? trip;

  const CreateTripForm({super.key, this.trip});

  @override
  ConsumerState<CreateTripForm> createState() => _CreateTripFormState();
}

class _CreateTripFormState extends ConsumerState<CreateTripForm>
    with TickerProviderStateMixin {
  static const List<String> _interestCodes = [
    'museums',
    'fineDining',
    'hiking',
    'walkingTours',
    'nature',
    'shopping',
    'art',
  ];

  static const List<_AccommodationOption> _accommodations = [
    _AccommodationOption(code: 'hotel', emoji: '🏨'),
    _AccommodationOption(code: 'airbnb', emoji: '🏠'),
    _AccommodationOption(code: 'hostel', emoji: '🛏️'),
    _AccommodationOption(code: 'resort', emoji: '🏖️'),
  ];

  static const List<double> _loadingMilestones = [0.22, 0.46, 0.72, 0.9];
  static const List<IconData> _loadingStageIcons = [
    Icons.search_rounded,
    Icons.travel_explore_rounded,
    Icons.alt_route_rounded,
    Icons.auto_awesome_rounded,
  ];

  int _currentStep = 1;
  bool _isGenerating = false;
  String _aiStatus = '';
  double _loadingProgress = 0.14;
  int _loadingStageIndex = 0;

  final PlacesService _placesService = PlacesService();
  final TextEditingController _destinationController = TextEditingController();
  late final AnimationController _loadingController;

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  double _budget = 3500;
  final List<String> _selectedInterests = [
    'museums',
    'fineDining',
    'walkingTours',
    'nature',
  ];
  int _guests = 2;
  String _accommodation = 'hotel';

  bool get _isEditMode => widget.trip?['id'] != null;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _aiStatus = AppStrings.current.tr('tripForm.aiInitializing');
    _hydrateFromTrip();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  String _formatBudget(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
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
    return DateTime.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String get _resolvedDestination {
    return _destinationController.text.isEmpty
        ? 'Paris, France'
        : _destinationController.text;
  }

  void _startLoading({
    required String status,
    required double progress,
    int stageIndex = 0,
  }) {
    _loadingController
      ..reset()
      ..repeat();

    setState(() {
      _isGenerating = true;
      _aiStatus = status;
      _loadingProgress = progress;
      _loadingStageIndex = stageIndex;
    });
  }

  void _setLoadingStage({
    required String status,
    required double progress,
    required int stageIndex,
  }) {
    setState(() {
      _aiStatus = status;
      _loadingProgress = progress;
      _loadingStageIndex = stageIndex;
    });
  }

  List<_LoadingStage> _loadingStages(BuildContext context) {
    return [
      _LoadingStage(
        status: context.tr('tripForm.statusAnalyzing'),
        progress: _loadingMilestones[0],
      ),
      _LoadingStage(
        status: context.tr(
          'tripForm.statusMapping',
          params: {'destination': _resolvedDestination},
        ),
        progress: _loadingMilestones[1],
      ),
      _LoadingStage(
        status: context.tr('tripForm.statusCalculating'),
        progress: _loadingMilestones[2],
      ),
      _LoadingStage(
        status: context.tr('tripForm.statusPolishing'),
        progress: _loadingMilestones[3],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return _buildAnimatedAiLoading();
    }

    return Scaffold(
      backgroundColor: context.appScaffoldColor,
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

  // ignore: unused_element
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
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                color: AppColors.g400,
                backgroundColor: AppColors.g700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedAiLoading() {
    final heading = _resolvedDestination.split(',').first.trim();

    return Scaffold(
      backgroundColor: AppColors.black,
      body: AnimatedBuilder(
        animation: _loadingController,
        builder: (context, child) {
          final animationValue = _loadingController.value;
          final shimmer = 0.03 * math.sin(animationValue * math.pi * 2).abs();
          final progress = (_loadingProgress + shimmer).clamp(0.08, 0.98);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(
                  -0.9 + (0.2 * math.sin(animationValue * math.pi * 2)),
                  -1.1,
                ),
                end: const Alignment(1, 1),
                colors: const [
                  Color(0xff04140c),
                  AppColors.g900,
                  Color(0xff0f4a2d),
                  AppColors.black,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 70 + (18 * math.sin(animationValue * math.pi * 2)),
                  left: -34,
                  child: _GlowOrb(
                    size: 170,
                    color: AppColors.g500.withValues(alpha: 0.18),
                  ),
                ),
                Positioned(
                  right: -28,
                  bottom: 120 + (14 * math.cos(animationValue * math.pi * 2)),
                  child: _GlowOrb(
                    size: 220,
                    color: const Color(0xff57d6ff).withValues(alpha: 0.12),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.white.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                    color: AppColors.g200,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI Travel Engine',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: AppColors.white.withValues(alpha: 0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withValues(
                                      alpha: 0.28,
                                    ),
                                    blurRadius: 42,
                                    offset: const Offset(0, 22),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _FlightRouteScene(
                                    animationValue: animationValue,
                                    destination: _resolvedDestination,
                                    isRtl: context.appLanguage.isRtl,
                                  ),
                                  const SizedBox(height: 26),
                                  Text(
                                    heading,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          color: AppColors.white,
                                          fontSize: 28,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _aiStatus,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.g100,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    children: List.generate(
                                      _loadingStageIcons.length,
                                      (index) {
                                        final isDone =
                                            index < _loadingStageIndex;
                                        final isCurrent =
                                            index == _loadingStageIndex;

                                        return Expanded(
                                          child: Transform.translate(
                                            offset: Offset(
                                              0,
                                              isCurrent
                                                  ? -4 *
                                                        math.sin(
                                                          animationValue *
                                                              math.pi,
                                                        )
                                                  : 0,
                                            ),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 260,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 11,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDone || isCurrent
                                                    ? AppColors.white
                                                          .withValues(
                                                            alpha: isCurrent
                                                                ? 0.16
                                                                : 0.11,
                                                          )
                                                    : AppColors.white
                                                          .withValues(
                                                            alpha: 0.05,
                                                          ),
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                border: Border.all(
                                                  color: isDone || isCurrent
                                                      ? AppColors.g300
                                                            .withValues(
                                                              alpha: 0.72,
                                                            )
                                                      : AppColors.white
                                                            .withValues(
                                                              alpha: 0.08,
                                                            ),
                                                ),
                                              ),
                                              child: Icon(
                                                _loadingStageIcons[index],
                                                size: isCurrent ? 22 : 19,
                                                color: isDone || isCurrent
                                                    ? AppColors.g100
                                                    : AppColors.g300.withValues(
                                                        alpha: 0.5,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withValues(
                                        alpha: 0.07,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: progress,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColors.g300,
                                                Color(0xff6bf2ff),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.g300
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Text(
                                        '${(progress * 100).round()}%',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _resolvedDestination,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: context.appLanguage.isRtl
                                              ? TextAlign.left
                                              : TextAlign.right,
                                          style: const TextStyle(
                                            color: AppColors.g200,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
                ),
              ],
            ),
          );
        },
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
                _isEditMode
                    ? context.tr('tripForm.editTrip')
                    : context.tr('tripForm.planYourTrip'),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 20,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(4, (index) {
              final stepNumber = index + 1;
              final isDone = stepNumber < _currentStep;
              final isActive = stepNumber == _currentStep;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isDone || isActive
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(
              'tripForm.stepOf',
              params: {
                'current': '$_currentStep',
                'total': '4',
                'title': context.strings.stepTitle(_currentStep),
              },
            ),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.g300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return ListView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(20),
      children: [
        _buildLabel(context.tr('tripForm.destinationLabel')),
        Autocomplete<String>(
          optionsBuilder: (textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _placesService.getAutocompleteSuggestions(
              textEditingValue.text,
            );
          },
          onSelected: (selection) => _destinationController.text = selection,
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
                textEditingController.addListener(() {
                  _destinationController.text = textEditingController.text;
                });
                if (textEditingController.text != _destinationController.text) {
                  textEditingController.text = _destinationController.text;
                }

                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: context.tr('tripForm.destinationHint'),
                    filled: true,
                    fillColor: context.appSurfaceAltColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.appBorderStrongColor,
                      ),
                    ),
                    suffixIcon: textEditingController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => textEditingController.clear(),
                          )
                        : null,
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return GestureDetector(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: context.appBorderColor),
                            ),
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 14),
                          ),
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
        _buildLabel(context.tr('tripForm.popularDestinations')),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(
                  () => _destinationController.text = 'Paris, France',
                ),
                child: const _DestSmall(emoji: '🗼', label: 'Paris'),
              ),
              GestureDetector(
                onTap: () => setState(
                  () => _destinationController.text = 'Bali, Indonesia',
                ),
                child: const _DestSmall(emoji: '🌴', label: 'Bali'),
              ),
              GestureDetector(
                onTap: () => setState(
                  () => _destinationController.text = 'Tokyo, Japan',
                ),
                child: const _DestSmall(emoji: '⛩️', label: 'Tokyo'),
              ),
            ],
          ),
        ),
        _buildLabel(context.tr('tripForm.groupSize')),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_guests > 1) {
                  setState(() => _guests--);
                }
              },
              child: const _CounterBtn(icon: Icons.remove),
            ),
            Expanded(
              child: Text(
                context.tr(
                  'tripForm.peopleCount',
                  params: {'count': '$_guests'},
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
    return '${context.strings.monthShort(date.month)} ${date.day}';
  }

  Widget _buildStep2() {
    return ListView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.g50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.g200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DateInfo(
                label: context.tr('common.from'),
                date: _formatDate(_startDate),
                year: _startDate.year.toString(),
              ),
              const Text('✈️', style: TextStyle(fontSize: 24)),
              _DateInfo(
                label: context.tr('common.to'),
                date: _formatDate(_endDate),
                year: _endDate.year.toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 350,
          decoration: BoxDecoration(
            color: context.appSurfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appBorderStrongColor),
          ),
          child: SfDateRangePicker(
            onSelectionChanged: (args) {
              if (args.value is PickerDateRange) {
                final start = args.value.startDate;
                final end = args.value.endDate;
                if (start != null && end != null) {
                  setState(() {
                    _startDate = start;
                    _endDate = end;
                  });
                } else if (start != null) {
                  setState(() {
                    _startDate = start;
                    _endDate = start;
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
            selectionTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
          decoration: BoxDecoration(
            color: AppColors.g50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.g300),
          ),
          child: Column(
            children: [
              Text(
                '\$${_formatBudget(_budget)}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  color: AppColors.g700,
                ),
              ),
              Text(
                context.tr(
                  'tripForm.totalBudgetFor',
                  params: {'guests': '$_guests', 'days': '$days'},
                ),
                style: const TextStyle(fontSize: 11, color: AppColors.g600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Slider(
          value: _budget,
          min: 500,
          max: 10000,
          divisions: 19,
          onChanged: (value) => setState(() => _budget = value),
          activeColor: AppColors.g500,
          inactiveColor: context.appBorderStrongColor,
        ),
        _buildLabel(context.tr('tripForm.accommodationType')),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: _accommodations.map((option) {
            return GestureDetector(
              onTap: () => setState(() => _accommodation = option.code),
              child: _Option(
                emoji: option.emoji,
                label: context.strings.accommodationLabel(option.code),
                isSelected: _accommodation == option.code,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return ListView(
      key: const ValueKey(4),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          context.tr('tripForm.selectInterests'),
          style: TextStyle(fontSize: 12, color: context.appMutedTextColor),
        ),
        const SizedBox(height: 16),
        _buildLabel(context.tr('tripForm.interests')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interestCodes.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            final label = _interestLabel(context, interest);
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
              child: _Interest(label: label, isOn: isSelected),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _interestLabel(BuildContext context, String code) {
    final emoji = switch (code) {
      'museums' => '🏛️',
      'fineDining' => '🍽️',
      'hiking' => '🥾',
      'walkingTours' => '🚶',
      'nature' => '🌿',
      'shopping' => '🛍️',
      'art' => '🎨',
      _ => '✨',
    };
    return '$emoji ${context.strings.interestLabel(code)}';
  }

  Future<void> _handleGenerate() async {
    if (_isEditMode) {
      final trip = widget.trip;
      final tripId = int.tryParse(trip?['id']?.toString() ?? '');

      if (tripId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('tripForm.tripIdMissing')),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      _startLoading(
        status: context.tr('tripForm.savingChanges'),
        progress: 0.72,
        stageIndex: 2,
      );

      final trips = ref.read(tripProvider);
      final errorMessage = await trips.updateTrip(tripId, {
        'destination': _destinationController.text.isEmpty
            ? 'Paris, France'
            : _destinationController.text,
        'start_date': _startDate.toIso8601String(),
        'end_date': _endDate.toIso8601String(),
        'budget': _budget,
        'status': trip?['status'] ?? 'Upcoming',
      });

      if (!mounted) return;

      if (errorMessage == null) {
        _loadingController.stop();
        context.go('/home', extra: 2);
      } else {
        _loadingController.stop();
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

    final statuses = _loadingStages(context);
    _startLoading(
      status: statuses.first.status,
      progress: statuses.first.progress,
      stageIndex: 0,
    );

    for (var index = 0; index < statuses.length; index++) {
      if (!mounted) return;
      final stage = statuses[index];
      _setLoadingStage(
        status: stage.status,
        progress: stage.progress,
        stageIndex: index,
      );
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    if (!mounted) return;

    final strings = context.strings;
    final trips = ref.read(tripProvider);
    final errorMessage = await trips.generateTrip({
      'destination': _destinationController.text.isEmpty
          ? 'Paris, France'
          : _destinationController.text,
      'start_date': _startDate.toIso8601String(),
      'end_date': _endDate.toIso8601String(),
      'budget': _budget,
      'interests': _selectedInterests
          .map((interest) => strings.interestLabel(interest))
          .toList(),
      'accommodation': _accommodation,
      'language': strings.languageCode,
    });

    if (errorMessage == null) {
      _loadingController.stop();
      if (mounted) {
        context.go('/home', extra: 2);
      }
    } else if (mounted) {
      _loadingController.stop();
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildFooter() {
    final nextStep = (_currentStep + 1).clamp(1, 4);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.appBorderColor)),
      ),
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
              ? context.tr(
                  'tripForm.nextStep',
                  params: {'title': context.strings.stepTitle(nextStep)},
                )
              : (_isEditMode
                    ? context.tr('common.saveChanges')
                    : '✨ ${context.tr('tripForm.generateItinerary')}'),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: context.appSubtextColor,
        ),
      ),
    );
  }
}

class _AccommodationOption {
  final String code;
  final String emoji;

  const _AccommodationOption({required this.code, required this.emoji});
}

class _LoadingStage {
  final String status;
  final double progress;

  const _LoadingStage({required this.status, required this.progress});
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size * 0.8, spreadRadius: 18),
        ],
      ),
    );
  }
}

class _FlightRouteScene extends StatelessWidget {
  static const Size _sceneSize = Size(308, 192);

  final double animationValue;
  final String destination;
  final bool isRtl;

  const _FlightRouteScene({
    required this.animationValue,
    required this.destination,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    final planePosition = _RouteGeometry.pointFor(
      animationValue,
      size: _sceneSize,
      isRtl: isRtl,
    );
    final planeAngle = _RouteGeometry.angleFor(
      animationValue,
      size: _sceneSize,
      isRtl: isRtl,
    );
    final destinationPoint = _RouteGeometry.end(_sceneSize, isRtl);
    final destinationLabel = destination.split(',').first.trim();
    final pinScale = 1 + (0.06 * math.sin(animationValue * math.pi * 2));

    return SizedBox(
      width: _sceneSize.width,
      height: _sceneSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.white.withValues(alpha: 0.1),
                    AppColors.white.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _FlightPathPainter(
                progress: animationValue,
                isRtl: isRtl,
              ),
            ),
          ),
          Positioned(
            left: isRtl ? null : 18,
            right: isRtl ? 18 : null,
            bottom: 16,
            child: const _ScenePill(
              icon: Icons.auto_awesome_rounded,
              label: 'AI',
            ),
          ),
          Positioned(
            left: planePosition.dx - 24,
            top: planePosition.dy - 24,
            child: Transform.rotate(
              angle: planeAngle,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xff7ef7dd), Color(0xff1ed1ff)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff7ef7dd).withValues(alpha: 0.32),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flight_rounded,
                  color: AppColors.g900,
                  size: 26,
                ),
              ),
            ),
          ),
          Positioned(
            left: destinationPoint.dx - 44,
            top: destinationPoint.dy - 42,
            child: Transform.scale(
              scale: pinScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.g300.withValues(alpha: 0.14),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.g100,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: _ScenePill(
                      icon: Icons.place_outlined,
                      label: destinationLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ScenePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.g100),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightPathPainter extends CustomPainter {
  final double progress;
  final bool isRtl;

  const _FlightPathPainter({required this.progress, required this.isRtl});

  @override
  void paint(Canvas canvas, Size size) {
    final start = _RouteGeometry.start(size, isRtl);
    final controlA = _RouteGeometry.controlA(size, isRtl);
    final controlB = _RouteGeometry.controlB(size, isRtl);
    final end = _RouteGeometry.end(size, isRtl);

    final route = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        controlA.dx,
        controlA.dy,
        controlB.dx,
        controlB.dy,
        end.dx,
        end.dy,
      );

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.white.withValues(alpha: 0.08);

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = AppColors.g200.withValues(alpha: 0.7);

    canvas.drawPath(route, shadowPaint);

    final metric = route.computeMetrics().first;
    var distance = 0.0;
    const dashLength = 10.0;
    const gapLength = 8.0;

    while (distance < metric.length) {
      final segment = metric.extractPath(
        distance,
        math.min(distance + dashLength, metric.length).toDouble(),
      );
      canvas.drawPath(segment, dashPaint);
      distance += dashLength + gapLength;
    }

    final trailLength = metric.length * 0.22;
    final trailEnd = metric.length * progress;
    final trailStart = math.max(0.0, trailEnd - trailLength);
    final trailPath = metric.extractPath(trailStart, trailEnd);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xff7ef7dd), Color(0xff1ed1ff)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(trailPath, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _FlightPathPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isRtl != isRtl;
  }
}

class _RouteGeometry {
  static Offset start(Size size, bool isRtl) {
    return Offset(size.width * (isRtl ? 0.82 : 0.16), size.height * 0.72);
  }

  static Offset controlA(Size size, bool isRtl) {
    return Offset(size.width * (isRtl ? 0.67 : 0.32), size.height * 0.18);
  }

  static Offset controlB(Size size, bool isRtl) {
    return Offset(size.width * (isRtl ? 0.34 : 0.63), size.height * 0.94);
  }

  static Offset end(Size size, bool isRtl) {
    return Offset(size.width * (isRtl ? 0.18 : 0.82), size.height * 0.28);
  }

  static Offset pointFor(double t, {required Size size, required bool isRtl}) {
    final p0 = start(size, isRtl);
    final p1 = controlA(size, isRtl);
    final p2 = controlB(size, isRtl);
    final p3 = end(size, isRtl);

    return Offset(
      _cubic(p0.dx, p1.dx, p2.dx, p3.dx, t),
      _cubic(p0.dy, p1.dy, p2.dy, p3.dy, t),
    );
  }

  static double angleFor(double t, {required Size size, required bool isRtl}) {
    final p0 = start(size, isRtl);
    final p1 = controlA(size, isRtl);
    final p2 = controlB(size, isRtl);
    final p3 = end(size, isRtl);

    final dx = _cubicDerivative(p0.dx, p1.dx, p2.dx, p3.dx, t);
    final dy = _cubicDerivative(p0.dy, p1.dy, p2.dy, p3.dy, t);

    return math.atan2(dy, dx);
  }

  static double _cubic(double p0, double p1, double p2, double p3, double t) {
    final mt = 1 - t;
    return (mt * mt * mt * p0) +
        (3 * mt * mt * t * p1) +
        (3 * mt * t * t * p2) +
        (t * t * t * p3);
  }

  static double _cubicDerivative(
    double p0,
    double p1,
    double p2,
    double p3,
    double t,
  ) {
    final mt = 1 - t;
    return (3 * mt * mt * (p1 - p0)) +
        (6 * mt * t * (p2 - p1)) +
        (3 * t * t * (p3 - p2));
  }
}

class _DestSmall extends StatelessWidget {
  final String emoji;
  final String label;

  const _DestSmall({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: context.appTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final bool isPrimary;

  const _CounterBtn({required this.icon, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.g600 : AppColors.g50,
        borderRadius: BorderRadius.circular(10),
        border: isPrimary ? null : Border.all(color: AppColors.g300),
      ),
      child: Icon(
        icon,
        size: 18,
        color: isPrimary ? Colors.white : AppColors.g700,
      ),
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final String date;
  final String year;

  const _DateInfo({
    required this.label,
    required this.date,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: context.appMutedTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.appTextColor,
          ),
        ),
        Text(
          year,
          style: TextStyle(fontSize: 10, color: context.appMutedTextColor),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;

  const _Option({
    required this.emoji,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.g50 : context.appSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.g500 : context.appBorderStrongColor,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.g700 : context.appSubtextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Interest extends StatelessWidget {
  final String label;
  final bool isOn;

  const _Interest({required this.label, this.isOn = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOn ? AppColors.g600 : context.appSurfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isOn ? AppColors.g600 : context.appBorderStrongColor,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isOn ? Colors.white : context.appSubtextColor,
        ),
      ),
    );
  }
}
