import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';
import '../models/usuario_model.dart';

class AdminService {
  final String baseUrl = ApiClient.baseUrl;

  // CONSULTAR
  Future<List<Usuario>> obtenerUsuarios() async {
    final url = Uri.parse('$baseUrl/admin/usuarios');

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is! List) {
          throw Exception(
            'El servidor no devolvió una lista de usuarios',
          );
        }

        return data
            .map<Usuario>(
              (json) => Usuario.fromJson(
                Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      }

      throw Exception(
        'El servidor respondió con código ${response.statusCode}',
      );
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. '
        'El celular no pudo conectarse al servidor.',
      );
    } catch (e) {
      throw Exception('Error al consultar usuarios: $e');
    }
  }

  // REGISTRAR
  Future<void> crearUsuario({
    required String nombres,
    required String apellidos,
    required String correo,
    required String contrasena,
    required int rol,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/admin/usuarios'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'nombres': nombres,
            'apellidos': apellidos,
            'correo': correo,
            'contrasena': contrasena,
            'rol': rol,
          }),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode != 201) {
      throw Exception(
        'No se pudo registrar el usuario: ${response.body}',
      );
    }
  }

  // EDITAR
  Future<void> actualizarUsuario({
    required int id,
    required String nombres,
    required String apellidos,
    required String correo,
    required int rol,
    String? contrasena,
  }) async {
    final Map<String, dynamic> datos = {
      'nombres': nombres,
      'apellidos': apellidos,
      'correo': correo,
      'rol': rol,
    };

    if (contrasena != null && contrasena.isNotEmpty) {
      datos['contrasena'] = contrasena;
    }

    final response = await http
        .put(
          Uri.parse('$baseUrl/admin/usuarios/$id'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(datos),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo actualizar el usuario: ${response.body}',
      );
    }
  }

  // ELIMINAR
  Future<void> eliminarUsuario(int id) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/admin/usuarios/$id'),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo eliminar el usuario: ${response.body}',
      );
    }
  }
}