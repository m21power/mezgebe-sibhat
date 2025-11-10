import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wereb/features/songs/data/local/song_model.dart';
import 'package:wereb/features/songs/presentation/bloc/song_bloc.dart';
import 'package:wereb/theme/theme.dart';
import 'package:wereb/features/songs/presentation/pages/song_player_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? expandedFolderIndex;
  Set<int> expandedFolders = {};

  bool isExpanded(SongModel song) =>
      expandedFolders.contains(song.name.hashCode);

  void toggleExpanded(SongModel song) {
    setState(() {
      if (isExpanded(song)) {
        expandedFolders.remove(song.name.hashCode);
      } else {
        expandedFolders.add(song.name.hashCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final songState = context.watch<SongBloc>().state;
    final isDarkMode = !songState.isLightTheme;

    return Theme(
      data: songState.isLightTheme ? AppThemes.lightTheme : AppThemes.darkTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("EOTC Collection"),
          centerTitle: true,
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          actions: [
            IconButton(
              tooltip: 'About',
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Wereb Player',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.music_note),
                  children: const [
                    Text(
                      'A simple music player app made with Flutter.\n'
                      'Features song playback, folder browsing, and theme switching.',
                    ),
                  ],
                );
              },
            ),
            IconButton(
              tooltip: isDarkMode
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
              icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: () {
                context.read<SongBloc>().add(
                  ChangeThemeEvent(isDarkMode ? 'light' : 'dark'),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<SongBloc, SongState>(
          listener: (context, songState) {
            // TODO: implement listener
          },
          builder: (context, songState) {
            return Center(
              child: Align(
                alignment: Alignment.centerLeft, // start from left
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: songState.songs.length,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 40,
                  ),
                  itemBuilder: (context, index) {
                    final song = songState.songs[index];
                    return buildSongItem(song);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildSongItem(SongModel song, {double indent = 0}) {
    final expanded = isExpanded(song); // unique id

    if (song.isAudio) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SongPlayerPage()),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16 + indent),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_note, color: Colors.blueAccent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  song.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (song.listHere) {
              toggleExpanded(song);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SongPlayerPage()),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 16 + indent,
            ),
            decoration: BoxDecoration(
              color: expanded
                  ? Colors.orange.shade100.withOpacity(0.3)
                  : Colors.orange.shade50.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                expanded
                    ? Image.asset(
                        "assets/folder_icon.png",
                        width: 28,
                        height: 28,
                      )
                    : const Icon(
                        Icons.folder,
                        color: Colors.amberAccent,
                        size: 28,
                      ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    song.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (song.listHere)
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Theme.of(context).iconTheme.color,
                  ),
              ],
            ),
          ),
        ),
        if (expanded && song.listHere)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: song.children
                  .map((child) => buildSongItem(child, indent: indent + 10))
                  .toList(),
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }
}
