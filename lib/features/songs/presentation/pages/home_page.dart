import 'package:flutter/material.dart';
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

    return Theme(
      data: songState.isLightTheme ? AppThemes.lightTheme : AppThemes.darkTheme,
      child: SafeArea(
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [const Color(0xFF0F1226), const Color(0xFF161B33)]
                    : [Colors.white, const Color(0xFFF0F2F8)],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: GestureDetector(
                      onTap: () {
                        // MobileAds.instance.openAdInspector((error) {
                        //   if (error != null) {
                        //     debugPrint('Ad Inspector error: ${error.message}');
                        //   } else {
                        //     debugPrint('Ad Inspector closed.');
                        //   }
                        // });
                      },
                      child: Text(
                        "መዝገበ ስብሐት",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.redAccent),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const DonationSheet(),
                      ),
                    ),
                    _buildMenu(isDarkMode),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => buildSongItem(
                        songState.songs[index],
                        theme,
                        isDarkMode,
                      ),
                      childCount: songState.songs.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: (_isAdLoaded && _bannerAd != null)
              ? SafeArea(
                  // 1. Prevents clipping by system buttons/notches
                  child: Container(
                    // 2. Use double.infinity to ensure it doesn't crop horizontally
                    width: double.infinity,
                    // 3. Force the exact height AdMob expects for 'AdSize.banner'
                    height: _bannerAd!.size.height.toDouble(),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF161B33)
                          : const Color(0xFFF0F2F8),
                      // 4. Subtle border to separate it from the content
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

  Widget _buildMenu(bool isDarkMode) {
    final theme = Theme.of(context);
    final iconColor = isDarkMode ? Colors.white70 : Colors.black87;

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_vert_rounded, color: iconColor),
      ),
      offset: const Offset(0, 55), // Positioned slightly lower
      elevation: 8,
      // Using a more pronounced curve for a modern feel
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      // Background color of the menu itself
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
              Icon(
                isDarkMode
                    ? Icons.wb_sunny_outlined
                    : Icons.nightlight_round_outlined,
                color: isDarkMode ? Colors.orangeAccent : Colors.indigo,
                size: 22,
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
        const PopupMenuDivider(height: 1), // Adds a nice clean line
        PopupMenuItem(
          value: 'about',
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.blueAccent,
                size: 22,
              ),
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

  Widget buildSongItem(
    SongModel song,
    ThemeData theme,
    bool isDarkMode, {
    double indent = 0,
  }) {
    final expanded = isExpanded(song);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  final hasAudioChildren = song.children.any(
                    (child) => child.isAudio,
                  );
                  if (song.listHere && !hasAudioChildren) {
                    toggleExpanded(song);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SongPlayerPage(song: song),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: expanded
                        ? theme.primaryColor.withOpacity(0.12)
                        : (isDarkMode
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: expanded
                          ? theme.primaryColor.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                    boxShadow: [
                      if (!expanded)
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDarkMode ? 0.2 : 0.05,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        expanded
                            ? Icons.folder_open_rounded
                            : Icons.folder_rounded,
                        color: Colors.orange.shade600,
                        size: 26,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          song.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: expanded
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (song.listHere && !song.children.any((c) => c.isAudio))
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_right_rounded,
                          color: theme.hintColor,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (expanded)
          ...song.children.map(
            (child) =>
                buildSongItem(child, theme, isDarkMode, indent: indent + 16),
          ),
      ],
    );
  }
}
