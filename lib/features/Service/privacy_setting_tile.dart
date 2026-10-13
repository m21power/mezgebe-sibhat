import 'package:flutter/material.dart';
import 'package:mezgebe_sibhat/features/Service/adService.dart';

class PrivacySettingsTile extends StatelessWidget {
  const PrivacySettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdService().isPrivacyOptionsRequired(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();

        return ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy settings'),
          onTap: AdService().showPrivacyOptionsForm,
        );
      },
    );
  }
}
