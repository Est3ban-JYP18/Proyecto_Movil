import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../models/devolucion_model.dart';
import '../models/pedido_model.dart';

/// Servicio centralizado para la gestión del historial de pedidos,
/// seguimiento logístico y devoluciones para Administradores y Clientes.
class PedidoService {
  // ============================================================
  // APIS Y MÉTODOS DE HISTORIAL (ADMIN Y CLIENTE)
  // ============================================================

  /// [ADMIN] Obtiene la lista completa de todas las facturas/pedidos registrados.
  Future<List<PedidoModel>> getHistorialAdmin() async {
    final url = Uri.parse('${ApiClient.baseUrl}/facturas');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => PedidoModel.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener facturas de administración (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error al conectar con el servidor: $e');
    }
  }

  /// [CLIENTE] Obtiene el historial de pedidos de un cliente específico.
  Future<List<PedidoModel>> getHistorialCliente(int usuarioId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/mis-pedidos/$usuarioId');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => PedidoModel.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener historial del cliente (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error al conectar con el servidor: $e');
    }
  }

  /// [AMBOS] Obtiene los artículos detallados de un pedido específico.
  Future<List<PedidoDetalleItem>> getDetallePedido(int idFactura) async {
    final url = Uri.parse('${ApiClient.baseUrl}/pedido-detalle/$idFactura');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => PedidoDetalleItem.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener detalles del pedido (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error al consultar detalle del pedido: $e');
    }
  }

  /// [AMBOS] Obtiene el estado de entrega y seguimiento logístico.
  Future<PedidoSeguimiento> getSeguimientoPedido(
    int idFactura, {
    String estadoFallback = 'Pendiente',
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/seguimiento/$idFactura');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PedidoSeguimiento.fromJson(data);
      } else if (response.statusCode == 404) {
        // Aún no hay registro en la tabla Entregas
        return PedidoSeguimiento(
          estadoEntrega: estadoFallback,
          observaciones: 'El pedido está siendo procesado en bodega.',
        );
      } else {
        throw Exception('Error al obtener seguimiento (${response.statusCode})');
      }
    } catch (e) {
      // Fallback seguro si no hay respuesta de red
      return PedidoSeguimiento(
        estadoEntrega: estadoFallback,
        observaciones: 'El pedido se encuentra registrado y en trámite logístico.',
      );
    }
  }

  /// [ADMIN] Actualiza el estado de una factura (Pendiente, Preparando, Enviado, Entregado, Cancelado).
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
      throw Exception('Error de conexión al actualizar estado: $e');
    }
  }

  /// [ADMIN] Elimina un pedido y sus registros asociados (cascada).
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
      throw Exception('Error de conexión al eliminar pedido: $e');
    }
  }

  /// [ADMIN] Obtiene la cantidad de ítems del catálogo para las métricas.
  Future<int> getCantidadProductos() async {
    final url = Uri.parse('${ApiClient.baseUrl}/productos');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.length;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ============================================================
  // APIS Y MÉTODOS DE DEVOLUCIONES
  // ============================================================

  /// [ADMIN] Obtiene todas las devoluciones solicitadas en la plataforma.
  Future<List<DevolucionModel>> getDevolucionesAdmin() async {
    final url = Uri.parse('${ApiClient.baseUrl}/devoluciones');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => DevolucionModel.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener devoluciones (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error al sincronizar devoluciones: $e');
    }
  }

  /// [CLIENTE] Obtiene las devoluciones pertenecientes al usuario logueado.
  Future<List<DevolucionModel>> getDevolucionesCliente(int usuarioId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/mis-devoluciones/$usuarioId');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => DevolucionModel.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener tus devoluciones (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error al sincronizar tus devoluciones: $e');
    }
  }

  /// [ADMIN] Aprueba una devolución solicitada.
  Future<bool> aprobarDevolucion(int idDevolucion, {String? comentarios, String? cupon}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/devoluciones/$idDevolucion/aprobar');

    try {
      final response = await http.put(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode({
          'comentariosAdmin': comentarios ?? 'Aprobada por administración',
          'codigoCupon': cupon ?? 'CUPON-DEV-$idDevolucion',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al aprobar devolución: $e');
    }
  }

  /// [ADMIN] Rechaza una devolución solicitada.
  Future<bool> rechazarDevolucion(int idDevolucion, {String? comentarios}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/devoluciones/$idDevolucion/rechazar');

    try {
      final response = await http.put(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode({
          'comentariosAdmin': comentarios ?? 'Rechazada por administración',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al rechazar devolución: $e');
    }
  }

  /// [CLIENTE] Registra una nueva solicitud de devolución.
  Future<bool> crearSolicitudDevolucion({
    required int facturaId,
    required int productoId,
    required int usuarioId,
    required int cantidad,
    required String motivo,
    String motivoCategoria = 'Defectuoso',
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/devoluciones');

    try {
      final response = await http.post(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode({
          'facturaId': facturaId,
          'productoId': productoId,
          'usuarioId': usuarioId,
          'cantidad': cantidad,
          'motivo': motivo,
          'motivoCategoria': motivoCategoria,
          'metodoReembolso': 'MetodoOriginal',
          'metodoRetorno': 'EntregaSucursal',
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al enviar solicitud de devolución: $e');
    }
  }
}
