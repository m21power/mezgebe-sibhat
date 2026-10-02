import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:mezgebe_sibhat/features/Service/adService.dart';
import 'package:mezgebe_sibhat/features/songs/data/local/song_model.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/pages/about_page.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/pages/donation_card.dart';
import 'package:mezgebe_sibhat/theme/theme.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/pages/song_player_page.dart';

// ---------------------------------------------------------------------
// Small design helpers
// ---------------------------------------------------------------------
Color _shade(Color c, double delta) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + delta).clamp(0.0, 1.0)).toColor();
}

LinearGradient _gradientFor(Color base) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_shade(base, 0.08), _shade(base, -0.08)],
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _headerExpandedHeight = 140;

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎉 Update downloaded!'),
              action: SnackBarAction(
                label: 'Restart',
                onPressed: () => InAppUpdate.completeFlexibleUpdate(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  @override
  void initState() {
    super.initState();
    _checkForUpdate();

    // Wait for the first frame to render before touching the ad SDK — that's
    // where the multi-second Davey frames were coming from, not song loading.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bannerAd = AdService().createBanner((ad) {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songState = context.watch<SongBloc>().state;
    final theme = Theme.of(context);
    final isDarkMode = !songState.isLightTheme;
    final songs = songState.songs;
    final primary = theme.primaryColor;

    return Theme(
      data: songState.isLightTheme ? AppThemes.lightTheme : AppThemes.darkTheme,
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [const Color(0xFF0F1226), const Color(0xFF161B33)]
                          : [Colors.white, const Color(0xFFF0F2F8)],
                    ),
                  ),
                ),
              ),

              // Soft ambient glow in the top-right corner
              Positioned(
                top: -90,
                right: -70,
                child: IgnorePointer(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primary.withOpacity(isDarkMode ? 0.28 : 0.16),
                          primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              CustomScrollView(
                slivers: [
                  _buildHeader(theme, isDarkMode, songs.length),

                  // Section label
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 2),
                      child: Row(
                        children: [
                          Text(
                            'Collections',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${songs.length}',
                              style: TextStyle(
                                color: primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _FadeSlideIn(
                          index: index,
                          child: buildSongItem(songs[index], theme, isDarkMode),
                        ),
                        childCount: songs.length,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: (_isAdLoaded && _bannerAd != null)
              ? SafeArea(
                  child: Container(
                    width: double.infinity,
                    height: _bannerAd!.size.height.toDouble(),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF161B33)
                          : const Color(0xFFF0F2F8),
                      border: Border(
                        top: BorderSide(
                          color: isDarkMode ? Colors.white10 : Colors.black12,
                          width: 0.5,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AdWidget(ad: _bannerAd!),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header: big title that collapses into a compact bar
  // ---------------------------------------------------------------------
  Widget _buildHeader(ThemeData theme, bool isDarkMode, int count) {
    final primary = theme.primaryColor;
    final barColor = isDarkMode ? const Color(0xFF0F1226) : Colors.white;

    final titleGradient = LinearGradient(
      colors: isDarkMode
          ? [Colors.white, _shade(primary, 0.25)]
          : [const Color(0xFF1B1F3B), primary],
    );

    return SliverAppBar(
      expandedHeight: _headerExpandedHeight,
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, c) {
          // 1 = fully expanded, 0 = fully collapsed
          final t =
              ((c.maxHeight - kToolbarHeight) /
                      (_headerExpandedHeight - kToolbarHeight))
                  .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Solid bar fades in as the header collapses
              Container(color: barColor.withOpacity((1 - t) * 0.94)),

              // Large title (expanded)
              Positioned(
                left: 22,
                bottom: 16,
                child: Opacity(
                  opacity: t,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUDIO LIBRARY',
                        style: TextStyle(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (rect) => titleGradient.createShader(
                          Rect.fromLTWH(0, 0, rect.width, rect.height),
                        ),
                        child: Text(
                          'መዝገበ ስብሐት',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Compact title (collapsed)
              Positioned(
                left: 22,
                top: 0,
                height: kToolbarHeight,
                child: Opacity(
                  opacity: 1 - t,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'መዝገበ ስብሐት',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // Donate
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const DonationSheet(),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildMenu(isDarkMode),
        const SizedBox(width: 14),
      ],
    );
  }

  Widget _buildMenu(bool isDarkMode) {
    final theme = Theme.of(context);
    final iconColor = isDarkMode ? Colors.white70 : Colors.black87;

    Widget menuIcon(IconData icon, Color color) => Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: color, size: 19),
    );

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Icon(Icons.more_vert_rounded, color: iconColor, size: 20),
      ),
      offset: const Offset(0, 52),
      elevation: 10,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      color: isDarkMode ? const Color(0xFF1A1F3D) : Colors.white,
      onSelected: (value) {
        if (value == 'about') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutPage()),
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
          child: Row(
            children: [
              menuIcon(
                isDarkMode
                    ? Icons.wb_sunny_rounded
                    : Icons.nightlight_round_rounded,
                isDarkMode ? Colors.orangeAccent : Colors.indigo,
              ),
              const SizedBox(width: 12),
              Text(
                isDarkMode ? 'Light Mode' : 'Dark Mode',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'about',
          child: Row(
            children: [
              menuIcon(Icons.info_rounded, Colors.blueAccent),
              const SizedBox(width: 12),
              Text(
                'About App',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Collection card (recursive — children appear in an indented branch)
  // ---------------------------------------------------------------------
  Widget buildSongItem(
    SongModel song,
    ThemeData theme,
    bool isDarkMode, {
    int depth = 0,
  }) {
    final expanded = isExpanded(song);
    final primary = theme.primaryColor;

    final hasAudioChildren = song.children.any((child) => child.isAudio);
    final isExpandable = song.listHere && !hasAudioChildren;
    final audioCount = song.children.where((c) => c.isAudio).length;

    String? subtitle;
    if (hasAudioChildren) {
      subtitle = '$audioCount ${audioCount == 1 ? 'track' : 'tracks'}';
    } else if (song.children.isNotEmpty) {
      subtitle =
          '${song.children.length} ${song.children.length == 1 ? 'item' : 'items'}';
    }

    // Icon tile: orange folders for expandable groups, brand colour for
    // anything that opens the player.
    final IconData tileIcon;
    final Color tileColor;
    if (isExpandable) {
      tileIcon = expanded ? Icons.folder_open_rounded : Icons.folder_rounded;
      tileColor = Colors.orange.shade600;
    } else {
      tileIcon = hasAudioChildren
          ? Icons.headphones_rounded
          : Icons.library_music_rounded;
      tileColor = primary;
    }

    final tileSize = depth == 0 ? 48.0 : 40.0;
    final radius = depth == 0 ? 22.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: _PressableScale(
            onTap: () {
              HapticFeedback.selectionClick();
              if (song.listHere && !hasAudioChildren) {
                toggleExpanded(song);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SongPlayerPage(song: song)),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.all(depth == 0 ? 14 : 11),
              decoration: BoxDecoration(
                color: expanded
                    ? primary.withOpacity(0.10)
                    : (isDarkMode
                          ? Colors.white.withOpacity(0.055)
                          : Colors.white),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: expanded
                      ? primary.withOpacity(0.35)
                      : (isDarkMode
                            ? Colors.white.withOpacity(0.07)
                            : Colors.black.withOpacity(0.04)),
                ),
                boxShadow: [
                  if (!expanded)
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.22 : 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: Row(
                children: [
                  // Gradient icon tile
                  Container(
                    width: tileSize,
                    height: tileSize,
                    decoration: BoxDecoration(
                      gradient: _gradientFor(tileColor),
                      borderRadius: BorderRadius.circular(depth == 0 ? 15 : 13),
                      boxShadow: [
                        BoxShadow(
                          color: tileColor.withOpacity(0.32),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      tileIcon,
                      color: Colors.white,
                      size: depth == 0 ? 25 : 21,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: expanded
                                ? FontWeight.w800
                                : FontWeight.w600,
                            height: 1.25,
                            fontSize: depth == 0 ? null : 15,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Trailing: rotating chevron for groups, play badge for audio
                  if (isExpandable)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(expanded ? 0.18 : 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: expanded ? primary : theme.hintColor,
                          size: 22,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: primary,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Expanded children, drawn as a branch with a guide line
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: primary.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: song.children
                          .map(
                            (child) => buildSongItem(
                              child,
                              theme,
                              isDarkMode,
                              depth: depth + 1,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Press-down scale feedback for cards
// ---------------------------------------------------------------------
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Fade + slide-up entrance for list items
// ---------------------------------------------------------------------
class _FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;
  const _FadeSlideIn({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final step = index > 8 ? 8 : index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 380 + step * 45),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
