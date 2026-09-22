import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../core/session/session_manager.dart';
import '../models/pedido_model.dart';

class ContadorService {
  Future<Map<String, dynamic>> getReportesFinancieros() async {
    final url = Uri.parse('${ApiClient.baseUrl}/facturas');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final pedidos = data.map((item) => PedidoModel.fromJson(item)).toList();

        double totalIngresos = 0.0;
        int pagadas = 0;
        int pendientes = 0;
        int canceladas = 0;

        for (final p in pedidos) {
          if (p.estado.toLowerCase() == 'pagada' || p.estado.toLowerCase() == 'entregado') {
            totalIngresos += p.total;
            pagadas++;
          } else if (p.estado.toLowerCase() == 'pendiente' || p.estado.toLowerCase() == 'en proceso') {
            pendientes++;
          } else if (p.estado.toLowerCase() == 'cancelada' || p.estado.toLowerCase() == 'cancelado') {
            canceladas++;
          }
        }

        return {
          'totalIngresos': totalIngresos,
          'totalFacturas': pedidos.length,
          'pagadas': pagadas,
          'pendientes': pendientes,
          'canceladas': canceladas,
          'facturas': pedidos,
        };
      } else {
        throw Exception('Error al obtener reporte financiero: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar con reportes financieros: $e');
    }
  }

  /// Obtiene los recibos de compra directamente desde el backend para el perfil del contador
  Future<List<PedidoModel>> getRecibosContador() async {
    final url = Uri.parse('${ApiClient.baseUrl}/recibos');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => PedidoModel.fromJson(item)).toList();
      } else {
        // Fallback a /facturas si /recibos diera error de ruta antigua
        final fallbackRes = await http.get(Uri.parse('${ApiClient.baseUrl}/facturas'), headers: SessionManager().authHeaders);
        if (fallbackRes.statusCode == 200) {
          final List<dynamic> list = jsonDecode(fallbackRes.body);
          return list.map((item) => PedidoModel.fromJson(item)).toList();
        }
        throw Exception('Error al cargar recibos de compra (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error al consultar recibos de compra: $e');
    }
  }

  /// Actualiza el estado de un recibo desde el perfil del contador
  Future<bool> actualizarEstadoRecibo(int idFactura, String nuevoEstado) async {
    final url = Uri.parse('${ApiClient.baseUrl}/recibos/$idFactura/estado');

    try {
      final response = await http.put(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode({'estado': nuevoEstado}),
      );

      return response.statusCode == 200;
    } catch (e) {
      // Intentar endpoint alternativo de facturas
      try {
        final altRes = await http.put(
          Uri.parse('${ApiClient.baseUrl}/facturas/$idFactura/estado'),
          headers: SessionManager().authHeaders,
          body: jsonEncode({'estado': nuevoEstado}),
        );
        return altRes.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }

  /// Obtiene los detalles específicos de un recibo (ítems comprados)
  Future<List<PedidoDetalleItem>> getDetalleRecibo(int idFactura) async {
    final url = Uri.parse('${ApiClient.baseUrl}/recibos/$idFactura');

    try {
      final response = await http.get(url, headers: SessionManager().authHeaders);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> detalles = data['detalles'] ?? [];
        return detalles.map((item) => PedidoDetalleItem.fromJson(item)).toList();
      } else {
        // Fallback a /pedido-detalle/$idFactura
        final fallbackRes = await http.get(
          Uri.parse('${ApiClient.baseUrl}/pedido-detalle/$idFactura'),
          headers: SessionManager().authHeaders,
        );
        if (fallbackRes.statusCode == 200) {
          final List<dynamic> list = jsonDecode(fallbackRes.body);
          return list.map((item) => PedidoDetalleItem.fromJson(item)).toList();
        }
        return [];
      }
    } catch (_) {
      try {
        final fallbackRes = await http.get(
          Uri.parse('${ApiClient.baseUrl}/pedido-detalle/$idFactura'),
          headers: SessionManager().authHeaders,
        );
        if (fallbackRes.statusCode == 200) {
          final List<dynamic> list = jsonDecode(fallbackRes.body);
          return list.map((item) => PedidoDetalleItem.fromJson(item)).toList();
        }
      } catch (_) {}
      return [];
    }
  }
}
