import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/pages/donation_card.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../Service/adService.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String appVersion = '';

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _bannerAd = AdService().createBanner((ad) {
      setState(() {
        _isAdLoaded = true; // Set flag to true only when loaded
      });
    });
    // Rebuild UI as the user types
    _feedbackController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => appVersion = info.version);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1226)
          : const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const DonationSheet(),
            ),
          ),
        ],
      ),
      body: BlocListener<SongBloc, SongState>(
        listener: (context, songState) {
          if (songState is FeedbackSubmittedState) {
            _showSuccess();
          } else if (songState is FeedbackSubmissionFailedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(songState.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<SongBloc, SongState>(
          builder: (context, songState) {
            final isLoading = songState is SubmitFeedbackLoadingState;

            // Logic check: Enable if text is not empty OR an image is selected
            final bool hasText = _feedbackController.text.trim().isNotEmpty;
            final bool hasImage = _selectedImage != null;
            final bool isButtonDisabled = isLoading || !(hasText || hasImage);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // --- HEADER ---
                  _buildHeader(isDark, theme),

                  const SizedBox(height: 30),

                  // --- DEDICATION ---
                  _buildDedicationCard(isDark),

                  const SizedBox(height: 30),

                  // --- FEEDBACK FORM ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "  Report a Bug",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _feedbackController,
                            hint:
                                "Describe the issue (Optional if image attached)...",
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                          _buildImagePicker(theme),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: isButtonDisabled
                                  ? null
                                  : () => _submit(songState),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: theme.primaryColor
                                    .withOpacity(0.2),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Send Report 🚀",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
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
                  color: isDark
                      ? const Color(0xFF161B33)
                      : const Color(0xFFF0F2F8),
                  // 4. Subtle border to separate it from the content
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                      width: 0.5,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildHeader(bool isDark, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E264F), const Color(0xFF0F1226)]
              : [Colors.indigo.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          Image.asset('assets/icon2.png', height: 80),
          const SizedBox(height: 16),
          Text(
            'መዝገበ ስብሐት',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Ads help us cover the essential server costs required to keep this app running, but your personal support is deeply appreciated. Together, we keep these teachings easily accessible for all. 🙏",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDedicationCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        "This application is dedicated to every soul who desires to learn the sacred teachings of the Ethiopian Orthodox Tewahedo Church.\n\nAll glory belongs to God Almighty.\n\nSpecial thanks to all who preserved these teachings.\n\n© 2026 Mezgebe Sibhat",
        style: TextStyle(
          height: 1.6,
          color: isDark ? Colors.white60 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            final XFile? img = await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            );
            if (img != null) {
              setState(() => _selectedImage = File(img.path));
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.add_a_photo_rounded, color: theme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  _selectedImage == null
                      ? "Attach Screenshot"
                      : "Change Screenshot",
                ),
              ],
            ),
          ),
        ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _submit(SongState songState) {
    if (!songState.connectionEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No internet connection"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    context.read<SongBloc>().add(
      SubmitFeedbackEvent(
        feedback: _feedbackController.text.trim().isEmpty
            ? "Image Report"
            : _feedbackController.text.trim(),
        fullname: "Mezgebe Sibhat User",
        imageFile: _selectedImage,
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback sent!'),
        backgroundColor: Colors.green,
      ),
    );
    _feedbackController.clear();
    setState(() => _selectedImage = null);
  }
}
