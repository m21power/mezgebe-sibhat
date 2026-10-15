import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mezgebe_sibhat/core/locale_controller.dart';
import 'package:mezgebe_sibhat/dependency_injection.dart';
import 'package:mezgebe_sibhat/features/Service/adService.dart';
import 'package:mezgebe_sibhat/features/Service/app_lifecycle_reactor.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
import 'package:mezgebe_sibhat/l10n/app_localizations.dart';
import 'package:mezgebe_sibhat/start_up_page.dart';
import 'package:mezgebe_sibhat/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await init();
  await dotenv.load(fileName: ".env");
  await LocaleController.instance.load();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyApp());

  // Consent form + AdMob init after the first UI frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AdService().init();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLifecycleReactor _appLifecycleReactor;

  @override
  void initState() {
    super.initState();
    _appLifecycleReactor = AppLifecycleReactor();
    _appLifecycleReactor.start();
  }

  @override
  void dispose() {
    _appLifecycleReactor.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<SongBloc>()
            ..add(GetCurrentThemeEvent())
            ..add(CheckConnection()),
        ),
      ],
      child: BlocBuilder<SongBloc, SongState>(
        builder: (context, state) {
          final isLight = state.isLightTheme;

          return ValueListenableBuilder<Locale>(
            valueListenable: LocaleController.instance.locale,
            builder: (context, locale, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const StartupPage(),
              );
            },
          );
        },
      ),
    );
  }
}
