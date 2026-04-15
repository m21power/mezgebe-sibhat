import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationSheet extends StatelessWidget {
  const DonationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B33) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handlebar
              Container(
                width: 45,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: DonationCard(
                    onInternationalTap: () => openLink(
                      "https://buy.polar.sh/polar_cl_nk8kUL2o9VgAp9hro86ae1Qa5VW1J4kiIp9Yy3YQtsc",
                    ),
                    onLocalTap: () =>
                        openLink("https://www.gurshaplus.com/mesay"),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DonationCard extends StatelessWidget {
  final VoidCallback onInternationalTap;
  final VoidCallback onLocalTap;

  const DonationCard({
    super.key,
    required this.onInternationalTap,
    required this.onLocalTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 48),
        const SizedBox(height: 16),
        const Text(
          "Support the Mission",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          "Ads help us cover the essential server costs required to keep this app running, but your personal support is deeply appreciated. Together, we keep these teachings easily accessible for all. 🙏",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 32),

        // Global Support - Gradient Button
        GestureDetector(
          onTap: onInternationalTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.public_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Global Support 🌍",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      "USD / EUR / International",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Local Support - Glass/Outline style
        OutlinedButton(
          onPressed: onLocalTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            side: BorderSide(
              color: theme.primaryColor.withOpacity(0.5),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_rounded, size: 24),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Ethiopia 🇪🇹",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  Text(
                    "Telebirr / Local Banking",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Every contribution matters ❤️",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

Future<void> openLink(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not launch $url');
  }
}
