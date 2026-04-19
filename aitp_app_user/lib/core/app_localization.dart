import 'package:flutter/material.dart';

enum AppLanguage { english, sorani }

extension AppLanguageX on AppLanguage {
  String get storageValue => switch (this) {
    AppLanguage.english => 'en',
    AppLanguage.sorani => 'ckb',
  };

  bool get isRtl => this == AppLanguage.sorani;

  Locale get locale => switch (this) {
    AppLanguage.english => const Locale('en'),
    AppLanguage.sorani => const Locale('ckb', 'IQ'),
  };
}

class AppStrings {
  AppStrings(this.language);

  final AppLanguage language;

  static AppLanguage _currentLanguage = AppLanguage.sorani;

  static set currentLanguage(AppLanguage language) {
    _currentLanguage = language;
  }

  static AppStrings get current => AppStrings(_currentLanguage);

  bool get isSorani => language == AppLanguage.sorani;

  String get languageCode => isSorani ? 'ckb' : 'en';

  static const Map<AppLanguage, Map<String, String>> _values = {
    AppLanguage.english: {
      'app.title': 'AI Trip Planner',
      'app.tagline': 'Plan smarter. Travel better.',
      'common.email': 'Email Address',
      'common.password': 'Password',
      'common.phone': 'Phone Number',
      'common.fullName': 'Full Name',
      'common.searchDestinations': 'Search destinations...',
      'common.or': 'OR',
      'common.share': 'Share',
      'common.open': 'Open',
      'common.settings': 'Settings',
      'common.language': 'Language',
      'common.english': 'English',
      'common.sorani': 'Kurdish Sorani',
      'common.saveChanges': 'Save Changes',
      'common.upcoming': 'Upcoming',
      'common.past': 'Past',
      'common.completed': 'Completed',
      'common.active': 'Active',
      'common.people': 'people',
      'common.days': 'days',
      'common.from': 'From',
      'common.to': 'To',
      'common.total': 'Total',
      'common.budget': 'Budget',
      'common.trip': 'Trip',
      'common.trips': 'Trips',
      'common.countries': 'Countries',
      'common.logout': 'Logout',
      'common.more': 'More',
      'common.seeAll': 'See all',
      'common.clearFilters': 'Clear filters',
      'common.schedule': 'Schedule',
      'common.tbd': 'TBD',
      'common.unknownDestination': 'Unknown destination',
      'common.activity': 'Activity',
      'common.variousLocations': 'Various locations',
      'common.anytime': 'Anytime',
      'common.fromPrice': 'from {price}',
      'auth.welcomeBack': 'Welcome back',
      'auth.loginSubtitle': 'Login to continue planning your adventures.',
      'auth.forgotPassword': 'Forgot Password?',
      'auth.login': 'Login',
      'auth.continueWithGoogle': 'Continue with Google',
      'auth.noAccount': 'Don\'t have an account?',
      'auth.signUp': 'Sign Up',
      'auth.createAccount': 'Create Account',
      'auth.joinTravelers': 'Join thousands of travelers planning with AI.',
      'auth.alreadyHaveAccount': 'Already have an account?',
      'auth.resetPassword': 'Reset Password',
      'auth.resetSubtitle':
          'Use your email and phone number to set a new password.',
      'auth.newPassword': 'New Password',
      'auth.confirmPassword': 'Confirm Password',
      'auth.fillAllFields': 'Please fill in all fields',
      'auth.passwordMismatch': 'Passwords do not match',
      'auth.passwordResetSuccess':
          'Password reset successful. Log in with your new password.',
      'auth.terms': 'I agree to the Terms of Service and Privacy Policy.',
      'auth.loginFailed': 'Login failed. Please check your credentials.',
      'auth.registrationFailed': 'Registration failed. Please try again.',
      'auth.passwordResetFailed': 'Password reset failed. Please try again.',
      'auth.serverError': 'Server error ({status}). Check backend logs.',
      'auth.cannotReachServer':
          'Cannot reach server at {url}. Check API_URL and backend status.',
      'nav.home': 'Home',
      'nav.explore': 'Explore',
      'nav.myTrips': 'My Trips',
      'nav.aiChat': 'AI Chat',
      'nav.profile': 'Profile',
      'home.yourTrips': 'Your Trips',
      'home.suggestedForYou': 'Suggested for You',
      'home.noTripsYet': 'No trips yet',
      'home.startAdventure': 'Start planning your first adventure!',
      'home.createTrip': 'Create Trip',
      'home.welcomeBackLabel': 'Welcome Back',
      'home.whereToGo': 'Where do you want to go?',
      'home.newTrip': 'New Trip',
      'home.estimatedBudget': 'Estimated Budget',
      'home.traveler': 'Traveler',
      'explore.title': 'Explore',
      'explore.noDestinations': 'No destinations found',
      'explore.searchHint': 'Search destinations...',
      'explore.iconicEurope': 'Iconic · Europe',
      'explore.exoticAsia': 'Exotic · Asia',
      'explore.vibrantAmericas': 'Vibrant · Americas',
      'explore.adventureWorld': 'Adventure · World',
      'explore.parisSubtitle': 'City of Light · Europe',
      'explore.tokyoSubtitle': 'Modern Meets Ancient · Asia',
      'explore.baliSubtitle': 'Island Paradise · Asia',
      'explore.newYorkSubtitle': 'The Big Apple · Americas',
      'explore.santoriniSubtitle': 'Blue Domes · Europe',
      'explore.swissAlpsSubtitle': 'Mountain Majesty · Europe',
      'explore.maldivesSubtitle': 'Tropical Luxury · Asia',
      'explore.marrakechSubtitle': 'Desert Oasis · Africa',
      'filter.all': 'All',
      'filter.beach': 'Beach',
      'filter.city': 'City',
      'filter.nature': 'Nature',
      'filter.budget': 'Budget',
      'filter.luxury': 'Luxury',
      'tripForm.aiInitializing': 'Initializing AI planner...',
      'tripForm.editTrip': 'Edit Trip',
      'tripForm.planYourTrip': 'Plan Your Trip 🌍',
      'tripForm.stepOf': 'Step {current} of {total} — {title}',
      'tripForm.step.where': 'Where?',
      'tripForm.step.when': 'When?',
      'tripForm.step.budget': 'Budget',
      'tripForm.step.interests': 'Interests',
      'tripForm.destinationLabel': 'TO (DESTINATION)',
      'tripForm.destinationHint': '🌍 Search destination...',
      'tripForm.popularDestinations': 'POPULAR DESTINATIONS',
      'tripForm.groupSize': 'GROUP SIZE',
      'tripForm.peopleCount': '{count} people 👥',
      'tripForm.accommodationType': 'ACCOMMODATION TYPE',
      'tripForm.selectInterests':
          'Select everything you enjoy — AI will tailor your itinerary!',
      'tripForm.interests': 'INTERESTS',
      'tripForm.tripIdMissing': 'Trip ID is missing.',
      'tripForm.savingChanges': 'Saving your trip changes...',
      'tripForm.statusAnalyzing': 'Analyzing your interests...',
      'tripForm.statusMapping': 'Mapping destinations in {destination}...',
      'tripForm.statusCalculating': 'Calculating optimal routes...',
      'tripForm.statusPolishing': 'Polishing your premium itinerary...',
      'tripForm.generateItinerary': 'Generate My Itinerary',
      'tripForm.totalBudgetFor':
          'Total budget for {guests} people · {days} days',
      'tripForm.nextStep': 'Next → {title}',
      'tripForm.interest.museums': 'Museums',
      'tripForm.interest.fineDining': 'Fine Dining',
      'tripForm.interest.hiking': 'Hiking',
      'tripForm.interest.walkingTours': 'Walking Tours',
      'tripForm.interest.nature': 'Nature',
      'tripForm.interest.shopping': 'Shopping',
      'tripForm.interest.art': 'Art',
      'tripForm.accommodation.hotel': 'Hotel',
      'tripForm.accommodation.airbnb': 'Airbnb',
      'tripForm.accommodation.hostel': 'Hostel',
      'tripForm.accommodation.resort': 'Resort',
      'myTrips.title': 'My Trips',
      'myTrips.noTripsForFilter': 'No {filter} trips found.',
      'myTrips.view': 'View',
      'myTrips.edit': 'Edit',
      'myTrips.ai': 'AI',
      'myTrips.completed': 'Completed',
      'myTrips.activeProgress': 'Active · {progress}%',
      'profile.notifications': 'Notifications',
      'profile.darkMode': 'Dark Mode',
      'profile.systemTheme': 'Use device theme',
      'profile.privacy': 'Privacy & Security',
      'profile.editProfile': 'Edit Profile',
      'profile.phoneMissing': 'No phone number',
      'profile.updateSuccess': 'Profile updated successfully.',
      'profile.updateFailed': 'Could not update your profile.',
      'profile.systemThemeOn': 'Theme now follows your device settings.',
      'profile.systemThemeOff': 'Theme is fixed to light mode.',
      'profile.notificationStatusOn': 'Daily trip reminders are enabled.',
      'profile.notificationStatusOff': 'Daily trip reminders are disabled.',
      'profile.privacyMessage':
          'Your account data stays on your signed-in device and backend account. Use Forgot Password from login if you need to reset access.',
      'profile.noEmail': 'No email',
      'profile.languageSheetTitle': 'Choose language',
      'profile.languageSheetSubtitle':
          'Apply Sorani across the app and AI responses.',
      'profile.currentLanguage': 'Current',
      'tripReminder.title': 'Trip day reminder: {destination}',
      'tripReminder.body':
          'Day {day} of your trip is ready. Open the app to review today\'s plan.',
      'chat.initialGreeting':
          'Hey! I\'m your AI travel assistant 🌍 Tell me where you\'d like to go and I\'ll plan the perfect trip!',
      'chat.typing': 'AI is typing...',
      'chat.title': 'AITP Assistant',
      'chat.statusReady': 'Online · AI assistant ready',
      'chat.menu.clear': 'New chat',
      'chat.quick.weather': '🌦️ Check weather',
      'chat.quick.weatherPrompt': '🌦️ Check weather for my trip',
      'chat.quick.budget': '💰 Budget tips',
      'chat.quick.budgetPrompt': '💰 How can I travel cheap?',
      'chat.quick.hotels': '🏨 Best hotels',
      'chat.quick.hotelsPrompt': '🏨 Recommend some hotels',
      'chat.quick.dates': '📅 Change dates',
      'chat.quick.datesPrompt': '📅 How do I change my dates?',
      'chat.askHint': 'Ask anything about your trip...',
      'chat.failedResponse': 'Failed to get response',
      'chat.sessionExpired':
          'Your session expired. Please log in again and resend the message.',
      'chat.serverError': 'Server error: {message}',
      'chat.serverStatusError':
          'Server error ({status}) while contacting {url}.',
      'chat.connectionError':
          'Sorry, I am having trouble connecting to {url}. Please try again.',
      'trip.timeout':
          'AI trip generation took too long to respond. The app now waits longer, so retry once.',
      'trip.networkError': 'A network error occurred: {message}',
      'itinerary.overview': 'Overview',
      'itinerary.map': 'Map',
      'itinerary.budgetTab': 'Budget',
      'itinerary.noItinerary': 'No itinerary yet',
      'itinerary.noItinerarySubtitle':
          'Create or regenerate this trip to see the daily plan.',
      'itinerary.day': 'Day {number}',
      'itinerary.stops': '{count} stops',
      'itinerary.noActivities': 'No activities saved for this day',
      'itinerary.noActivitiesSubtitle':
          'This day exists, but no itinerary stops were returned.',
      'itinerary.tripRoute': 'Trip route',
      'itinerary.savedStops': '{destination} - {count} saved stops',
      'itinerary.mapIntro':
          'Open the destination or any saved stop in your map app.',
      'itinerary.openDestinationInMaps': 'Open destination in maps',
      'itinerary.noSavedStops': 'No saved map stops',
      'itinerary.noSavedStopsSubtitle':
          'This itinerary does not have activity locations yet.',
      'itinerary.budgetSummary': 'Budget summary',
      'itinerary.budgetSavedSubtitle':
          'This estimate is based on the saved trip budget.',
      'itinerary.noBudgetSubtitle': 'No budget is saved on this trip yet.',
      'itinerary.estimatedBreakdown': 'Estimated breakdown',
      'itinerary.breakdownSubtitle':
          '{days} days - {people} people - {stops} itinerary stops',
      'itinerary.noLocationForTrip': 'No location is available for this trip.',
      'itinerary.couldNotOpenMaps': 'Could not open maps.',
      'itinerary.shareTitle': 'My AI Trip',
      'itinerary.shareDestination': 'Destination: {destination}',
      'itinerary.shareDates': 'Dates: {start} - {end}',
      'itinerary.shareBudget': 'Budget: {budget}',
      'itinerary.shareTravelers': 'Travelers: {count}',
      'itinerary.shareNoItinerary':
          'No itinerary has been generated for this trip yet.',
      'itinerary.shareDay': 'Day {number}: {description}',
      'itinerary.shareDayWithoutDescription': 'Day {number}',
      'itinerary.shareStop': '- {slot}: {title} @ {location}',
      'itinerary.shareSubject': 'AITP itinerary for {destination}',
      'itinerary.couldNotShare': 'Could not open the share sheet.',
      'itinerary.metricPerDay': 'Per day',
      'itinerary.metricPerPerson': 'Per person',
      'itinerary.metricPerStop': 'Per stop',
      'itinerary.sliceStay': 'Stay',
      'itinerary.sliceFood': 'Food',
      'itinerary.sliceTransport': 'Transport',
      'itinerary.sliceActivities': 'Activities',
      'itinerary.slotMorning': 'Morning',
      'itinerary.slotAfternoon': 'Afternoon',
      'itinerary.slotEvening': 'Evening',
    },
    AppLanguage.sorani: {
      'app.title': 'پلانەری گەشتی AI',
      'app.tagline': 'بە زیرەکی پلانی بدە. باشتر گەشت بکە.',
      'common.email': 'ئیمەیڵ',
      'common.password': 'وشەی نهێنی',
      'common.phone': 'ژمارەی مۆبایل',
      'common.fullName': 'ناوی تەواو',
      'common.searchDestinations': 'بگەڕێ بە شوێنەکان...',
      'common.or': 'یان',
      'common.share': 'هاوبەشکردن',
      'common.open': 'کردنەوە',
      'common.settings': 'ڕێکخستنەکان',
      'common.language': 'زمان',
      'common.english': 'ئینگلیزی',
      'common.sorani': 'کوردی سۆرانی',
      'common.saveChanges': 'گۆڕانکارییەکان پاشەکەوت بکە',
      'common.upcoming': 'داهاتوو',
      'common.past': 'ڕابردوو',
      'common.completed': 'تەواوبوو',
      'common.active': 'چالاک',
      'common.people': 'کەس',
      'common.days': 'ڕۆژ',
      'common.from': 'لە',
      'common.to': 'بۆ',
      'common.total': 'گشتی',
      'common.budget': 'بودجە',
      'common.trip': 'گەشت',
      'common.trips': 'گەشتەکان',
      'common.countries': 'وڵات',
      'common.logout': 'دەرچوون',
      'common.more': 'زیاتر',
      'common.seeAll': 'هەمووی ببینە',
      'common.clearFilters': 'فلتەرەکان بسڕەوە',
      'common.schedule': 'خشتە',
      'common.tbd': 'دیار نەکراوە',
      'common.unknownDestination': 'شوێنی ناناسراو',
      'common.activity': 'چالاکی',
      'common.variousLocations': 'شوێنە جیاوازەکان',
      'common.anytime': 'هەرکات',
      'common.fromPrice': 'لە {price}',
      'auth.welcomeBack': 'بەخێربێیتەوە',
      'auth.loginSubtitle':
          'بچۆ ژوورەوە بۆ بەردەوامبوون لە پلان دانانی گەشتەکانت.',
      'auth.forgotPassword': 'وشەی نهێنیت لەبیرکردووە؟',
      'auth.login': 'چوونەژوورەوە',
      'auth.continueWithGoogle': 'بە Google بەردەوامبە',
      'auth.noAccount': 'هەژمارت نییە؟',
      'auth.signUp': 'هەژمار دروست بکە',
      'auth.createAccount': 'هەژمار دروست بکە',
      'auth.joinTravelers':
          'بەشداری هەزاران گەشتیار بکە کە بە AI پلان دادەنێن.',
      'auth.alreadyHaveAccount': 'پێشتر هەژمارت هەیە؟',
      'auth.resetPassword': 'گۆڕینی وشەی نهێنی',
      'auth.resetSubtitle': 'بە ئیمەیڵ و ژمارەی مۆبایل وشەی نهێنیی نوێ دابنێ.',
      'auth.newPassword': 'وشەی نهێنیی نوێ',
      'auth.confirmPassword': 'دووبارەکردنەوەی وشەی نهێنی',
      'auth.fillAllFields': 'تکایە هەموو خانەکان پڕ بکەوە',
      'auth.passwordMismatch': 'وشە نهێنییەکان یەک ناگرن',
      'auth.passwordResetSuccess':
          'وشەی نهێنی بە سەرکەوتوویی گۆڕدرا. بە وشەی نهێنیی نوێ بچۆ ژوورەوە.',
      'auth.terms':
          'من ڕازیم بە مەرجەکانی بەکارهێنان و سیاسەتی پاراستنی زانیاری.',
      'auth.loginFailed':
          'چوونەژوورەوە سەرکەوتوو نەبوو. تکایە زانیارییەکانت بپشکنە.',
      'auth.registrationFailed':
          'دروستکردنی هەژمار سەرکەوتوو نەبوو. تکایە دووبارە هەوڵ بدەوە.',
      'auth.passwordResetFailed':
          'گۆڕینی وشەی نهێنی سەرکەوتوو نەبوو. تکایە دووبارە هەوڵ بدەوە.',
      'auth.serverError': 'هەڵەی سێرڤەر ({status}). لۆگی باکئێند بپشکنە.',
      'auth.cannotReachServer':
          'ناتوانرێت بگەیت بە سێرڤەری {url}. API_URL و دۆخی باکئێند بپشکنە.',
      'nav.home': 'سەرەکی',
      'nav.explore': 'گەڕان',
      'nav.myTrips': 'گەشتەکانم',
      'nav.aiChat': 'گفتوگۆی AI',
      'nav.profile': 'پرۆفایل',
      'home.yourTrips': 'گەشتەکانت',
      'home.suggestedForYou': 'پێشنیار بۆ تۆ',
      'home.noTripsYet': 'هێشتا هیچ گەشتێکت نییە',
      'home.startAdventure': 'دەست بکە بە پلان دانانی یەکەم سەردانەکەت!',
      'home.createTrip': 'گەشت دروست بکە',
      'home.welcomeBackLabel': 'بەخێربێیتەوە',
      'home.whereToGo': 'دەتەوێت بۆ کوێ بچیت؟',
      'home.newTrip': 'گەشتی نوێ',
      'home.estimatedBudget': 'بودجەی خەمڵێنراو',
      'home.traveler': 'گەشتیار',
      'explore.title': 'گەڕان',
      'explore.noDestinations': 'هیچ شوێنێک نەدۆزرایەوە',
      'explore.searchHint': 'بگەڕێ بە شوێنەکان...',
      'explore.iconicEurope': 'ناسراو · ئەورووپا',
      'explore.exoticAsia': 'سەرسوڕهێنەر · ئاسیا',
      'explore.vibrantAmericas': 'زیندوو · ئەمریکاکان',
      'explore.adventureWorld': 'سەربردە · جیهان',
      'explore.parisSubtitle': 'شاری ڕووناکی · ئەورووپا',
      'explore.tokyoSubtitle': 'مۆدێرن و کۆن · ئاسیا',
      'explore.baliSubtitle': 'بەهەشتی دوورگە · ئاسیا',
      'explore.newYorkSubtitle': 'سیبە گەورەکە · ئەمریکاکان',
      'explore.santoriniSubtitle': 'گنبدە شینەکان · ئەورووپا',
      'explore.swissAlpsSubtitle': 'شکۆی چیا · ئەورووپا',
      'explore.maldivesSubtitle': 'لوکسێی گەرمسێر · ئاسیا',
      'explore.marrakechSubtitle': 'بەهەشتی بیابان · ئەفریقا',
      'filter.all': 'هەموو',
      'filter.beach': 'کەناراو',
      'filter.city': 'شار',
      'filter.nature': 'سروشت',
      'filter.budget': 'ئابووری',
      'filter.luxury': 'لوکس',
      'tripForm.aiInitializing': 'پلاندانی AI ئامادە دەکرێت...',
      'tripForm.editTrip': 'دەستکاریی گەشت',
      'tripForm.planYourTrip': 'گەشتەکەت پلان بکە 🌍',
      'tripForm.stepOf': 'هەنگاوی {current} لە {total} — {title}',
      'tripForm.step.where': 'کوێ؟',
      'tripForm.step.when': 'کەی؟',
      'tripForm.step.budget': 'بودجە',
      'tripForm.step.interests': 'ئارەزووەکان',
      'tripForm.destinationLabel': 'بۆ (شوێن)',
      'tripForm.destinationHint': '🌍 بگەڕێ بە شوێنی گەشت...',
      'tripForm.popularDestinations': 'شوێنە بەناوبانگەکان',
      'tripForm.groupSize': 'ژمارەی گرووپ',
      'tripForm.peopleCount': '{count} کەس 👥',
      'tripForm.accommodationType': 'جۆری نیشتەجێبوون',
      'tripForm.selectInterests':
          'هەر شتێک حەزت لێیە هەڵبژێرە — AI پلانەکەت بۆ تایبەت دەکات!',
      'tripForm.interests': 'ئارەزووەکان',
      'tripForm.tripIdMissing': 'ناسنامەی گەشت ونە.',
      'tripForm.savingChanges': 'گۆڕانکارییەکانی گەشتەکەت پاشەکەوت دەکرێن...',
      'tripForm.statusAnalyzing': 'ئارەزووەکانت شیکاری دەکرێن...',
      'tripForm.statusMapping': 'شوێنەکان لە {destination} دەخشرێنە نەخشە...',
      'tripForm.statusCalculating': 'ڕێگاکانی باشتر هەژمار دەکرێن...',
      'tripForm.statusPolishing': 'پلانە تایبەتەکەت تەواو دەکرێت...',
      'tripForm.generateItinerary': 'پلانەکەم دروست بکە',
      'tripForm.totalBudgetFor': 'بودجەی گشتی بۆ {guests} کەس · {days} ڕۆژ',
      'tripForm.nextStep': 'دواتر → {title}',
      'tripForm.interest.museums': 'مۆزەخانەکان',
      'tripForm.interest.fineDining': 'خواردنی جوان',
      'tripForm.interest.hiking': 'پیاسەی چیا',
      'tripForm.interest.walkingTours': 'گەشتی پیاسە',
      'tripForm.interest.nature': 'سروشت',
      'tripForm.interest.shopping': 'کڕین',
      'tripForm.interest.art': 'هونەر',
      'tripForm.accommodation.hotel': 'هوتێل',
      'tripForm.accommodation.airbnb': 'ئێربینبی',
      'tripForm.accommodation.hostel': 'هۆستێل',
      'tripForm.accommodation.resort': 'ڕیزۆرت',
      'myTrips.title': 'گەشتەکانم',
      'myTrips.noTripsForFilter': 'هیچ گەشتی {filter} نەدۆزرایەوە.',
      'myTrips.view': 'بینین',
      'myTrips.edit': 'دەستکاری',
      'myTrips.ai': 'AI',
      'myTrips.completed': 'تەواوبوو',
      'myTrips.activeProgress': 'چالاک · {progress}%',
      'profile.notifications': 'ئاگادارکردنەوە',
      'profile.darkMode': 'دۆخی تاریک',
      'profile.privacy': 'تایبەتمەندی و ئاسایش',
      'profile.noEmail': 'ئیمەیڵ نییە',
      'profile.languageSheetTitle': 'زمان هەڵبژێرە',
      'profile.languageSheetSubtitle':
          'سۆرانی لە سەرانسەری ئەپ و وەڵامەکانی AI جێبەجێ بکە.',
      'profile.currentLanguage': 'ئێستا',
      'chat.initialGreeting':
          'سڵاو! من یارمەتیدەری گەشتی AI ـتەم 🌍 پێم بڵێ بۆ کوێ دەتەوێت بچیت تا پلانێکی گونجاوت بۆ دابنێم!',
      'chat.typing': 'AI نووسین دەکات...',
      'chat.title': 'یارمەتیدەری AITP',
      'chat.statusReady': 'لەهێڵدایە · یارمەتیدەری AI ئامادەیە',
      'chat.menu.clear': 'گفتوگۆی نوێ',
      'chat.quick.weather': '🌦️ کەشووهەوا',
      'chat.quick.weatherPrompt': '🌦️ کەشووهەوای گەشتەکەم چۆنە؟',
      'chat.quick.budget': '💰 ئامۆژگاری بودجە',
      'chat.quick.budgetPrompt': '💰 چۆن بە هەرزانترین شێوە گەشت بکەم؟',
      'chat.quick.hotels': '🏨 باشترین هوتێلەکان',
      'chat.quick.hotelsPrompt': '🏨 هەندێک هوتێل پێشنیار بکە',
      'chat.quick.dates': '📅 گۆڕینی بەروار',
      'chat.quick.datesPrompt': '📅 چۆن بەروارەکانم بگۆڕم؟',
      'chat.askHint': 'هەر شتێک سەبارەت بە گەشتەکەت بپرسە...',
      'chat.failedResponse': 'وەڵام وەرنەگیرا',
      'chat.sessionExpired':
          'دانیشتنت بەسەرچوو. تکایە دووبارە بچۆ ژوورەوە و نامەکە بنێرەوە.',
      'chat.serverError': 'هەڵەی سێرڤەر: {message}',
      'chat.serverStatusError':
          'هەڵەی سێرڤەر ({status}) لە پەیوەندیدا بە {url}.',
      'chat.connectionError':
          'ببورە، لە پەیوەندیکردن بە {url} کێشەم هەیە. تکایە دووبارە هەوڵ بدەوە.',
      'trip.timeout':
          'دروستکردنی پلانی AI زۆر کات خایاند. ئێستا ئەپ کاتێکی زیاتر چاوەڕێ دەکات، تکایە یەکجار دووبارە هەوڵ بدەوە.',
      'trip.networkError': 'هەڵەی تۆڕ ڕوویدا: {message}',
      'itinerary.overview': 'پوختە',
      'itinerary.map': 'نەخشە',
      'itinerary.budgetTab': 'بودجە',
      'itinerary.noItinerary': 'هێشتا پلانێک نییە',
      'itinerary.noItinerarySubtitle':
          'ئەم گەشتە دروست بکە یان دووبارە دروستی بکە بۆ بینینی پلانی ڕۆژانە.',
      'itinerary.day': 'ڕۆژی {number}',
      'itinerary.stops': '{count} وەستان',
      'itinerary.noActivities': 'بۆ ئەم ڕۆژە هیچ چالاکییەک پاشەکەوت نەکراوە',
      'itinerary.noActivitiesSubtitle':
          'ئەم ڕۆژە هەیە، بەڵام هیچ وەستانێکی پلان بۆ نەگەڕایەوە.',
      'itinerary.tripRoute': 'ڕێگای گەشت',
      'itinerary.savedStops': '{destination} - {count} وەستانی پاشەکەوتکراو',
      'itinerary.mapIntro':
          'شوێنی سەرەکی یان هەر وەستانێکی پاشەکەوتکراو لە ئەپی نەخشەدا بکەرەوە.',
      'itinerary.openDestinationInMaps': 'کردنەوەی شوێن لە نەخشەدا',
      'itinerary.noSavedStops': 'هیچ وەستانێکی نەخشە پاشەکەوت نەکراوە',
      'itinerary.noSavedStopsSubtitle':
          'ئەم پلانە هێشتا شوێنی چالاکییەکانی تێدا نییە.',
      'itinerary.budgetSummary': 'پوختەی بودجە',
      'itinerary.budgetSavedSubtitle':
          'ئەم خەمڵاندنە لەسەر بنەمای بودجەی پاشەکەوتکراوی گەشتە.',
      'itinerary.noBudgetSubtitle':
          'هێشتا هیچ بودجەیەک بۆ ئەم گەشتە پاشەکەوت نەکراوە.',
      'itinerary.estimatedBreakdown': 'دابەشکردنی خەمڵێنراو',
      'itinerary.breakdownSubtitle':
          '{days} ڕۆژ - {people} کەس - {stops} وەستانی پلان',
      'itinerary.noLocationForTrip': 'هیچ شوێنێک بۆ ئەم گەشتە بەردەست نییە.',
      'itinerary.couldNotOpenMaps': 'نەتوانرا نەخشە بکرێتەوە.',
      'itinerary.shareTitle': 'گەشتی AI ـەکەم',
      'itinerary.shareDestination': 'شوێن: {destination}',
      'itinerary.shareDates': 'بەروارەکان: {start} - {end}',
      'itinerary.shareBudget': 'بودجە: {budget}',
      'itinerary.shareTravelers': 'گەشتیاران: {count}',
      'itinerary.shareNoItinerary':
          'هێشتا هیچ پلانێک بۆ ئەم گەشتە دروست نەکراوە.',
      'itinerary.shareDay': 'ڕۆژی {number}: {description}',
      'itinerary.shareDayWithoutDescription': 'ڕۆژی {number}',
      'itinerary.shareStop': '- {slot}: {title} @ {location}',
      'itinerary.shareSubject': 'پلانی AITP بۆ {destination}',
      'itinerary.couldNotShare': 'نەتوانرا پەنجەرەی هاوبەشکردن بکرێتەوە.',
      'itinerary.metricPerDay': 'بۆ هەر ڕۆژ',
      'itinerary.metricPerPerson': 'بۆ هەر کەس',
      'itinerary.metricPerStop': 'بۆ هەر وەستان',
      'itinerary.sliceStay': 'نیشتەجێبوون',
      'itinerary.sliceFood': 'خواردن',
      'itinerary.sliceTransport': 'گواستنەوە',
      'itinerary.sliceActivities': 'چالاکییەکان',
      'itinerary.slotMorning': 'بەیانی',
      'itinerary.slotAfternoon': 'نیوەڕۆ',
      'itinerary.slotEvening': 'ئێوارە',
    },
  };

  String tr(String key, {Map<String, String> params = const {}}) {
    final value =
        _values[language]?[key] ?? _values[AppLanguage.english]?[key] ?? key;
    var resolved = value;
    for (final entry in params.entries) {
      resolved = resolved.replaceAll('{${entry.key}}', entry.value);
    }
    return resolved;
  }

  String monthShort(int month) {
    const en = [
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
    const ku = [
      'کانوو۲',
      'شوبات',
      'ئازار',
      'نیسان',
      'ئایار',
      'حوزەیران',
      'تەمموز',
      'ئاب',
      'ئەیلوول',
      'تشرینی۱',
      'تشرینی۲',
      'کانوو۱',
    ];
    return (isSorani ? ku : en)[month - 1];
  }

  String stepTitle(int step) => switch (step) {
    1 => tr('tripForm.step.where'),
    2 => tr('tripForm.step.when'),
    3 => tr('tripForm.step.budget'),
    4 => tr('tripForm.step.interests'),
    _ => '',
  };

  String filterLabel(String filter) => switch (filter) {
    'Beach' => tr('filter.beach'),
    'City' => tr('filter.city'),
    'Nature' => tr('filter.nature'),
    'Budget' => tr('filter.budget'),
    'Luxury' => tr('filter.luxury'),
    _ => tr('filter.all'),
  };

  String accommodationLabel(String code) => switch (code) {
    'hotel' => tr('tripForm.accommodation.hotel'),
    'airbnb' => tr('tripForm.accommodation.airbnb'),
    'hostel' => tr('tripForm.accommodation.hostel'),
    'resort' => tr('tripForm.accommodation.resort'),
    _ => code,
  };

  String interestLabel(String code) => switch (code) {
    'museums' => tr('tripForm.interest.museums'),
    'fineDining' => tr('tripForm.interest.fineDining'),
    'hiking' => tr('tripForm.interest.hiking'),
    'walkingTours' => tr('tripForm.interest.walkingTours'),
    'nature' => tr('tripForm.interest.nature'),
    'shopping' => tr('tripForm.interest.shopping'),
    'art' => tr('tripForm.interest.art'),
    _ => code,
  };

  String tripStatusLabel(String status) => switch (status.toLowerCase()) {
    'past' => tr('common.past'),
    'completed' => tr('common.completed'),
    'active' => tr('common.active'),
    'upcoming' => tr('common.upcoming'),
    _ => status,
  };

  String slotLabel(String? slot) => switch ((slot ?? '').toLowerCase()) {
    'morning' => tr('itinerary.slotMorning'),
    'afternoon' => tr('itinerary.slotAfternoon'),
    'evening' => tr('itinerary.slotEvening'),
    _ => tr('common.anytime'),
  };

  String languageLabel(AppLanguage value) => switch (value) {
    AppLanguage.english => tr('common.english'),
    AppLanguage.sorani => tr('common.sorani'),
  };
}

class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({
    super.key,
    required this.language,
    required super.child,
  });

  final AppLanguage language;

  AppStrings get strings => AppStrings(language);

  static AppLanguageScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    if (scope == null) {
      throw StateError('AppLanguageScope not found in widget tree.');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) =>
      oldWidget.language != language;
}

extension AppLocalizationContext on BuildContext {
  AppStrings get strings => AppLanguageScope.of(this).strings;

  AppLanguage get appLanguage => AppLanguageScope.of(this).language;

  String tr(String key, {Map<String, String> params = const {}}) =>
      strings.tr(key, params: params);
}
