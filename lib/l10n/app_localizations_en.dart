// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mezgebe Sibhat';

  @override
  String get audioLibrary => 'AUDIO LIBRARY';

  @override
  String get collections => 'Collections';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get aboutApp => 'About App';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get amharic => 'አማርኛ';

  @override
  String get updateDownloaded => '🎉 Update downloaded!';

  @override
  String get restart => 'Restart';

  @override
  String tracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String items(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get notDownloadedYet => 'This song isn\'t downloaded yet';

  @override
  String get enableInternet => 'Please enable internet connection';

  @override
  String get uploadHint =>
      'For a better experience, upload a photo of the book page you are listening to.';

  @override
  String get supportMission => 'Support the Mission';

  @override
  String get donationBody =>
      'Ads help us cover the essential server costs required to keep this app running, but your personal support is deeply appreciated. Together, we keep these teachings easily accessible for all. 🙏';

  @override
  String get globalSupport => 'Global Support 🌍';

  @override
  String get globalSupportSub => 'USD / EUR / International';

  @override
  String get ethiopia => 'Ethiopia 🇪🇹';

  @override
  String get ethiopiaSub => 'Telebirr / Local Banking';

  @override
  String get everyContribution => 'Every contribution matters ❤️';

  @override
  String get reportBug => 'Report a Bug';

  @override
  String get describeIssue =>
      'Describe the issue (Optional if image attached)...';

  @override
  String get sendReport => 'Send Report 🚀';

  @override
  String get attachScreenshot => 'Attach Screenshot';

  @override
  String get changeScreenshot => 'Change Screenshot';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get feedbackSent => 'Feedback sent!';

  @override
  String get dedication =>
      'This application is dedicated to every soul who desires to learn the sacred teachings of the Ethiopian Orthodox Tewahedo Church.\n\nAll glory belongs to God Almighty.\n\nSpecial thanks to all who preserved these teachings.\n\n© 2026 Mezgebe Sibhat';
}
