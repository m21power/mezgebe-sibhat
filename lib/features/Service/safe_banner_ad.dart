import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mezgebe_sibhat/features/Service/adService.dart';

class SafeBannerAd extends StatefulWidget {
  const SafeBannerAd({super.key});

  @override
  State<SafeBannerAd> createState() => _SafeBannerAdState();
}

class _SafeBannerAdState extends State<SafeBannerAd> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    AdService().adsReady.addListener(_tryLoad);
    _tryLoad();
  }

  void _tryLoad() {
    if (_banner != null || !AdService().adsReady.value) return;

    _banner = AdService().createBanner((ad) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    AdService().adsReady.removeListener(_tryLoad);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) return const SizedBox.shrink();

    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
