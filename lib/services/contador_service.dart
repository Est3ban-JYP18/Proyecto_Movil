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
}
