import 'package:flutter/foundation.dart';

class ApiClient {
  // IP actual de tu computador en la red local (para celulares/dispositivos físicos)
  static String mobileIp = '10.1.196.116';
  static int port = 3001;

  static String get baseUrl {
    // Si la aplicación se ejecuta en Google Chrome (Web) en la misma computadora
    if (kIsWeb) {
      return 'http://localhost:$port';
    }

    // Si se ejecuta en un celular físico o emulador conectado a la misma red
    return 'http://$mobileIp:$port';
  }
}