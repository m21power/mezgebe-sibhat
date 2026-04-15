// Inside your State class
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

final ImagePicker _picker = ImagePicker();

Future<String> pickImage(BuildContext context) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final XFile? image = await showDialog<XFile>(
    context: context,
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Adds premium blur
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(20),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                color: theme.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Book Page',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture a photo or choose from gallery to follow along.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPickerOption(
              theme: theme,
              icon: Icons.camera_enhance_rounded,
              label: 'Take Photo',
              onTap: () async => Navigator.pop(
                context,
                await _picker.pickImage(source: ImageSource.camera),
              ),
            ),
            const SizedBox(height: 12),
            _buildPickerOption(
              theme: theme,
              icon: Icons.grid_view_rounded,
              label: 'From Gallery',
              onTap: () async => Navigator.pop(
                context,
                await _picker.pickImage(source: ImageSource.gallery),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return image?.path ?? '';
}

Widget _buildPickerOption({
  required ThemeData theme,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
        ],
      ),
    ),
  );
}

Future<bool?> showConfirmImageDialog(BuildContext context, String imagePath) {
  final theme = Theme.of(context);

  return showDialog<bool>(
    context: context,
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding: EdgeInsets.zero, // Clean edge-to-edge preview
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Preview Header
            Container(
              height: 250,
              width: double.maxFinite,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                image: DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    "Looks Good?",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This image will be saved for this specific audio segment.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            "Discard",
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Save Image",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
  );
}
