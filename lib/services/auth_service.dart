import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../models/usuario_model.dart';

class AuthService {
  Future<Usuario> login(String correo, String contrasena) async {
    final url = Uri.parse('${ApiClient.baseUrl}/usuarios/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Correo': correo,
          'Contrasena': contrasena,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Si el backend responde con los datos del usuario logueado
        return Usuario.fromJson(data['usuario'] ?? data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Credenciales incorrectas');
      }
    } catch (e) {
      throw Exception('Error al conectar con el servidor: $e');
    }
  }
}