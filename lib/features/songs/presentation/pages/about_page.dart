// about_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mezgebe_sibhat/features/songs/presentation/bloc/song_bloc.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<SongBloc, SongState>(
          listener: (context, songState) {
            if (songState is FeedbackSubmittedState) {
              _showSuccess(
                _telegramController.text.trim().isEmpty
                    ? 'Not provided'
                    : _telegramController.text.trim(),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 22,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.08),
                          Theme.of(context).primaryColor.withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'መዝገበ ስብሐት',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Treasury of Ethiopian Orthodox Tewahedo Church Teachings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 25),

                        Text(
                          "This application is dedicated to every soul who desires to learn the sacred teachings "
                          "of the Ethiopian Orthodox Tewahedo Church, yet has not had the opportunity to do so.\n\n"
                          "All glory belongs to God Almighty, who inspired and guided this work.\n\n"
                          "We extend gratitude to all fathers, monks, scholars, deacons, and faithful servants "
                          "who preserved the sacred hymns and teachings through generations.\n\n"
                          "Version $appVersion\n© 2025 Mezgebe Sibhat",
                          textAlign: TextAlign.justify,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.7,
                            fontSize: 15,
                            color: theme.textTheme.bodyLarge?.color
                                ?.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
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
                      borderRadius: BorderRadius.circular(18),
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _feedbackController,
                            maxLines: 6,
                            decoration: InputDecoration(
                              labelText: "Describe the issue",
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              filled: true,
                              fillColor: theme.brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.03),
                            ),
                            validator: (v) => v!.trim().isEmpty
                                ? 'Please describe the issue'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _telegramController,
                            decoration: InputDecoration(
                              labelText: "Telegram Username (optional)",
                              prefixText: '@ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              filled: true,
                              fillColor: theme.brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.03),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: Text(
                                    _selectedImage == null
                                        ? "Attach Screenshot"
                                        : "Change Screenshot",
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                  ),
                                ),
                              ),
                              if (_selectedImage != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _selectedImage = null),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          if (_selectedImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (songState.connectionEnabled == false) {
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

                                if (_formKey.currentState!.validate()) {
                                  BlocProvider.of<SongBloc>(context).add(
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: songState is! SubmitFeedbackLoadingState
                                  ? const Text(
                                      "Send Report",
                                      style: TextStyle(fontSize: 16),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
