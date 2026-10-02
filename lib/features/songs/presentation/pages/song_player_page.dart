import 'dart:async';
import 'dart:io';
import 'dart:ui'; // Required for BackdropFilter

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/song_model.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/widgets/pick_image.dart';

import '../../../Service/adService.dart';

/// ---------------------------------------------------------------------
/// Natural / alphanumeric sort helper.
/// ---------------------------------------------------------------------
int _naturalCompare(String a, String b) {
  final regExp = RegExp(r'(\d+|\D+)');
  final aParts = regExp.allMatches(a).map((m) => m.group(0)!).toList();
  final bParts = regExp.allMatches(b).map((m) => m.group(0)!).toList();

  final len = aParts.length < bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < len; i++) {
    final aPart = aParts[i];
    final bPart = bParts[i];
    final aNum = int.tryParse(aPart);
    final bNum = int.tryParse(bPart);

    if (aNum != null && bNum != null) {
      final cmp = aNum.compareTo(bNum);
      if (cmp != 0) return cmp;
    } else {
      final cmp = aPart.toLowerCase().compareTo(bPart.toLowerCase());
      if (cmp != 0) return cmp;
    }
  }
  return aParts.length.compareTo(bParts.length);
}

SongModel _naturallySorted(SongModel model) {
  model.children.sort((a, b) => _naturalCompare(a.name, b.name));
  return model;
}

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
  late PageController _pageController;

  late StreamSubscription<PlayerState> _playerStateSub;
  late StreamSubscription<Duration> _positionSub;
  bool isPlaying = false;
  bool isLoading = false;
  final AudioPlayer _tempPlayer = AudioPlayer();

  /// Guards against PageView.onPageChanged re-triggering playback for every
  /// intermediate page while we animate the PageController programmatically.
  bool _isProgrammaticPageChange = false;

  /// When true, the image area is collapsed so the song list can use the
  /// whole screen.
  bool _imageCollapsed = false;
  final GlobalKey _selectedTileKey = GlobalKey();

  // ---------------------------------------------------------------------
  // Zoom / pan state
  // ---------------------------------------------------------------------
  static const double _maxZoom = 5.0;
  static const double _zoomStep = 1.5;

  /// One transformation controller per song image (keyed by song id).
  final Map<String, TransformationController> _zoomControllers = {};

  /// Current zoom level of the visible image. Only the zoom controls listen
  /// to this, so zooming doesn't rebuild the whole page every frame.
  final ValueNotifier<double> _scaleNotifier = ValueNotifier<double>(1.0);

  /// True while the visible image is zoomed in. Used to lock the horizontal
  /// swipe between songs so finger-panning works inside the image.
  bool _isZoomed = false;

  /// Size of the image viewport (needed to zoom around the centre and to
  /// keep the image inside its bounds when using the buttons).
  Size _viewportSize = Size.zero;

  late AnimationController _zoomAnim;
  VoidCallback? _zoomTick;

  TransformationController _controllerFor(String id) {
    return _zoomControllers.putIfAbsent(id, () {
      final c = TransformationController();
      c.addListener(() {
        if (!mounted) return;
        final isCurrent = songModel!.children[currentIndex].id == id;
        if (!isCurrent) return;
        final s = c.value.getMaxScaleOnAxis();
        _scaleNotifier.value = s;
        final zoomed = s > 1.01;
        if (zoomed != _isZoomed) {
          setState(() => _isZoomed = zoomed);
        }
      });
      return c;
    });
  }

  TransformationController get _currentZoomController =>
      _controllerFor(songModel!.children[currentIndex].id);

  /// Builds a matrix with the given scale/translation, clamped so the image
  /// can never be dragged outside its frame.
  Matrix4 _buildMatrix(double scale, double tx, double ty) {
    final w = _viewportSize.width;
    final h = _viewportSize.height;
    final cx = tx.clamp(w * (1 - scale), 0.0).toDouble();
    final cy = ty.clamp(h * (1 - scale), 0.0).toDouble();
    return Matrix4.translationValues(cx, cy, 0)
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1));
  }

  void _animateTo(TransformationController c, Matrix4 end) {
    if (_zoomTick != null) _zoomAnim.removeListener(_zoomTick!);
    _zoomAnim.stop();
    final tween = Matrix4Tween(begin: c.value, end: end);
    final curved = CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOut);
    _zoomTick = () => c.value = tween.evaluate(curved);
    _zoomAnim.addListener(_zoomTick!);
    _zoomAnim.forward(from: 0);
  }

  void _zoomBy(double factor) {
    if (_viewportSize == Size.zero) return;
    final c = _currentZoomController;
    final s = c.value.getMaxScaleOnAxis();
    final ns = (s * factor).clamp(1.0, _maxZoom).toDouble();
    if ((ns - s).abs() < 0.001) return;

    // Zoom around the centre of the image frame.
    final t = c.value.getTranslation();
    final cx = _viewportSize.width / 2;
    final cy = _viewportSize.height / 2;
    final k = ns / s;
    _animateTo(c, _buildMatrix(ns, cx - (cx - t.x) * k, cy - (cy - t.y) * k));
  }

  /// dirX / dirY: -1, 0 or 1. Moves the *view* in that direction.
  void _pan(double dirX, double dirY) {
    if (_viewportSize == Size.zero) return;
    final c = _currentZoomController;
    final s = c.value.getMaxScaleOnAxis();
    if (s <= 1.01) return;
    final t = c.value.getTranslation();
    _animateTo(
      c,
      _buildMatrix(
        s,
        t.x - dirX * _viewportSize.width * 0.4,
        t.y - dirY * _viewportSize.height * 0.4,
      ),
    );
  }

  void _resetZoom() {
    _animateTo(_currentZoomController, Matrix4.identity());
  }

  void _toggleDoubleTapZoom() {
    final s = _currentZoomController.value.getMaxScaleOnAxis();
    if (s > 1.01) {
      _resetZoom();
    } else {
      _zoomBy(2.5);
    }
  }

  @override
  void initState() {
    super.initState();
    songModel = _naturallySorted(widget.song);
    _audioPlayer = AudioPlayer();
    _pageController = PageController(initialPage: currentIndex);
    _zoomAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
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
        _isAdLoaded = true;
      });
    });
    AdService().loadInterstitial();
  }

  // --- Native ad insertion helpers ---
  static const int _adInterval = 15;

  bool _isAdSlot(int listIndex) =>
      listIndex != 0 && (listIndex + 1) % (_adInterval + 1) == 0;

  int _itemCountWithAds(int songCount) {
    if (songCount <= _adInterval) return songCount;
    final adCount = songCount ~/ _adInterval;
    return songCount + adCount;
  }

  int _songIndexForListIndex(int listIndex) {
    final adsBefore = (listIndex + 1) ~/ (_adInterval + 1);
    return listIndex - adsBefore;
  }

  final Map<int, NativeAd> _nativeAds = {};
  final Set<int> _failedAdSlots = {};

  Widget _buildNativeAdTile(int listIndex) {
    if (_failedAdSlots.contains(listIndex)) {
      return const SizedBox.shrink();
    }

    if (!_nativeAds.containsKey(listIndex)) {
      AdService().createNativeAd(
        onLoaded: (nativeAd) {
          if (!mounted) {
            nativeAd.dispose();
            return;
          }
          setState(() => _nativeAds[listIndex] = nativeAd);
        },
        onFailed: (_) {
          if (mounted) setState(() => _failedAdSlots.add(listIndex));
        },
      );
      return const SizedBox.shrink();
    }

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: AdWidget(ad: _nativeAds[listIndex]!),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _playerStateSub.cancel();
    _positionSub.cancel();
    _audioPlayer.dispose();
    _tempPlayer.dispose();
    _zoomAnim.dispose();
    _scaleNotifier.dispose();
    for (final c in _zoomControllers.values) {
      c.dispose();
    }
    for (final ad in _nativeAds.values) {
      ad.dispose();
    }
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
    final currentTag = _audioPlayer.sequenceState.sequence.firstOrNull?.tag;
    if (currentTag != localUrl) {
      await _audioPlayer.setFilePath(localUrl, tag: localUrl);
      await _audioPlayer.setSpeed(playbackSpeed);
    }
    isPlaying ? await _audioPlayer.pause() : await _audioPlayer.play();
  }

  Future<void> playSongAtIndex(int index, {bool animatePage = true}) async {
    if (index < 0 || index >= songModel!.children.length) return;

    // Every song remembers its own zoom/pan. Look up the target song's
    // saved zoom so the controls and swipe-lock match it.
    final targetScale = _controllerFor(
      songModel!.children[index].id,
    ).value.getMaxScaleOnAxis();

    setState(() {
      currentIndex = index;
      isPlaying = false;
      progress = 0.0;
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
      _imageCollapsed = false; // expand the image whenever a song is picked
      _isZoomed = targetScale > 1.01;
    });
    _scaleNotifier.value = targetScale;

    // Keep the selected tile in view once the image has expanded
    Future.delayed(const Duration(milliseconds: 300), () {
      final ctx = _selectedTileKey.currentContext;
      if (mounted && ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    // Move the image PageView to the selected song's image
    if (animatePage && _pageController.hasClients) {
      _isProgrammaticPageChange = true;
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _isProgrammaticPageChange = false;
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

    // Full (expanded) height of the image area.
    final screenH = MediaQuery.of(context).size.height;
    final imageH = screenH < 700
        ? (screenH * 0.30).clamp(170.0, 220.0)
        : (screenH * 0.36).clamp(200.0, 320.0);

    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 68,
          titleSpacing: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.45),
                  Colors.black.withOpacity(0.0),
                ],
              ),
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 35,
              color: Colors.white,
            ),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.song.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 3),
              ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    songModel!.children[currentIndex].name,
                    key: ValueKey(currentIndex),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: 0.4,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: BlocConsumer<SongBloc, SongState>(
          listenWhen: (previous, current) {
            if (current is AudioDownloadSuccessfully) {
              return previous is! AudioDownloadSuccessfully;
            }
            return false;
          },
          listener: (context, songState) async {
            if (songState is AudioDownloadSuccessfully) {
              setState(() => songModel = _naturallySorted(songState.songModel));

              final downloadedChild = songModel!.children[currentIndex];
              if (downloadedChild.isDownloaded &&
                  downloadedChild.audioLocalPath != null) {
                final localUrl = downloadedChild.audioLocalPath!;
                await _audioPlayer.stop();
                await _audioPlayer.setFilePath(localUrl, tag: localUrl);
                await _audioPlayer.setSpeed(playbackSpeed);
                await _audioPlayer.play();
              }

              final adService = AdService();
              adService.incrementDownloadCount();

              debugPrint("Download Count: ${adService.downloadCounter}");

              if (adService.downloadCounter >= 3) {
                if (adService.interstitialAd != null) {
                  _audioPlayer.pause();

                  adService
                      .interstitialAd!
                      .fullScreenContentCallback = FullScreenContentCallback(
                    onAdDismissedFullScreenContent: (ad) async {
                      ad.dispose();
                      adService.loadInterstitial();
                      await Future.delayed(const Duration(milliseconds: 400));
                      if (mounted) {
                        await _audioPlayer.play();
                      }
                    },
                    onAdFailedToShowFullScreenContent: (ad, error) async {
                      ad.dispose();
                      adService.loadInterstitial();
                      await Future.delayed(const Duration(milliseconds: 400));
                      if (mounted) {
                        await _audioPlayer.play();
                      }
                    },
                  );

                  adService.interstitialAd!.show();
                  adService.clearInterstitial();
                  adService.resetDownloadCount();
                } else {
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
                  SizedBox(height: MediaQuery.of(context).padding.top),

                  // 1. Image Viewer — collapses to 0 while browsing the list.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    height: _imageCollapsed ? 0 : imageH,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: imageH,
                        maxHeight: imageH,
                        child: SizedBox(
                          height: imageH,
                          child: imageWidget(
                            theme,
                            songModel!.name,
                            songState,
                            context,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Slider
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: theme.primaryColor,
                        inactiveTrackColor: theme.primaryColor.withOpacity(
                          0.15,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            formatDuration(currentPosition),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.textTheme.labelSmall?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: (value) =>
                                  setState(() => progress = value),
                              onChangeEnd: (value) =>
                                  _audioPlayer.seek(totalDuration * value),
                            ),
                          ),
                          Text(
                            formatDuration(totalDuration),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.textTheme.labelSmall?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Main Controls Row
                  Padding(
                    padding: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPlaybackAction(
                          Icons.skip_previous_rounded,
                          () => playSongAtIndex(
                            (currentIndex - 1 + songModel!.children.length) %
                                songModel!.children.length,
                          ),
                          size: 36,
                        ),
                        const SizedBox(width: 20),
                        _buildMainPlayButton(theme, songState),
                        const SizedBox(width: 20),
                        _buildPlaybackAction(
                          Icons.skip_next_rounded,
                          () => playSongAtIndex(
                            (currentIndex + 1) % songModel!.children.length,
                          ),
                          size: 36,
                        ),
                      ],
                    ),
                  ),

                  // 4. Glassmorphic Bottom List
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(40),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(40),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n.depth != 0) return false;

                              // Scrolling down the list -> collapse the image
                              if (n is UserScrollNotification &&
                                  n.direction == ScrollDirection.reverse &&
                                  !_imageCollapsed) {
                                setState(() => _imageCollapsed = true);
                              }

                              // Pulling down at the very top -> bring it back
                              final atTopPullingDown =
                                  (n is OverscrollNotification &&
                                      n.overscroll < 0) ||
                                  (n is ScrollUpdateNotification &&
                                      n.metrics.pixels <= 0 &&
                                      (n.scrollDelta ?? 0) < 0);
                              if (atTopPullingDown && _imageCollapsed) {
                                setState(() => _imageCollapsed = false);
                              }
                              return false;
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 12,
                              ),
                              itemCount: _itemCountWithAds(
                                songModel!.children.length,
                              ),
                              itemBuilder: (context, index) {
                                if (_isAdSlot(index)) {
                                  return _buildNativeAdTile(index);
                                }
                                final songIndex = _songIndexForListIndex(index);
                                final song = songModel!.children[songIndex];
                                final isSelected = songIndex == currentIndex;
                                return _buildListTile(song, isSelected, theme);
                              },
                            ),
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
                  color: isDark ? const Color(0xFF16213E) : Colors.white,
                  alignment: Alignment.center,
                  child: AdWidget(ad: _bannerAd!),
                ),
              )
            : const SizedBox.shrink(),
      ),
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
          return SizedBox(
            height: 56,
            width: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: songState.progress / 100,
                  strokeWidth: 4,
                  color: theme.primaryColor,
                ),
                Text(
                  "${songState.progress.toInt()}%",
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () async {
            if (songState is AudioDownloadRequestedState ||
                songState is AudioDownloadingFetchingState) {
              return;
            }
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
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: songState is AudioDownloadRequestedState
                ? const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  )
                : Icon(
                    currentChild.isDownloaded && exists
                        ? (isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded)
                        : Icons.download_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildListTile(SongModel song, bool isSelected, ThemeData theme) {
    return AnimatedContainer(
      key: isSelected ? _selectedTileKey : null,
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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

  // --- imageWidget ---
  Widget imageWidget(
    ThemeData theme,
    String title,
    SongState songState,
    BuildContext context,
  ) {
    return PageView.builder(
      controller: _pageController,
      // Lock swiping between songs while zoomed in, so dragging the image
      // pans it instead. Zoom out (or tap reset) to swipe again.
      physics: _isZoomed
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      itemCount: songModel!.children.length,
      onPageChanged: (index) {
        if (_isProgrammaticPageChange) return;
        playSongAtIndex(index, animatePage: false);
      },
      itemBuilder: (context, index) {
        bool isActive = index == currentIndex;
        final currentChild = songModel!.children[index];

        return AnimatedScale(
          scale: isActive ? 1.0 : 0.8,
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (isActive) _viewportSize = constraints.biggest;

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: hasUploaded
                                ? GestureDetector(
                                    onDoubleTap: isActive
                                        ? _toggleDoubleTapZoom
                                        : null,
                                    child: InteractiveViewer(
                                      transformationController: _controllerFor(
                                        currentChild.id,
                                      ),
                                      clipBehavior: Clip.none,
                                      minScale: 1.0,
                                      maxScale: _maxZoom,
                                      child: Image.file(
                                        File(
                                          localPath ??
                                              selectedImage[currentChild.id],
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  )
                                : _buildAnimatedPlaceholder(
                                    theme,
                                    currentChild.id,
                                  ),
                          ),

                          // Pan arrows (only visible while zoomed in)
                          if (hasUploaded && isActive) _buildPanArrows(),

                          // Zoom controls (bottom-left)
                          if (hasUploaded && isActive)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: _buildZoomControls(),
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
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Zoom UI ---

  /// Small glass pill:  [ − ]  1.5×  [ + ]
  /// Tapping the "1.5×" label resets the zoom back to 1.0×.
  Widget _buildZoomControls() {
    return ValueListenableBuilder<double>(
      valueListenable: _scaleNotifier,
      builder: (context, scale, _) {
        final canZoomOut = scale > 1.01;
        final canZoomIn = scale < _maxZoom - 0.01;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _zoomButton(
                Icons.remove_rounded,
                canZoomOut ? () => _zoomBy(1 / _zoomStep) : null,
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: canZoomOut ? _resetZoom : null,
                child: SizedBox(
                  width: 40,
                  child: Text(
                    "${scale.toStringAsFixed(1)}×",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(canZoomOut ? 1 : 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _zoomButton(
                Icons.add_rounded,
                canZoomIn ? () => _zoomBy(_zoomStep) : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? Colors.white30 : Colors.white,
        ),
      ),
    );
  }

  /// Four small arrows on the edges of the image. They fade in only when the
  /// image is zoomed, and move the view left / right / up / down.
  Widget _buildPanArrows() {
    return Positioned.fill(
      child: ValueListenableBuilder<double>(
        valueListenable: _scaleNotifier,
        builder: (context, scale, _) {
          final zoomed = scale > 1.01;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !zoomed
                ? const SizedBox.shrink(key: ValueKey('no-arrows'))
                : Stack(
                    key: const ValueKey('arrows'),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _panButton(
                            Icons.chevron_left_rounded,
                            () => _pan(-1, 0),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _panButton(
                            Icons.chevron_right_rounded,
                            () => _pan(1, 0),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _panButton(
                            Icons.keyboard_arrow_up_rounded,
                            () => _pan(0, -1),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _panButton(
                            Icons.keyboard_arrow_down_rounded,
                            () => _pan(0, 1),
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _panButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, size: 22, color: Colors.white),
      ),
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
              opacity: 0.6 + (value * 0.4),
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
          onEnd: () {},
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
