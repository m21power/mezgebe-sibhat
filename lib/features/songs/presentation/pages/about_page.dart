// about_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/pages/donation_card.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final _feedbackController = TextEditingController();
  final _telegramController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String appVersion = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showSuccess(String username) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          username == 'Not provided'
              ? 'Thank you for your feedback!'
              : 'Thank you! @$username, for your report! We will get back to you soon.',
        ),
        backgroundColor: Colors.green,
      ),
    );
    _resetForm();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _resetForm() {
    _feedbackController.clear();
    _telegramController.clear();
    setState(() => _selectedImage = null);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('About'),
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
          ],
        ),
        body: BlocConsumer<SongBloc, SongState>(
          listener: (context, songState) {
            if (songState is FeedbackSubmittedState) {
              _showSuccess(
                _telegramController.text.trim().isEmpty
                    ? 'Not provided'
                    : _telegramController.text.trim(),
              );

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const DonationSheet(),
              );
            } else if (songState is FeedbackSubmissionFailedState) {
              _showError(songState.message);
            }
          },
          builder: (context, songState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🌟 HEADER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withOpacity(0.15),
                          theme.primaryColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.auto_awesome, size: 40),
                        const SizedBox(height: 10),

                        Text(
                          'መዝገበ ስብሐት',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Treasury of Ethiopian Orthodox Tewahedo Church Teachings',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),

                        const SizedBox(height: 20),

                        Text(
                          "Built to help everyone access sacred teachings.\n\n"
                          "Version $appVersion",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const SizedBox(height: 30),

                  Text(
                    "About This App",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "This application is dedicated to every soul who desires to learn the sacred teachings "
                    "of the Ethiopian Orthodox Tewahedo Church.\n\n"
                    "All glory belongs to God Almighty.\n\n"
                    "Special thanks to all who preserved these teachings.\n\n"
                    "© 2025 Mezgebe Sibhat",
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "Report a Bug or Contact Us",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// TITLE
                          Row(
                            children: const [
                              Icon(Icons.bug_report, size: 22),
                              SizedBox(width: 8),
                              Text(
                                "Send Feedback",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// MESSAGE FIELD
                          TextFormField(
                            controller: _feedbackController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: "Describe the issue...",
                              prefixIcon: const Icon(Icons.edit_note),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Required' : null,
                          ),

                          const SizedBox(height: 16),

                          /// TELEGRAM FIELD
                          TextFormField(
                            controller: _telegramController,
                            decoration: InputDecoration(
                              hintText: "Telegram username (optional)",
                              prefixIcon: const Icon(Icons.telegram),
                              prefixText: '@ ',
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// IMAGE PICKER
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedImage == null
                                        ? "Attach Screenshot"
                                        : "Change Screenshot",
                                  ),
                                ],
                              ),
                            ),
                          ),

                          /// IMAGE PREVIEW
                          if (_selectedImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      _selectedImage!,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  /// REMOVE BUTTON
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedImage = null),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          /// SUBMIT BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (!songState.connectionEnabled) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("No internet connection"),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                if (_formKey.currentState!.validate()) {
                                  context.read<SongBloc>().add(
                                    SubmitFeedbackEvent(
                                      feedback: _feedbackController.text.trim(),
                                      fullname: _telegramController.text.trim(),
                                      imageFile: _selectedImage,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: songState is! SubmitFeedbackLoadingState
                                  ? const Text(
                                      "Send Report 🚀",
                                      style: TextStyle(fontSize: 16),
                                    )
                                  : const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
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
    );
  }
}
