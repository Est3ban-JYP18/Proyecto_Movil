import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import 'launcher/url_launcher_helper.dart';
import '../core/session/session_manager.dart';
import '../models/cart_item_model.dart';

class PaymentService {
  // Crear preferencia y obtener init_point de Mercado Pago mediante el backend
  Future<Map<String, dynamic>?> crearPagoMercadoPago(List<CartItem> items) async {
    final url = Uri.parse('${ApiClient.baseUrl}/crear-pago');

    final payload = {
      'carrito': items.map((item) => {
        'idProductos': item.producto.id,
        'Nombre_Producto': item.producto.nombre,
        'Precio': item.producto.precio,
        'cantidad': item.cantidad,
      }).toList(),
    };

    try {
      final response = await http.post(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        debugPrint('Error en /crear-pago: ${response.statusCode} -> ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Excepción al conectar con Mercado Pago: $e');
      return null;
    }
  }

  // Registrar el pedido y la factura en la base de datos MySQL mediante el backend
  Future<int?> registrarPedidoBackend({
    required int idUsuario,
    required double total,
    required List<CartItem> items,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/pedidos');

    final pedidoData = {
      'idUsuario': idUsuario,
      'total': total,
      'productos': items.map((item) => {
        'idProducto': item.producto.id,
        'cantidad': item.cantidad,
        'precioUnitario': item.producto.precio,
      }).toList(),
    };

    try {
      final response = await http.post(
        url,
        headers: SessionManager().authHeaders,
        body: jsonEncode(pedidoData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return int.tryParse(data['idFactura']?.toString() ?? '');
      } else {
        debugPrint('Error en /pedidos: ${response.statusCode} -> ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Excepción al registrar pedido: $e');
      return null;
    }
  }

  // Abre la pasarela oficial de Mercado Pago
  Future<bool> abrirPasarelaMercadoPago(String urlString) async {
    try {
      return await PlatformUrlLauncher.openUrl(urlString);
    } catch (e) {
      debugPrint('Error abriendo pasarela de pago: $e');
      return false;
    }
  }

  // Compatibilidad con llamadas previas
  Future<String?> crearPreferenciaPago(List<Map<String, dynamic>> items) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/crear-preferencia'),
        headers: SessionManager().authHeaders,
        body: jsonEncode({'items': items}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Error al generar pago: $e');
      return null;
    }
  }
}