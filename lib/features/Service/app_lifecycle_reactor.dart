import 'package:flutter/widgets.dart';
import 'package:mezgebe_sibhat/features/Service/adService.dart';

class AppLifecycleReactor with WidgetsBindingObserver {
  final AdService _adService;

  bool _wasInBackground = false;

  AppLifecycleReactor({AdService? adService})
    : _adService = adService ?? AdService();

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
    }

    if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;

      _adService.showAppOpenAdIfAvailable();
    }
  }
}
