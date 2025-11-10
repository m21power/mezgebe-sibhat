import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wereb/dependency_injection.dart';
import 'package:wereb/features/songs/presentation/bloc/song_bloc.dart';
import 'package:wereb/features/songs/presentation/pages/home_page.dart';
import 'package:wereb/theme/theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/songs/data/local/song_model.dart';
import 'features/songs/data/local/song_model_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await init();
  Hive.registerAdapter(SongModelAdapter());
  await Hive.openBox<SongModel>('songsBox');
  runApp(const MyApp());
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
            ..add(LoadSongsEvent()),
        ),
      ],
      child: BlocBuilder<SongBloc, SongState>(
        builder: (context, state) {
          final isLight = state.isLightTheme; // from your bloc’s state
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'EOTC',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
