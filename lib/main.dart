import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mezgebe_sibhat/dependency_injection.dart';
import 'package:mezgebe_sibhat/features/Service/adService.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
import 'package:mezgebe_sibhat/start_up_page.dart';
import 'package:mezgebe_sibhat/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only do things here that are required before the UI can start.
  await init();
  await dotenv.load(fileName: ".env");

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Start the UI immediately.
  runApp(const MyApp());

  // Initialize ads AFTER the first UI frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AdService().init();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Mezgebe Sibhat',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
            home: const StartupPage(),
          );
        },
      ),
    );
  }
}
