import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wereb/features/songs/data/local/song_model.dart';
import 'package:wereb/features/songs/domain/entities/SongModel.dart';
import 'package:wereb/features/songs/presentation/bloc/song_bloc.dart';
import 'package:wereb/features/songs/presentation/widgets/pick_image.dart';

class SongPlayerPage extends StatefulWidget {
  final SongModel song;
  const SongPlayerPage({super.key, required this.song});

  @override
  State<SongPlayerPage> createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage> {
  double progress = 0.2;
  double playbackSpeed = 1.0; // add this as a state variable
  SongModel? songModel;
  int currentIndex = 0;
  double downloadProgress = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    songModel = widget.song;
  }

  bool isLoading = false;

  final selectedImage = {};
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: SafeArea(
        child: BlocConsumer<SongBloc, SongState>(
          listener: (context, songState) {
            if (songState is AudioDownloadingFetchingState) {
              print("testing.>>>>>>>>>>>>>>>>");
              print(songState.progress);
              setState(() {
                isLoading = false;
                downloadProgress = songState.progress;
              });
            }
            if (songState is AudioDownloadSuccessfully) {
              setState(() {
                setState(() {
                  songModel = songState.songModel;
                });
              });
            }
            if (songState is AudioDownloadFailed) {}
          },
          builder: (context, songState) {
            return Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: theme.iconTheme.color,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            songModel!.name,
                            style: textTheme.titleLarge,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Album Art Scrollable
                imageWidget(theme, songModel!.name, songState, context),
                const SizedBox(height: 20),
                // Song Info
                Text(
                  songModel!.children[currentIndex].name,
                  style: textTheme.displayMedium,
                ),
                const SizedBox(height: 5),

                // Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Slider(
                              value: progress,
                              onChanged: (value) =>
                                  setState(() => progress = value),
                              activeColor: theme.primaryColor,
                              inactiveColor: theme.primaryColor.withOpacity(
                                0.4,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ), // small gap between slider and dropdown
                          DropdownButton<double>(
                            value: playbackSpeed,
                            dropdownColor: theme.scaffoldBackgroundColor,
                            iconEnabledColor: theme.iconTheme.color,
                            items: const [
                              DropdownMenuItem(value: 0.5, child: Text("0.5x")),
                              DropdownMenuItem(value: 1.0, child: Text("1x")),
                              DropdownMenuItem(value: 1.5, child: Text("1.5x")),
                              DropdownMenuItem(value: 2.0, child: Text("2x")),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  playbackSpeed = value;
                                  // TODO: update your audio player speed here
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("0:50", style: textTheme.titleMedium),
                          Text("4:00", style: textTheme.titleMedium),
                        ],
                      ),
                    ],
                  ),
                ),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          currentIndex =
                              (currentIndex - 1 + songModel!.children.length) %
                              songModel!.children.length;
                        });
                      },
                      icon: Icon(
                        Icons.skip_previous,
                        size: 40,
                        color: theme.iconTheme.color,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () {
                        if (!songModel!.children[currentIndex].isDownloaded) {
                          if (!songState.connectionEnabled) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.wifi_off, color: Colors.white),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Please enable your internet connection",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: EdgeInsets.all(16),
                                duration: Duration(seconds: 3),
                              ),
                            );

                            return;
                          }
                          setState(() {
                            isLoading = true;
                          });
                        }
                        context.read<SongBloc>().add(
                          DownloadAudioEvent(
                            songModel!,
                            songModel!.children[currentIndex].url!,
                          ),
                        );
                      },
                      icon: songState is AudioDownloadingFetchingState
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: CircularProgressIndicator(
                                    value:
                                        songState.progress /
                                        100, // <-- percentage
                                    strokeWidth: 4,
                                    backgroundColor: Colors.grey.withOpacity(
                                      0.2,
                                    ),
                                    valueColor: AlwaysStoppedAnimation(
                                      theme.primaryColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${songState.progress.toInt()}%",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.iconTheme.color,
                                  ),
                                ),
                              ],
                            )
                          : isLoading
                          ? const SizedBox(
                              width: 45,
                              height: 45,
                              child: CircularProgressIndicator(strokeWidth: 4),
                            )
                          : Icon(
                              songModel!.children[currentIndex].isDownloaded
                                  ? Icons.play_arrow
                                  : Icons.download,
                              size: 50,
                              color: theme.iconTheme.color,
                            ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          currentIndex =
                              (currentIndex + 1) % songModel!.children.length;
                        });
                      },
                      icon: Icon(
                        Icons.skip_next,
                        size: 40,
                        color: theme.iconTheme.color,
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),

                // Scrollable Song List at Bottom
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.2),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: songModel!.children.length,
                      itemBuilder: (context, index) {
                        final song = songModel!.children[index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: currentIndex == index
                                  ? theme.primaryColor.withOpacity(0.10)
                                  : theme.cardColor.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    setState(() => currentIndex = index),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Icon(Icons.music_note, size: 30),
                                  ),
                                  title: Text(
                                    song.name,
                                    style: textTheme.bodyLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    "3:45",
                                    style: textTheme.titleMedium,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  SizedBox imageWidget(
    ThemeData theme,
    String title,
    SongState songState,
    BuildContext context,
  ) {
    double height = MediaQuery.of(context).size.height;

    return SizedBox(
      height: height * 0.35,
      width: double.infinity,
      child: PageView.builder(
        controller: PageController(viewportFraction: 1.0),
        // optional: lock scroll if zoomed (you can manage this dynamically)
        physics: const BouncingScrollPhysics(),
        itemCount: songModel!.children.length,
        onPageChanged: (index) => setState(() => currentIndex = index),
        itemBuilder: (context, index) {
          bool isActive = index == currentIndex;
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: isActive ? 0 : 20,
                ),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: InteractiveViewer(
                    panEnabled: true,
                    scaleEnabled: true,
                    minScale: 1,
                    maxScale: 4,
                    clipBehavior: Clip.none,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child:
                        (songModel!.children[currentIndex].localPath != null &&
                                widget
                                    .song
                                    .children[currentIndex]
                                    .localPath!
                                    .isNotEmpty) ||
                            selectedImage[widget
                                    .song
                                    .children[currentIndex]
                                    .id] !=
                                null
                        ? Image.file(
                            File(
                              songModel!.children[currentIndex].localPath ??
                                  selectedImage[widget
                                      .song
                                      .children[currentIndex]
                                      .id],
                            ),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          )
                        : Image.asset(
                            "assets/kidus_yared.png",
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),

                    /*
                    Image.asset(
                      "assets/kidus_yared.png",
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                    */
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 10,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.iconTheme.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    tooltip: 'Upload',
                    icon: Icon(
                      Icons.cloud_upload_outlined,
                      color: theme.scaffoldBackgroundColor,
                    ),
                    onPressed: () async {
                      final imagePath = await pickImage(context);
                      if (imagePath.isEmpty) return; // user cancelled picking

                      // Show confirmation dialog with image preview
                      final confirm = await showConfirmImageDialog(
                        context,
                        imagePath,
                      );
                      if (confirm == true) {
                        selectedImage[songModel!.children[currentIndex].id] =
                            imagePath;
                        context.read<SongBloc>().add(
                          SaveImageLocallyEvent(
                            songModel!.children[currentIndex],
                            imagePath,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
