import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

final ImagePicker _picker = ImagePicker();

// ---------------------------------------------------------------------
// Small design helpers
// ---------------------------------------------------------------------
Color _shade(Color c, double delta) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + delta).clamp(0.0, 1.0)).toColor();
}

LinearGradient _brandGradient(ThemeData theme) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_shade(theme.primaryColor, 0.10), _shade(theme.primaryColor, -0.08)],
);

// =====================================================================
// 1. SOURCE PICKER  (bottom sheet)
// =====================================================================
/// Returns the picked image path, or '' if cancelled.
Future<String> pickImage(BuildContext context) async {
  final XFile? image = await showModalBottomSheet<XFile>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => const _PickSourceSheet(),
  );
  return image?.path ?? '';
}

class _PickSourceSheet extends StatefulWidget {
  const _PickSourceSheet();

  @override
  State<_PickSourceSheet> createState() => _PickSourceSheetState();
}

class _PickSourceSheetState extends State<_PickSourceSheet> {
  ImageSource? _active; // which option is currently opening

  Future<void> _pick(ImageSource source) async {
    if (_active != null) return;
    HapticFeedback.selectionClick();
    setState(() => _active = source);

    XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2400,
      );
    } catch (_) {
      file = null;
    }
    if (!mounted) return;
    Navigator.pop(context, file);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(22, 12, 22, 20 + bottomInset),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF16213E) : Colors.white)
                .withOpacity(0.96),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(isDark ? 0.12 : 0.8),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.hintColor.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 22),

              // Glowing icon badge
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: _brandGradient(theme),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Add Book Page',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add the page you are listening to,\nso you can read along.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              _SourceCard(
                icon: Icons.photo_camera_rounded,
                title: 'Take Photo',
                subtitle: 'Capture the page with your camera',
                loading: _active == ImageSource.camera,
                disabled: _active != null && _active != ImageSource.camera,
                onTap: () => _pick(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _SourceCard(
                icon: Icons.photo_library_rounded,
                title: 'From Gallery',
                subtitle: 'Choose an existing photo',
                loading: _active == ImageSource.gallery,
                disabled: _active != null && _active != ImageSource.gallery,
                onTap: () => _pick(ImageSource.gallery),
              ),
              const SizedBox(height: 18),

              // Tip
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 15,
                    color: theme.primaryColor.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Tip: good lighting and a flat page give the clearest result.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _active == null
                    ? () => Navigator.pop(context)
                    : null,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w600,
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

class _SourceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
    this.disabled = false,
  });

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.disabled ? 0.4 : 1,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.disabled ? null : widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : theme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.primaryColor.withOpacity(_pressed ? 0.5 : 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _brandGradient(theme),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                widget.loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: theme.primaryColor,
                        ),
                      )
                    : Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: theme.hintColor,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// 2. CONFIRM DIALOG
// =====================================================================
/// Returns true = save, false/null = discard.
Future<bool?> showConfirmImageDialog(BuildContext context, String imagePath) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => _ConfirmImageDialog(imagePath: imagePath),
  );
}

class _ConfirmImageDialog extends StatelessWidget {
  final String imagePath;
  const _ConfirmImageDialog({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.10 : 0.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------- Preview ----------
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred ambient backdrop made from the photo itself
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Image.file(File(imagePath), fit: BoxFit.cover),
                      ),
                      Container(color: Colors.black.withOpacity(0.35)),

                      // The full page, never cropped
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      // "Preview" glass chip
                      Positioned(
                        top: 14,
                        left: 14,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              color: Colors.black.withOpacity(0.35),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Preview',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------- Text + actions ----------
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  child: Column(
                    children: [
                      Text(
                        'Looks good?',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This image will be saved for this specific audio segment.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                side: BorderSide(
                                  color: theme.hintColor.withOpacity(0.35),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Discard',
                                style: TextStyle(
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: _GradientButton(
                              label: 'Save Image',
                              icon: Icons.check_rounded,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(context, true);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: _brandGradient(theme),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
