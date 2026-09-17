import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../models/usuario_model.dart';

class AuthService {
  // Inicio de sesión
  Future<Usuario> login(String correo, String contrasena) async {
    final baseUrl = ApiClient.baseUrl;

    try {
      // 1. Intentar endpoint /login con soporte de token JWT
      final responseLogin = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo.trim(),
          'contrasena': contrasena,
        }),
      );

      if (responseLogin.statusCode == 200) {
        final data = jsonDecode(responseLogin.body);
        final usuario = Usuario.fromJson(data['usuario'] ?? data);
        final token = data['token']?.toString();
        SessionManager().iniciarSesion(usuario, token: token);
        return usuario;
      }

      // 2. Fallback a /usuarios/login
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Correo': correo.trim(),
          'Contrasena': contrasena,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final usuario = Usuario.fromJson(data['usuario'] ?? data);
        final token = data['token']?.toString();
        SessionManager().iniciarSesion(usuario, token: token);
        return usuario;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'Credenciales incorrectas');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('SocketException') && !e.toString().contains('ClientException')) {
        rethrow;
      }
      throw Exception('No se pudo conectar al servidor ($baseUrl). Verifica que MySQL y el backend estén encendidos.');
    }
  }

  // Registro de nuevos usuarios (Rol 3 = Cliente)
  Future<Map<String, dynamic>> registrar({
    required String nombres,
    required String apellidos,
    required String correo,
    required String contrasena,
  }) async {
    final baseUrl = ApiClient.baseUrl;
    final url = Uri.parse('$baseUrl/registro');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombres': nombres.trim(),
          'apellidos': apellidos.trim(),
          'correo': correo.trim().toLowerCase(),
          'contrasena': contrasena,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = data['token']?.toString();
        if (data['usuario'] != null) {
          final usuario = Usuario.fromJson(data['usuario']);
          SessionManager().iniciarSesion(usuario, token: token);
        }
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception(data['message'] ?? data['error'] ?? 'Error al registrar la cuenta');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('SocketException') && !e.toString().contains('ClientException')) {
        rethrow;
      }
      throw Exception('No se pudo conectar al servidor ($baseUrl). Verifica tu conexión de red o backend.');
    }
  }
}