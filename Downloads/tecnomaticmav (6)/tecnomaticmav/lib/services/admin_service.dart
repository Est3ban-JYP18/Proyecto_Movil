import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../models/devolucion_model.dart';
import '../models/pedido_model.dart';
import '../models/usuario_model.dart';

class AdminService {
  // ============================================================
  // GESTIÓN DE USUARIOS
  // ============================================================

  Future<List<Usuario>> getUsuarios() async {
    final url = Uri.parse('${ApiClient.baseUrl}/admin/usuarios');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Usuario.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener usuarios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar con el servidor de usuarios: $e');
    }
  }

  Future<bool> crearUsuario({
    required String nombres,
    required String apellidos,
    required String correo,
    required String contrasena,
    required int rol,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/admin/usuarios');

    try {
      final response = await http.post(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode({
          'nombres': nombres.trim(),
          'apellidos': apellidos.trim(),
          'correo': correo.trim().toLowerCase(),
          'contrasena': contrasena,
          'rol': rol,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? err['message'] ?? 'No se pudo crear el usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión al crear usuario: $e');
    }
  }

  Future<bool> actualizarUsuario(
    int id, {
    required String nombres,
    required String apellidos,
    required String correo,
    String? contrasena,
    required int rol,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/admin/usuarios/$id');

    try {
      final response = await http.put(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode({
          'nombres': nombres.trim(),
          'apellidos': apellidos.trim(),
          'correo': correo.trim().toLowerCase(),
          if (contrasena != null && contrasena.isNotEmpty) 'contrasena': contrasena,
          'rol': rol,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? err['message'] ?? 'No se pudo actualizar el usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión al actualizar usuario: $e');
    }
  }

  Future<bool> eliminarUsuario(int id) async {
    final url = Uri.parse('${ApiClient.baseUrl}/admin/usuarios/$id');

    try {
      final response = await http.delete(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        return true;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? err['message'] ?? 'No se pudo eliminar el usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión al eliminar usuario: $e');
    }
  }

  // ============================================================
  // GESTIÓN DE PEDIDOS Y FACTURACIÓN
  // ============================================================

  Future<List<PedidoModel>> getPedidos() async {
    final url = Uri.parse('${ApiClient.baseUrl}/facturas');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => PedidoModel.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener pedidos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al sincronizar pedidos con MySQL: $e');
    }
  }

  Future<bool> actualizarEstadoPedido(int idFactura, String nuevoEstado) async {
    final url = Uri.parse('${ApiClient.baseUrl}/facturas/$idFactura/estado');

    try {
      final response = await http.put(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode({'estado': nuevoEstado}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? err['message'] ?? 'No se pudo actualizar el estado');
      }
    } catch (e) {
      throw Exception('Error al actualizar estado del pedido: $e');
    }
  }

  Future<bool> eliminarPedido(int idFactura) async {
    final url = Uri.parse('${ApiClient.baseUrl}/facturas/$idFactura');

    try {
      final response = await http.delete(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        return true;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? err['message'] ?? 'No se pudo eliminar el pedido');
      }
    } catch (e) {
      throw Exception('Error al eliminar pedido: $e');
    }
  }

  // ============================================================
  // GESTIÓN DE DEVOLUCIONES
  // ============================================================

  Future<List<DevolucionModel>> getDevoluciones() async {
    final url = Uri.parse('${ApiClient.baseUrl}/devoluciones');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => DevolucionModel.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener devoluciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al sincronizar devoluciones: $e');
    }
  }

  Future<bool> aprobarDevolucion(int id, {String? comentarios, String? cupon}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/devoluciones/$id/aprobar');

    try {
      final response = await http.put(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode({
          'comentariosAdmin': comentarios ?? 'Aprobada por administración',
          'codigoCupon': cupon ?? 'CUPON-DEV-$id',
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? err['message'] ?? 'No se pudo aprobar la devolución');
      }
    } catch (e) {
      throw Exception('Error al aprobar devolución: $e');
    }
  }

  Future<bool> rechazarDevolucion(int id, {String? comentarios}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/devoluciones/$id/rechazar');

    try {
      final response = await http.put(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode({
          'comentariosAdmin': comentarios ?? 'Rechazada por administración',
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? err['message'] ?? 'No se pudo rechazar la devolución');
      }
    } catch (e) {
      throw Exception('Error al rechazar devolución: $e');
    }
  }
}
