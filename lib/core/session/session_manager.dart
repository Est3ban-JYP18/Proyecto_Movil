import '../../models/usuario_model.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  bool isLoggedIn = false;
  Usuario? usuarioActual;

  void iniciarSesion(Usuario usuario) {
    isLoggedIn = true;
    usuarioActual = usuario;
  }

  void cerrarSesion() {
    isLoggedIn = false;
    usuarioActual = null;
  }
}