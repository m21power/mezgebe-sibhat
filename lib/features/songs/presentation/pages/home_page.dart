import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/song_model.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/pages/about_page.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/pages/donation_card.dart';
import 'package:mezgebe_sibhat/theme/theme.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/pages/song_player_page.dart';

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

  void _checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '🎉 Update downloaded! Restart the app to apply it.',
            ),
            action: SnackBarAction(
              label: 'Restart',
              onPressed: () async {
                // Complete the update
                await InAppUpdate.completeFlexibleUpdate();
              },
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final songState = context.watch<SongBloc>().state;
    final isDarkMode = !songState.isLightTheme;

    return Theme(
      data: songState.isLightTheme ? AppThemes.lightTheme : AppThemes.darkTheme,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text("መዝገበ ስብሐት"),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const DonationSheet(),
                  );
                },
              ),
              PopupMenuButton<String>(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                onSelected: (value) {
                  if (value == 'about') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutPage()),
                    );
                  } else if (value == 'theme') {
                    context.read<SongBloc>().add(
                      ChangeThemeEvent(isDarkMode ? 'light' : 'dark'),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'theme',
                    child: ListTile(
                      leading: Icon(
                        isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                      ),
                      title: Text('Theme'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'about',
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('About'),
                    ),
                  ),
                ],
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
      ),
    );
  }

  Widget buildSongItem(SongModel song, {double indent = 0}) {
    final expanded = isExpanded(song);

    if (song.isAudio) {
      return InkWell(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16 + indent),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.music_note, color: Colors.blueAccent, size: 22),
              const SizedBox(width: 10),
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
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final oneOfTheChildrenIsAudio = song.children.any(
              (child) => child.isAudio,
            );

            if (song.listHere && !oneOfTheChildrenIsAudio) {
              toggleExpanded(song);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SongPlayerPage(song: song)),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16 + indent,
            ),
            decoration: BoxDecoration(
              color: expanded
                  ? Colors.amber.withOpacity(0.25)
                  : Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.folder_open : Icons.folder,
                  color: Colors.orange.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    song.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (song.listHere &&
                    !song.children.any((child) => child.isAudio))
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                  ),
              ],
            ),
          ),
        ),

        if (expanded && song.listHere)
          Padding(
            padding: EdgeInsets.only(left: indent + 30, top: 4),
            child: Column(
              children: song.children
                  .map((child) => buildSongItem(child, indent: 0))
                  .toList(),
            ),
          ),

        const SizedBox(height: 4),
      ],
    );
  }
}
