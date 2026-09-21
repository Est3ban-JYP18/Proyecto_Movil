import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../models/producto_model.dart';

class ClienteService {
  // GET /productos (con soporte para filtro por categoría)
  Future<List<Producto>> obtenerProductos({String? categoria}) async {
    Uri url = Uri.parse('${ApiClient.baseUrl}/productos');
    
    // Si se pasa una categoría, se adjunta como Query Parameter
    if (categoria != null && categoria.isNotEmpty && categoria != 'Todos') {
      url = Uri.parse('${ApiClient.baseUrl}/productos?categoria=$categoria');
    }

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Producto.fromJson(item)).toList();
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión con el servidor: $e');
    }
  }

  // GET /productos/:id - Obtener un detalle específico
  Future<Producto> obtenerProductoPorId(int id) async {
    final url = Uri.parse('${ApiClient.baseUrl}/productos/$id');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        return Producto.fromJson(body);
      } else {
        throw Exception('Error al obtener detalle del producto');
      }
    } catch (e) {
      throw Exception('Error de conexión con el servidor: $e');
    }
  }
}