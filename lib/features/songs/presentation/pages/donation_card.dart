import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

    return Column(
      children: [
        const Text(
          "💖 Support This App",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Text(
          "Your support helps us cover the server costs required to keep this app running for thousands of users worldwide.\nYour support helps keep it alive and free 🙏",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onInternationalTap,
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.public, size: 20),
                const SizedBox(width: 10),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Global 🌍",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text("Outside Ethiopia", style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onLocalTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 10),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Ethiopia 🇪🇹",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text("For local users", style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          "Every contribution matters ❤️",
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}

class DonationSheet extends StatelessWidget {
  const DonationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: DonationCard(
                    onInternationalTap: () {
                      openLink(
                        "https://buy.polar.sh/polar_cl_nk8kUL2o9VgAp9hro86ae1Qa5VW1J4kiIp9Yy3YQtsc",
                      );
                    },
                    onLocalTap: () {
                      openLink("https://www.gurshaplus.com/mesay");
                    },
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

Future<void> openLink(String url) async {
  final Uri uri = Uri.parse(url);

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not launch $url');
  }
}
