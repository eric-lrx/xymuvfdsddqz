import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool> connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => connectionStatusController.stream;

  ConnectivityService() {
    // Écouter les changements de connectivité
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      connectionStatusController.add(_getStatusFromResult(result));
    });
  }

  // Vérifier la connectivité actuelle
  Future<bool> checkConnectivity() async {
    final ConnectivityResult result = await _connectivity.checkConnectivity();
    return _getStatusFromResult(result);
  }

  // Convertir le résultat en booléen
  bool _getStatusFromResult(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  void dispose() {
    connectionStatusController.close();
  }
}