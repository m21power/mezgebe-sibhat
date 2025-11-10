import 'package:flutter/material.dart';
import 'package:wereb/features/songs/presentation/pages/home_page.dart';
import 'package:wereb/theme/theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/songs/data/local/song_model.dart';
import 'features/songs/data/local/song_model_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(SongModelAdapter());
  await Hive.openBox<SongModel>('songsBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EOTC',
      theme: AppThemes.darkTheme,
      darkTheme: AppThemes.darkTheme,
      // themeMode: ThemeMode.system, // follows system setting
      home: HomePage(),
    );
  }
}
