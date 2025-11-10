import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onStatusChange;
}

class NetworkInfoImpl implements NetworkInfo {
  late final Future<bool> Function() _checkConnection;
  late final Stream<bool> _statusStream;

  NetworkInfoImpl() {
    if (kIsWeb) {
      final connectivity = Connectivity();
      _checkConnection = () async {
        final result = await connectivity.checkConnectivity();
        return result != ConnectivityResult.none;
      };
      _statusStream = connectivity.onConnectivityChanged.map(
        (result) => result != ConnectivityResult.none,
      );
    } else {
      final connectionChecker = InternetConnectionChecker.createInstance();
      _checkConnection = () => connectionChecker.hasConnection;
      _statusStream = connectionChecker.onStatusChange.map(
        (status) => status == InternetConnectionStatus.connected,
      );
    }
  }

  @override
  Future<bool> get isConnected => _checkConnection();

  @override
  Stream<bool> get onStatusChange => _statusStream;
}
