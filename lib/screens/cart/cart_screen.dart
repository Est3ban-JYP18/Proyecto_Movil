import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/payment_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessing = false;

  void _procesarPago() async {
    setState(() => _isProcessing = true);

    // Lista de prueba basada en la estructura requerida por Mercado Pago
    final items = [
      {
        'title': 'Casco de Seguridad Dielectrico',
        'unit_price': 45000,
        'quantity': 1,
      }
    ];

    final paymentService = PaymentService();
    final preferenceId = await paymentService.crearPreferenciaPago(items);

    setState(() => _isProcessing = false);

    if (preferenceId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferencia creada con éxito: $preferenceId')),
      );
      // Aquí se abre el WebView o el Checkout de Mercado Pago
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al conectar con la pasarela de pago'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Carrito')),
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _isProcessing ? null : _procesarPago,
          icon: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.payment, color: Colors.white),
          label: Text(
            _isProcessing ? 'Procesando...' : 'Pagar con Mercado Pago',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}