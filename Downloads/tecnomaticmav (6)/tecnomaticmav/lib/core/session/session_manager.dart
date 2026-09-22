import 'dart:convert';
import '../../models/usuario_model.dart';
import 'storage/session_storage.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;

  SessionManager._internal() {
    _restaurarSesionSiExiste();
  }

  bool isLoggedIn = false;
  Usuario? usuarioActual;
  String? token;

  void _restaurarSesionSiExiste() {
    try {
      final savedToken = PlatformLocalStorage.getItem('token');
      final savedUserStr = PlatformLocalStorage.getItem('usuario');

      if (savedToken != null && savedToken.isNotEmpty) {
        token = savedToken;
      }
      if (savedUserStr != null && savedUserStr.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(savedUserStr);
        usuarioActual = Usuario.fromJson(userMap);
        isLoggedIn = true;
      }
    } catch (_) {}
  }

  void iniciarSesion(Usuario usuario, {String? token}) {
    isLoggedIn = true;
    usuarioActual = usuario;

    // Solo actualizar token si se provee uno válido; no sobreescribir con null
    if (token != null && token.isNotEmpty) {
      this.token = token;
      PlatformLocalStorage.setItem('token', token);
    }

    // Persistir usuario para que coincida con lo esperado en web/localStorage
    try {
      PlatformLocalStorage.setItem('usuario', jsonEncode(usuario.toJson()));
    } catch (_) {}
  }

  void cerrarSesion() {
    isLoggedIn = false;
    usuarioActual = null;
    token = null;

    try {
      PlatformLocalStorage.removeItem('token');
      PlatformLocalStorage.removeItem('usuario');
    } catch (_) {}
  }

  Map<String, String> get authHeaders {
    return {
      'Content-Type': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}