import 'dart:async';
import 'dart:io';
import 'dart:ui'; // Required for BackdropFilter

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/song_model.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/widgets/pick_image.dart';

import '../../../Service/adService.dart';

class SongPlayerPage extends StatefulWidget {
  final SongModel song;
  const SongPlayerPage({super.key, required this.song});

  @override
  State<SongPlayerPage> createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage>
    with SingleTickerProviderStateMixin {
  // Logic remains unchanged
  double progress = 0.0;
  double playbackSpeed = 1.0;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  SongModel? songModel;
  int currentIndex = 0;
  double downloadProgress = 0;
  late AudioPlayer _audioPlayer;
  late PageController _pageController; // Add this line

  late StreamSubscription<PlayerState> _playerStateSub;
  late StreamSubscription<Duration> _positionSub;
  bool isPlaying = false;
  bool isLoading = false;
  final Map<String, Duration> _durationCache = {};
  final AudioPlayer _tempPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    songModel = widget.song;
    _audioPlayer = AudioPlayer();
    _pageController = PageController(initialPage: currentIndex);
    _audioPlayer.durationStream.listen((d) {
      if (d != null) setState(() => totalDuration = d);
    });

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      setState(() {
        currentPosition = pos;
        progress = totalDuration.inMilliseconds == 0
            ? 0
            : pos.inMilliseconds / totalDuration.inMilliseconds;
      });
    });

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
    _bannerAd = AdService().createBanner((ad) {
      setState(() {
        _isAdLoaded = true; // Set flag to true only when loaded
      });
    });
    AdService().loadInterstitial();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _playerStateSub.cancel();
    _positionSub.cancel();
    _audioPlayer.dispose();
    _tempPlayer.dispose();
    super.dispose();
  }

  Future<void> togglePlayPause() async {
    final currentChild = songModel!.children[currentIndex];
    if (!currentChild.isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This song isn’t downloaded yet")),
      );
      return;
    }
    final localUrl = currentChild.audioLocalPath!;
    final currentTag = _audioPlayer.sequenceState?.sequence.firstOrNull?.tag;
    if (currentTag != localUrl) {
      await _audioPlayer.setFilePath(localUrl, tag: localUrl);
      await _audioPlayer.setSpeed(playbackSpeed);
    }
    isPlaying ? await _audioPlayer.pause() : await _audioPlayer.play();
  }

  Future<void> playSongAtIndex(int index) async {
    if (index < 0 || index >= songModel!.children.length) return;

    setState(() {
      currentIndex = index;
      isPlaying = false;
      progress = 0.0;
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
    });

    // CRITICAL: Tell the PageView to move to the new image
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }

    final song = songModel!.children[index];
    await _audioPlayer.stop();

    if (song.isDownloaded) {
      final localUrl = song.audioLocalPath!;
      await _audioPlayer.setFilePath(localUrl, tag: localUrl);
      await _audioPlayer.setSpeed(playbackSpeed);
      await _audioPlayer.play();
    }
  }

  Future<bool> fileExists(String? localPath) async {
    if (localPath == null || localPath.isEmpty) return false;
    return await File(localPath).exists();
  }

  String formatDuration(Duration? d) {
    if (d == null) return "00:00";
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  final selectedImage = {};
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool isAudioDownloading = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true, // Transparent AppBar effect
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.song.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 35),
        ),
      ),
      body: BlocConsumer<SongBloc, SongState>(
        listenWhen: (previous, current) {
          if (current is AudioDownloadSuccessfully) {
            // Only trigger if the previous state wasn't success OR
            // if the newly downloaded song is different from the last one
            return previous is! AudioDownloadSuccessfully;
          }
          return false;
        },
        listener: (context, songState) {
          if (songState is AudioDownloadSuccessfully) {
            setState(() => songModel = songState.songModel);

            final adService = AdService();
            adService.incrementDownloadCount();

            debugPrint("Download Count: ${adService.downloadCounter}");

            if (adService.downloadCounter >= 2) {
              if (adService.interstitialAd != null) {
                _audioPlayer.pause();

                adService.interstitialAd!.fullScreenContentCallback =
                    FullScreenContentCallback(
                      onAdDismissedFullScreenContent: (ad) {
                        ad.dispose();
                        adService.loadInterstitial();
                        _audioPlayer.play();
                      },
                      onAdFailedToShowFullScreenContent: (ad, error) {
                        ad.dispose();
                        adService.loadInterstitial();
                        _audioPlayer.play();
                      },
                    );

                adService.interstitialAd!.show();
                adService.clearInterstitial();
                adService.resetDownloadCount();
              } else {
                // Reset even if ad isn't ready so the next pair triggers it
                adService.resetDownloadCount();
                adService.loadInterstitial();
              }
            }
          }
        },
        builder: (context, songState) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [const Color(0xFFF1F2F6), Colors.white],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 100),
                // 1. Image Viewer with soft shadow
                Expanded(
                  flex: 3,
                  child: imageWidget(
                    theme,
                    songModel!.name,
                    songState,
                    context,
                  ),
                ),

                // 2. Song Info
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      Text(
                        songModel!.children[currentIndex].name,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "መዝገበ ስብሐት",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Slider Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: theme.primaryColor,
                          inactiveTrackColor: theme.primaryColor.withOpacity(
                            0.15,
                          ),
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: (value) =>
                              setState(() => progress = value),
                          onChangeEnd: (value) =>
                              _audioPlayer.seek(totalDuration * value),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatDuration(currentPosition),
                              style: theme.textTheme.labelMedium,
                            ),
                            Text(
                              formatDuration(totalDuration),
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Main Controls Row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPlaybackAction(
                        Icons.skip_previous_rounded,
                        () => playSongAtIndex(
                          (currentIndex - 1 + songModel!.children.length) %
                              songModel!.children.length,
                        ),
                        size: 40,
                      ),
                      const SizedBox(width: 25),
                      _buildMainPlayButton(theme, songState),
                      const SizedBox(width: 25),
                      _buildPlaybackAction(
                        Icons.skip_next_rounded,
                        () => playSongAtIndex(
                          (currentIndex + 1) % songModel!.children.length,
                        ),
                        size: 40,
                      ),
                    ],
                  ),
                ),

                // 5. Glassmorphic Bottom List
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          itemCount: songModel!.children.length,
                          itemBuilder: (context, index) {
                            final song = songModel!.children[index];
                            final isSelected = index == currentIndex;
                            return _buildListTile(song, isSelected, theme);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: (_isAdLoaded && _bannerAd != null)
          ? SafeArea(
              child: Container(
                width: double.infinity,
                height: _bannerAd!.size.height.toDouble(),
                // MATCH THE PLAYER PAGE GRADIENT END COLOR
                color: isDark ? const Color(0xFF16213E) : Colors.white,
                alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // --- HELPER UI WIDGETS ---

  Widget _buildPlaybackAction(
    IconData icon,
    VoidCallback onTap, {
    double size = 30,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: size),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildMainPlayButton(ThemeData theme, SongState songState) {
    return FutureBuilder<bool>(
      future: fileExists(songModel!.children[currentIndex].audioLocalPath),
      builder: (context, snapshot) {
        final exists = snapshot.data ?? false;
        final currentChild = songModel!.children[currentIndex];

        if (songState is AudioDownloadingFetchingState) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: songState.progress / 100,
                strokeWidth: 5,
                color: theme.primaryColor,
              ),
              Text(
                "${songState.progress.toInt()}%",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }

        return GestureDetector(
          onTap: () async {
            if (songState is AudioDownloadRequestedState ||
                songState is AudioDownloadingFetchingState) {
              // Prevent multiple download attempts
              return;
            }
            // Your existing complex logic for Play/Pause/Download
            if (currentChild.isDownloaded && exists) {
              togglePlayPause();
            } else {
              if (!songState.connectionEnabled) {
                _showNoInternetSnackBar(context);
              } else {
                setState(() => isLoading = true);
                context.read<SongBloc>().add(
                  DownloadAudioEvent(parent: songModel!, child: currentChild),
                );
              }
            }
          },
          child: Container(
            height: 75,
            width: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: songState is AudioDownloadRequestedState
                ? CircularProgressIndicator(strokeWidth: 3, color: Colors.white)
                : Icon(
                    currentChild.isDownloaded && exists
                        ? (isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded)
                        : Icons.download_rounded,
                    size: 45,
                    color: Colors.white,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildListTile(SongModel song, bool isSelected, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: () => playSongAtIndex(songModel!.children.indexOf(song)),
        leading: Icon(
          isSelected ? Icons.equalizer_rounded : Icons.music_note_rounded,
          color: isSelected
              ? theme.primaryColor
              : theme.iconTheme.color?.withOpacity(0.5),
        ),
        title: Text(
          song.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.primaryColor : null,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.play_circle_fill, size: 20)
            : (song.isDownloaded
                  ? const Icon(Icons.check_circle_outline, size: 16)
                  : null),
      ),
    );
  }

  void _showNoInternetSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Please enable internet connection"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- Optimized imageWidget with smooth shadows ---
  Widget imageWidget(
    ThemeData theme,
    String title,
    SongState songState,
    BuildContext context,
  ) {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: songModel!.children.length,
      onPageChanged: (index) => playSongAtIndex(index),
      itemBuilder: (context, index) {
        bool isActive = index == currentIndex;
        final currentChild = songModel!.children[index];

        return AnimatedScale(
          scale: isActive ? 1.0 : 0.8,
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: FutureBuilder<bool>(
                future: fileExists(currentChild.imageLocalPath),
                builder: (context, snap) {
                  final exists = snap.data ?? false;
                  final localPath = currentChild.imageLocalPath;
                  final hasUploaded =
                      (localPath != null && exists) ||
                      selectedImage[currentChild.id] != null;

                  return Stack(
                    children: [
                      // The Image Layer with Zoom
                      Positioned.fill(
                        child: hasUploaded
                            ? InteractiveViewer(
                                clipBehavior: Clip.none,
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Image.file(
                                  File(
                                    localPath ?? selectedImage[currentChild.id],
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              )
                            : _buildAnimatedPlaceholder(
                                theme,
                                currentChild.id,
                              ), // Cool placeholder
                      ),

                      // Upload Button Overlay
                      Positioned(
                        bottom: 15,
                        right: 15,
                        child: _buildUploadButton(theme, currentChild.id),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedPlaceholder(ThemeData theme, String songId) {
    return GestureDetector(
      onTap: () async {
        final imagePath = await pickImage(context);
        if (imagePath.isNotEmpty) {
          final confirm = await showConfirmImageDialog(context, imagePath);
          if (confirm == true) {
            setState(() {
              // CRITICAL: Bind image to specific ID
              selectedImage[songId] = imagePath;
            });
            context.read<SongBloc>().add(
              SaveImageLocallyEvent(
                songModel!.children[currentIndex],
                imagePath,
              ),
            );
          }
        }
      },
      child: Container(
        color: theme.primaryColor.withOpacity(0.05),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOutSine,
          builder: (context, value, child) {
            return Opacity(
              opacity: 0.6 + (value * 0.4), // Gentle pulse
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 60,
                    color: theme.primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "For a better experience, upload a photo of the book page you are listening to.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.primaryColor.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          onEnd:
              () {}, // Restart loop via state if needed, but Tween handles pulse well
        ),
      ),
    );
  }

  Widget _buildUploadButton(ThemeData theme, String songId) {
    return GestureDetector(
      onTap: () async {
        final imagePath = await pickImage(context);
        if (imagePath.isNotEmpty) {
          final confirm = await showConfirmImageDialog(context, imagePath);
          if (confirm == true) {
            setState(() {
              // CRITICAL: Bind image to specific ID
              selectedImage[songId] = imagePath;
            });
            context.read<SongBloc>().add(
              SaveImageLocallyEvent(
                songModel!.children[currentIndex],
                imagePath,
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
