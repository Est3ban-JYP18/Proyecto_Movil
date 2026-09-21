import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';

class PaymentService {
  Future<String?> crearPreferenciaPago(List<Map<String, dynamic>> items) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/crear-preferencia'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'items': items}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id']; // ID de la preferencia retornado por Mercado Pago
      }
      return null;
    } catch (e) {
      debugPrint('Error al generar pago: $e');
      return null;
    }
  }
}