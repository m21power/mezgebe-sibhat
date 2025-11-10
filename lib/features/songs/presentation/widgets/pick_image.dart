// Inside your State class
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

final ImagePicker _picker = ImagePicker();

Future<String> pickImage(BuildContext context) async {
  final theme = Theme.of(context);
  final XFile? image = await showDialog<XFile>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
      title: Row(
        children: [
          Icon(Icons.upload_file, color: theme.primaryColor),
          const SizedBox(width: 10),
          Text('Select Image', style: theme.textTheme.titleLarge),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await _picker.pickImage(
                source: ImageSource.gallery,
              );
              Navigator.pop(context, picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.photo, color: theme.primaryColor),
                  const SizedBox(width: 10),
                  Text('Gallery', style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await _picker.pickImage(
                source: ImageSource.camera,
              );
              Navigator.pop(context, picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.camera_alt, color: theme.primaryColor),
                  const SizedBox(width: 10),
                  Text('Camera', style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  if (image != null) {
    return image.path;
  } else {
    return '';
  }
}

Future<bool?> showConfirmImageDialog(BuildContext context, String imagePath) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Confirm Upload"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Do you want to save this image?"),
          const SizedBox(height: 10),
          Image.file(
            File(imagePath),
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(context, false),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.close,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text("Cancel"),
            ],
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.save,
                size: 18,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              const SizedBox(width: 8),
              const Text("Save"),
            ],
          ),
        ),
      ],
    ),
  );
}
