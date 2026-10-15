import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mezgebe Sibhat'**
  String get appTitle;

  /// No description provided for @audioLibrary.
  ///
  /// In en, this message translates to:
  /// **'AUDIO LIBRARY'**
  String get audioLibrary;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @amharic.
  ///
  /// In en, this message translates to:
  /// **'አማርኛ'**
  String get amharic;

  /// No description provided for @updateDownloaded.
  ///
  /// In en, this message translates to:
  /// **'🎉 Update downloaded!'**
  String get updateDownloaded;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @tracks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String tracks(int count);

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String items(int count);

  /// No description provided for @notDownloadedYet.
  ///
  /// In en, this message translates to:
  /// **'This song isn\'t downloaded yet'**
  String get notDownloadedYet;

  /// No description provided for @enableInternet.
  ///
  /// In en, this message translates to:
  /// **'Please enable internet connection'**
  String get enableInternet;

  /// No description provided for @uploadHint.
  ///
  /// In en, this message translates to:
  /// **'For a better experience, upload a photo of the book page you are listening to.'**
  String get uploadHint;

  /// No description provided for @supportMission.
  ///
  /// In en, this message translates to:
  /// **'Support the Mission'**
  String get supportMission;

  /// No description provided for @donationBody.
  ///
  /// In en, this message translates to:
  /// **'Ads help us cover the essential server costs required to keep this app running, but your personal support is deeply appreciated. Together, we keep these teachings easily accessible for all. 🙏'**
  String get donationBody;

  /// No description provided for @globalSupport.
  ///
  /// In en, this message translates to:
  /// **'Global Support 🌍'**
  String get globalSupport;

  /// No description provided for @globalSupportSub.
  ///
  /// In en, this message translates to:
  /// **'USD / EUR / International'**
  String get globalSupportSub;

  /// No description provided for @ethiopia.
  ///
  /// In en, this message translates to:
  /// **'Ethiopia 🇪🇹'**
  String get ethiopia;

  /// No description provided for @ethiopiaSub.
  ///
  /// In en, this message translates to:
  /// **'Telebirr / Local Banking'**
  String get ethiopiaSub;

  /// No description provided for @everyContribution.
  ///
  /// In en, this message translates to:
  /// **'Every contribution matters ❤️'**
  String get everyContribution;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportBug;

  /// No description provided for @describeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue (Optional if image attached)...'**
  String get describeIssue;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send Report 🚀'**
  String get sendReport;

  /// No description provided for @attachScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Attach Screenshot'**
  String get attachScreenshot;

  /// No description provided for @changeScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Change Screenshot'**
  String get changeScreenshot;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent!'**
  String get feedbackSent;

  /// No description provided for @dedication.
  ///
  /// In en, this message translates to:
  /// **'This application is dedicated to every soul who desires to learn the sacred teachings of the Ethiopian Orthodox Tewahedo Church.\n\nAll glory belongs to God Almighty.\n\nSpecial thanks to all who preserved these teachings.\n\n© 2026 Mezgebe Sibhat'**
  String get dedication;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
