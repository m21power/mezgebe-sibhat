import 'package:flutter/material.dart';
import 'package:wereb/features/songs/presentation/pages/song_player_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SongPlayerPage()),
            );
          },
          child: Center(child: const Text('Next')),
        ),
      ),
    );
  }
}
