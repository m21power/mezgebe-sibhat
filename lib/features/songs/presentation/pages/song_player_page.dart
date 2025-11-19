import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif/gif.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/song_model.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/widgets/pick_image.dart';

class SongPlayerPage extends StatefulWidget {
  final SongModel song;
  const SongPlayerPage({super.key, required this.song});

  @override
  State<SongPlayerPage> createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage>
    with SingleTickerProviderStateMixin {
  double progress = 0.0;
  double playbackSpeed = 1.0;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  SongModel? songModel;
  int currentIndex = 0;
  double downloadProgress = 0;
  late AudioPlayer _audioPlayer;
  late GifController _controller;

  late StreamSubscription<PlayerState> _playerStateSub;
  late StreamSubscription<Duration> _positionSub;
  bool isPlaying = false;
  bool isLoading = false;
  // Add this to your state
  final Map<String, Duration> _durationCache = {};
  final AudioPlayer _tempPlayer = AudioPlayer();

  // Helper function
  Future<Duration> _getAudioDurationCached(String path) async {
    print("***************here******************");
    if (_durationCache.containsKey(path)) {
      print("*********************************");
      print("Using cached duration for $path: ${_durationCache[path]}");
      return _durationCache[path]!;
    }

    try {
      final duration = await _tempPlayer.setFilePath(path);
      _durationCache[path] = duration ?? Duration.zero;
      print("*********************************");
      print("Cached duration for $path: ${_durationCache[path]}");
      return Future.value(duration ?? Duration.zero);
    } catch (_) {
      print("Error getting audio duration for $path");
      return Duration.zero;
    }
  }

  @override
  void initState() {
    super.initState();
    songModel = widget.song;
    _audioPlayer = AudioPlayer();
    _controller = GifController(vsync: this);
    // Listen for total duration
    _audioPlayer.durationStream.listen((d) {
      if (d != null) {
        setState(() => totalDuration = d);
      }
    });

    // Listen for current position
    _positionSub = _audioPlayer.positionStream.listen((pos) {
      setState(() {
        currentPosition = pos;
        progress = totalDuration.inMilliseconds == 0
            ? 0
            : pos.inMilliseconds / totalDuration.inMilliseconds;
      });
    });

    // Listen for state changes
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
          isPlaying = false;
          progress = 0;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _playerStateSub.cancel();
    _positionSub.cancel();
    _audioPlayer.dispose();
    _tempPlayer.dispose();
    super.dispose();
  }

  // ---- FIXED: Centralized playback toggle ----
  Future<void> togglePlayPause() async {
    final currentChild = songModel!.children[currentIndex];

    if (!currentChild.isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This song isn’t downloaded yet")),
      );
      return;
    }

    final localUrl = currentChild.audioLocalPath!;
    // Always reload file if current source is different
    final currentTag = _audioPlayer.sequenceState?.sequence.firstOrNull?.tag;
    if (currentTag != localUrl) {
      await _audioPlayer.setFilePath(localUrl, tag: localUrl);
      await _audioPlayer.setSpeed(playbackSpeed);
    }

    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<bool> fileExists(String? localPath) async {
    if (localPath == null || localPath.isEmpty) return false;
    final file = File(localPath);
    return await file.exists();
  }

  // ---- FIXED: Switching between songs ----
  Future<void> playSongAtIndex(int index) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.reset();
        _controller.forward();
      }
    });

    if (index < 0 || index >= songModel!.children.length) return;
    if (!mounted) return;
    setState(() {
      currentIndex = index;
      isPlaying = false;
      progress = 0.0;
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
    });

    final song = songModel!.children[index];

    await _audioPlayer.stop();

    if (song.isDownloaded) {
      final localUrl = song.audioLocalPath!;
      await _audioPlayer.setFilePath(localUrl, tag: localUrl);
      await _audioPlayer.setSpeed(playbackSpeed);
      await _audioPlayer.play();
      setState(() => isLoading = false);
    } else {
      // reset UI since song isn't downloaded
      setState(() {
        isPlaying = false;
        totalDuration = Duration.zero;
        currentPosition = Duration.zero;
        progress = 0.0;
      });
    }
  }

  String formatDuration(Duration? d, [double? progress]) {
    if (d == null) return "--:--";
    final totalSeconds = d.inSeconds;
    final currentSeconds = progress == null
        ? totalSeconds
        : (progress * totalSeconds).toInt();
    final minutes = (currentSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (currentSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

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
              print("Progress:${songState.progress}");
              setState(() {
                isLoading = false;
                downloadProgress = songState.progress;
              });
            }
            if (songState is AudioDownloadSuccessfully) {
              setState(() {
                setState(() {
                  print("Download completed. updating ui...");
                  songModel = songState.songModel;
                });
              });
            }
            if (songState is AudioDownloadFailed) {
              setState(() => isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(
                    "Download failed: ${songState.message}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }
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
                            overflow: TextOverflow.ellipsis,
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
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    songModel!.children[currentIndex].name,
                    style: textTheme.displayMedium,
                  ),
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
                              value: progress.clamp(0.0, 1.0),
                              onChanged: (value) {
                                setState(() => progress = value);
                              },
                              onChangeEnd: (value) {
                                final newPosition = totalDuration * value;
                                _audioPlayer.seek(newPosition);
                              },
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
                                  _audioPlayer!.setSpeed(playbackSpeed);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            songModel!.children[currentIndex].isDownloaded
                                ? formatDuration(totalDuration, progress)
                                : "--:--",
                            style: textTheme.titleMedium,
                          ),
                          Text(
                            songModel!.children[currentIndex].isDownloaded
                                ? formatDuration(totalDuration)
                                : "--:--",
                            style: textTheme.titleMedium,
                          ),
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
                      onPressed: () => playSongAtIndex(
                        (currentIndex - 1 + songModel!.children.length) %
                            songModel!.children.length,
                      ),

                      icon: Icon(
                        Icons.skip_previous,
                        size: 40,
                        color: theme.iconTheme.color,
                      ),
                    ),
                    const SizedBox(width: 20),
                    FutureBuilder<bool>(
                      future: fileExists(
                        songModel!.children[currentIndex].audioLocalPath,
                      ),
                      builder: (context, snapshot) {
                        final exists = snapshot.data ?? false;

                        return IconButton(
                          onPressed: () async {
                            final currentChild =
                                songModel!.children[currentIndex];
                            final audioExistsLocally = await fileExists(
                              currentChild.audioLocalPath,
                            );

                            // If the song is downloaded
                            if (currentChild.isDownloaded &&
                                audioExistsLocally) {
                              final localUrl = currentChild.audioLocalPath!;
                              // If already playing something, toggle play/pause
                              if (isPlaying) {
                                await _audioPlayer.pause();
                              } else {
                                // Check if the file is already loaded
                                if (_audioPlayer.audioSource == null ||
                                    _audioPlayer
                                            .sequenceState
                                            ?.sequence
                                            .first
                                            .tag !=
                                        localUrl) {
                                  await _audioPlayer.setFilePath(
                                    localUrl,
                                    tag: localUrl,
                                  );
                                }
                                await _audioPlayer.setSpeed(playbackSpeed);
                                await _audioPlayer.play();
                              }
                            } else {
                              // Not downloaded yet
                              if (!songState.connectionEnabled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(
                                          Icons.wifi_off,
                                          color: Colors.white,
                                        ),
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
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }
                              setState(() => isLoading = true);
                              context.read<SongBloc>().add(
                                DownloadAudioEvent(
                                  parent: songModel!,
                                  child: currentChild,
                                ),
                              );
                            }
                          },
                          icon: songState is AudioDownloadingFetchingState
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 45,
                                      height: 45,
                                      child: CircularProgressIndicator(
                                        value: songState.progress / 100,
                                        strokeWidth: 4,
                                        backgroundColor: Colors.grey
                                            .withOpacity(0.2),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                  ),
                                )
                              : Icon(
                                  songModel!
                                              .children[currentIndex]
                                              .isDownloaded &&
                                          exists
                                      ? (isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled)
                                      : Icons.download,
                                  size: 50,
                                  color: theme.iconTheme.color,
                                ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () => playSongAtIndex(
                        (currentIndex + 1) % songModel!.children.length,
                      ),

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: songModel!.children.length,
                      itemBuilder: (context, index) {
                        final song = songModel!.children[index];
                        final isSelected = index == currentIndex;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => playSongAtIndex(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.primaryColor.withOpacity(0.15)
                                      : theme.cardColor.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.music_note,
                                      size: 28,
                                      color: theme.primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        song.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.equalizer,
                                        color: theme.primaryColor,
                                      ),
                                  ],
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
        onPageChanged: (index) => playSongAtIndex(index),
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
                child: FutureBuilder(
                  future: fileExists(
                    songModel!.children[currentIndex].imageLocalPath,
                  ),
                  builder: (context, snapShot) {
                    final exists = snapShot.data ?? false;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: InteractiveViewer(
                        panEnabled: true,
                        scaleEnabled: true,
                        minScale: 1,
                        maxScale: 4,
                        clipBehavior: Clip.none,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        child:
                            (songModel!.children[currentIndex].imageLocalPath !=
                                        null &&
                                    widget
                                        .song
                                        .children[currentIndex]
                                        .imageLocalPath!
                                        .isNotEmpty &&
                                    exists) ||
                                selectedImage[widget
                                        .song
                                        .children[currentIndex]
                                        .id] !=
                                    null
                            ? Image.file(
                                File(
                                  songModel!
                                          .children[currentIndex]
                                          .imageLocalPath ??
                                      selectedImage[widget
                                          .song
                                          .children[currentIndex]
                                          .id],
                                ),
                                fit: BoxFit.contain,
                                width: double.infinity,
                              )
                            // : Image.asset(
                            //     "assets/kidus_yared.png",
                            //     fit: BoxFit.contain,
                            //     width: double.infinity,
                            //   ),
                            : Center(
                                child: Gif(
                                  image: AssetImage(
                                    "assets/${songState.isLightTheme ? 'light_theme.gif' : 'dark_theme.gif'}",
                                  ),
                                  controller:
                                      _controller, // if duration and fps is null, original gif fps will be used.
                                  //fps: 30,
                                  //duration: const Duration(seconds: 3),
                                  autostart: Autostart.no,
                                  placeholder: (context) =>
                                      const Text('Loading...'),
                                  onFetchCompleted: () {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted) {
                                            _controller.reset();
                                            _controller.forward();
                                          }
                                        });
                                  },

                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    );
                  },
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
