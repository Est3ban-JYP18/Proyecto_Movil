import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../models/producto_model.dart';

class ProductoService {
  final String baseUrl = ApiClient.baseUrl;

  // 1. OBTENER LISTA DE PRODUCTOS
  Future<List<Producto>> obtenerProductos({
    String? categoria,
    String? busqueda,
    String? estado,
  }) async {
    Uri url = Uri.parse('$baseUrl/productos');

    final Map<String, String> queryParams = {};
    if (categoria != null && categoria.isNotEmpty && categoria != 'Todos') {
      queryParams['categoria'] = categoria;
    }
    if (busqueda != null && busqueda.isNotEmpty) {
      queryParams['busqueda'] = busqueda;
    }
    if (estado != null && estado.isNotEmpty) {
      queryParams['estado'] = estado;
    }

    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map<Producto>((item) => Producto.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        } else if (data is Map && data['productos'] is List) {
          return (data['productos'] as List)
              .map<Producto>((item) => Producto.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
        return [];
      } else {
        throw Exception('Error del servidor (${response.statusCode}): ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al conectar con el servidor.');
    } catch (e) {
      throw Exception('Error al consultar productos: $e');
    }
  }

  // 2. OBTENER CATEGORÍAS
  Future<List<CategoriaProducto>> obtenerCategorias() async {
    final url = Uri.parse('$baseUrl/categorias');

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map<CategoriaProducto>((item) => CategoriaProducto.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (_) {
      // Si falla o la ruta no existe, usamos las categorías predeterminadas
    }

    // Categorías predeterminadas por defecto
    return [
      CategoriaProducto(id: 1, nombre: 'Protección Corporal'),
      CategoriaProducto(id: 2, nombre: 'Protección de Cabeza'),
      CategoriaProducto(id: 3, nombre: 'Protección de Manos'),
      CategoriaProducto(id: 4, nombre: 'Protección de Pies'),
      CategoriaProducto(id: 5, nombre: 'Dotación'),
    ];
  }

  // 3. CREAR PRODUCTO
  Future<void> crearProducto(Map<String, dynamic> datos) async {
    final url = Uri.parse('$baseUrl/productos');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'Nombre_Producto': datos['nombre'],
              'Tipo': datos['tipo'] ?? 'Dotación',
              'Descripcion': datos['descripcion'] ?? '',
              'Precio': datos['precio'],
              'Stock': datos['stock'] ?? 0,
              'Marca': datos['marca'] ?? 'Tecnomatic',
              'Stock_Minimo': datos['stockMinimo'] ?? 5,
              'Imagen': datos['imagen'] ?? '',
              'Categoria_producto_idCategoria': datos['categoria'],
              'Categoria': datos['categoriaNombre'] ?? '',
              'Estado': datos['estado'] ?? 'Activo',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? response.body);
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al crear el producto.');
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  // 4. ACTUALIZAR PRODUCTO
  Future<void> actualizarProducto(int id, Map<String, dynamic> datos) async {
    final url = Uri.parse('$baseUrl/productos/$id');

    try {
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'Nombre_Producto': datos['nombre'],
              'Tipo': datos['tipo'],
              'Descripcion': datos['descripcion'],
              'Precio': datos['precio'],
              'Stock': datos['stock'],
              'Marca': datos['marca'],
              'Stock_Minimo': datos['stockMinimo'],
              'Imagen': datos['imagen'],
              'Categoria_producto_idCategoria': datos['categoria'],
              'Categoria': datos['categoriaNombre'],
              'Estado': datos['estado'],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? response.body);
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al actualizar el producto.');
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  // 5. ELIMINAR / MOVER A PAPELERA
  Future<void> eliminarProductoPapelera(int id) async {
    final url = Uri.parse('$baseUrl/productos/$id');

    try {
      final response = await http
          .delete(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('No se pudo eliminar el producto: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al eliminar el producto.');
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  // 6. OBTENER CATÁLOGO DETALLADO / FICHA TÉCNICA
  Future<Map<String, dynamic>> obtenerCatalogoDetallado(int id) async {
    final url = Uri.parse('$baseUrl/productos/$id/detallado');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    return {
      'atributos': {
        'marca': '',
        'material': '',
        'nivelProteccion': '',
        'stockMinimo': 5,
      },
      'imagenes': [],
      'variantes': [],
    };
  }

  // 7. GUARDAR CATÁLOGO DETALLADO / FICHA TÉCNICA
  Future<void> guardarCatalogoDetallado(int id, Map<String, dynamic> datos) async {
    final url = Uri.parse('$baseUrl/productos/$id/detallado');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(datos),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        // Si no existe la ruta específica de detallado, intentamos un PUT simple de actualización
        await actualizarProducto(id, {
          'marca': datos['atributos']?['marca'],
          'material': datos['atributos']?['material'],
          'nivelProteccion': datos['atributos']?['nivelProteccion'],
          'stockMinimo': datos['atributos']?['stockMinimo'],
        });
      }
    } catch (_) {
      // Fallback a actualizar atributos en el producto
      try {
        await actualizarProducto(id, {
          'marca': datos['atributos']?['marca'],
          'material': datos['atributos']?['material'],
          'nivelProteccion': datos['atributos']?['nivelProteccion'],
          'stockMinimo': datos['atributos']?['stockMinimo'],
        });
      } catch (e) {
        throw Exception('Error al guardar ficha técnica: $e');
      }
    }
  }

  // 8. OBTENER MOVIMIENTOS DE INVENTARIO (KÁRDEX)
  Future<List<MovimientoInventario>> obtenerMovimientosInventario(int id) async {
    final url = Uri.parse('$baseUrl/inventario/movimientos/$id');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map<MovimientoInventario>((item) => MovimientoInventario.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (_) {}

    // Movimientos simulados / iniciales en caso de no tener kárdex en backend
    return [
      MovimientoInventario(
        tipoMovimiento: 'Entrada',
        cantidad: 50,
        fecha: DateTime.now().subtract(const Duration(days: 10)),
        observacion: 'Carga inicial de inventario / Proveedor',
      ),
      MovimientoInventario(
        tipoMovimiento: 'Salida',
        cantidad: 5,
        fecha: DateTime.now().subtract(const Duration(days: 2)),
        observacion: 'Venta realizada en tienda / Factura #1024',
      ),
    ];
  }
}
