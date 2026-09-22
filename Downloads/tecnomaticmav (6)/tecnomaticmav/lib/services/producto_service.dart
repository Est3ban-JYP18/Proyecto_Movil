import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../models/producto_model.dart';

class ProductoService {
  // Obtener catálogo completo de productos
  Future<List<Producto>> getProductos({String? categoria}) async {
    String endpoint = '${ApiClient.baseUrl}/admin/productos';
    if (categoria != null && categoria.isNotEmpty && categoria != 'Todas' && categoria != 'Todos') {
      endpoint = '${ApiClient.baseUrl}/productos?categoria=$categoria';
    }

    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: SessionManager().authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Producto.fromJson(json)).toList();
      } else {
        // Fallback a /productos si /admin/productos no está disponible
        final fallbackRes = await http.get(Uri.parse('${ApiClient.baseUrl}/productos'));
        if (fallbackRes.statusCode == 200) {
          final List<dynamic> data = jsonDecode(fallbackRes.body);
          return data.map((json) => Producto.fromJson(json)).toList();
        }
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al sincronizar productos con MySQL: $e');
    }
  }

  // Crear nuevo producto en MySQL
  Future<Map<String, dynamic>> crearProducto(Producto producto) async {
    final url = Uri.parse('${ApiClient.baseUrl}/admin/productos');

    try {
      final response = await http.post(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode({
          'nombre': producto.nombre,
          'tipo': producto.tipo,
          'descripcion': producto.descripcion,
          'precio': producto.precio,
          'imagen': producto.imagen,
          'categoria': producto.categoriaId,
          'estado': producto.estado,
          'stock': producto.stock,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? err['message'] ?? 'Error al crear producto');
      }
    } catch (e) {
      throw Exception('Error de conexión al crear producto: $e');
    }
  }

  // Actualizar producto en MySQL
  Future<Map<String, dynamic>> actualizarProducto(Producto producto) async {
    final url = Uri.parse('${ApiClient.baseUrl}/admin/productos/${producto.id}');

    try {
      final response = await http.put(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode({
          'nombre': producto.nombre,
          'tipo': producto.tipo,
          'descripcion': producto.descripcion,
          'precio': producto.precio,
          'imagen': producto.imagen,
          'categoria': producto.categoriaId,
          'estado': producto.estado,
          'stock': producto.stock,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? err['message'] ?? 'Error al actualizar producto');
      }
    } catch (e) {
      throw Exception('Error de conexión al actualizar producto: $e');
    }
  }

  // Eliminar producto de MySQL (envío a papelera / eliminación)
  Future<bool> eliminarProducto(int id) async {
    final url = Uri.parse('${ApiClient.baseUrl}/admin/productos/$id');

    try {
      final response = await http.delete(
        url,
        headers: SessionManager().authHeaders,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? err['message'] ?? 'Error al eliminar producto');
      }
    } catch (e) {
      throw Exception('Error de conexión al eliminar producto: $e');
    }
  }
}
