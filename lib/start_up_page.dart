import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mezgebe_sibhat/dependency_injection.dart';
import 'package:mezgebe_sibhat/features/songs/data/repository/song_repo_impl.dart';
import 'package:mezgebe_sibhat/features/songs/domain/repository/song_repo.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/pages/home_page.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage>
    with TickerProviderStateMixin {
  static const _gold = Color(0xFFC9A24B);
  static const _goldLight = Color(0xFFE8CF8E);

  // Entrance animation (logo, title, subtitle, footer)
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  // Slow breathing glow behind the logo
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
  );
  late final Animation<double> _logoScale = Tween<double>(begin: 0.8, end: 1)
      .animate(
        CurvedAnimation(
          parent: _intro,
          curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
        ),
      );
  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
  );
  late final Animation<Offset> _titleSlide =
      Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _intro,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
        ),
      );
  late final Animation<double> _footerFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
  );

  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _glow.repeat(reverse: true);
    _initialize();
  }

  @override
  void dispose() {
    _intro.dispose();
    _glow.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (_hasError) setState(() => _hasError = false);

    try {
      // Let Flutter paint the first frame before doing any heavy work.
      await Future.delayed(Duration.zero);

      final repo = sl<SongRepository>() as SongRepoImpl;

      // Run the real work and a minimum display time together, so the
      // intro animation always finishes nicely but we never wait longer
      // than necessary.
      await Future.wait([
        repo.initializeServers(),
        Future.delayed(const Duration(milliseconds: 2200)),
      ]);

      if (!mounted) return;

      context.read<SongBloc>().add(LoadSongsEvent());

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final bgColors = isDark
        ? const [Color(0xFF1B1710), Color(0xFF121212), Color(0xFF0A0A0A)]
        : const [Color(0xFFFFFBF2), Color(0xFFFFFFFF), Color(0xFFF6EFE0)];
    final titleColor = isDark ? Colors.white : const Color(0xFF1C1A16);
    final mutedColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ---------- Logo with glow ----------
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: AnimatedBuilder(
                    animation: _glow,
                    builder: (context, child) {
                      final t = Curves.easeInOut.transform(_glow.value);
                      return Container(
                        width: 156,
                        height: 156,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.white,
                          border: Border.all(
                            color: _gold.withOpacity(0.35 + 0.25 * t),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withOpacity(
                                (isDark ? 0.22 : 0.18) + 0.14 * t,
                              ),
                              blurRadius: 40 + 24 * t,
                              spreadRadius: 2 + 6 * t,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Image.asset(
                        'assets/mezgebe_sibhat.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ---------- Title ----------
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [_gold, _goldLight, _gold],
                        ).createShader(rect),
                        child: Text(
                          'መዝገበ ስብሐት',
                          textAlign: TextAlign.center,
                          style: textTheme.displayLarge?.copyWith(
                            fontSize: 38,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white, // masked by the gradient
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GoldDivider(color: _gold),
                      const SizedBox(height: 14),
                      Text(
                        'Mezgebe Sibhat',
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                          color: titleColor.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ---------- Footer: progress / error ----------
              FadeTransition(
                opacity: _footerFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(56, 0, 56, 44),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _hasError
                        ? _ErrorView(
                            key: const ValueKey('error'),
                            color: mutedColor,
                            accent: _gold,
                            onRetry: _initialize,
                          )
                        : Column(
                            key: const ValueKey('loading'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  minHeight: 3,
                                  color: _gold,
                                  backgroundColor: _gold.withOpacity(0.15),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Preparing your library…',
                                style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin gold line – diamond – thin gold line.
class _GoldDivider extends StatelessWidget {
  final Color color;
  const _GoldDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    Widget line(bool fadeLeft) => Container(
      width: 44,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: fadeLeft
              ? [color.withOpacity(0), color]
              : [color, color.withOpacity(0)],
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(true),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 0.785398, // 45°
          child: Container(width: 6, height: 6, color: color),
        ),
        const SizedBox(width: 10),
        line(false),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Color color;
  final Color accent;
  final VoidCallback onRetry;

  const _ErrorView({
    super.key,
    required this.color,
    required this.accent,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Something went wrong while loading.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: color),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent.withOpacity(0.6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          ),
          child: const Text('Try again'),
        ),
      ],
    );
  }
}
