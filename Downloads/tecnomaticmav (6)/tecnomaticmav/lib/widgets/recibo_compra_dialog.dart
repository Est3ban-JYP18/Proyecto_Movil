import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/pedido_model.dart'; 
import '../services/contador_service.dart';

class ReciboItemSimple {
  final String nombre;
  final int cantidad;
  final double precioUnitario;

  ReciboItemSimple({
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
}

class ReciboCompraDialog extends StatelessWidget {
  final int idFactura;
  final String fecha;
  final String clienteNombre;
  final String? clienteCorreo;
  final String? clienteCedula;
  final String? clienteTelefono;
  final double total;
  final String estado;
  final List<ReciboItemSimple>? itemsPredefinidos;

  const ReciboCompraDialog({
    super.key,
    required this.idFactura,
    required this.fecha,
    required this.clienteNombre,
    this.clienteCorreo,
    this.clienteCedula,
    this.clienteTelefono,
    required this.total,
    required this.estado,
    this.itemsPredefinidos,
  });

  static void mostrar(
    BuildContext context, {
    required int idFactura,
    required String fecha,
    required String clienteNombre,
    String? clienteCorreo,
    String? clienteCedula,
    String? clienteTelefono,
    required double total,
    required String estado,
    List<ReciboItemSimple>? items,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => ReciboCompraDialog(
        idFactura: idFactura,
        fecha: fecha,
        clienteNombre: clienteNombre,
        clienteCorreo: clienteCorreo,
        clienteCedula: clienteCedula,
        clienteTelefono: clienteTelefono,
        total: total,
        estado: estado,
        itemsPredefinidos: items,
      ),
    );
  }

  String _formatearPrecio(double precio) {
    final entero = precio.toStringAsFixed(0);
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formateado = entero.replaceAllMapped(regExp, (Match m) => '${m[1]}.');
    return '\$$formateado';
  }

  @override
  Widget build(BuildContext context) {
    final bool esPagado = estado.toLowerCase() == 'pagada' ||
        estado.toLowerCase() == 'pagado' ||
        estado.toLowerCase() == 'entregado';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
        child: Column(
          children: [
            // BARRA SUPERIOR CON ACCIONES
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'RECIBO DE COMPRA OFICIAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // CONTENIDO DEL RECIBO SCROLLEABLE
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // CABECERA COMERCIAL
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.security, color: AppTheme.primaryColor, size: 36),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'TECNOMATIC MAV',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Equipos y Dotaciones de Seguridad Industrial',
                                style: TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                              Text(
                                'NIT: 901.458.823-1 • Bogotá, Colombia',
                                style: TextStyle(fontSize: 11, color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 10),

                    // DETALLES DEL DOCUMENTO Y CLIENTE
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'N° DE RECIBO',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  Text(
                                    'RC-${idFactura.toString().padLeft(4, '0')}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0047AB),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: esPagado ? Colors.green.shade50 : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: esPagado ? Colors.green.shade400 : AppTheme.accentColor,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      esPagado ? Icons.check_circle : Icons.access_time_rounded,
                                      size: 14,
                                      color: esPagado ? Colors.green.shade700 : AppTheme.accentColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      esPagado ? 'PAGADO' : estado.toUpperCase(),
                                      style: TextStyle(
                                        color: esPagado ? Colors.green.shade700 : AppTheme.accentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(
                                'Fecha: ${fecha.contains('T') ? fecha.split('T')[0] : fecha}',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 13, color: Colors.grey),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Cliente: $clienteNombre',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          if (clienteCorreo != null && clienteCorreo!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.mail_outline, size: 13, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(
                                  'Correo: $clienteCorreo',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                          if (clienteTelefono != null && clienteTelefono!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 13, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(
                                  'Teléfono: $clienteTelefono',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TABLA DE PRODUCTOS COMPRADOS
                    const Text(
                      'Artículos del Recibo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (itemsPredefinidos != null && itemsPredefinidos!.isNotEmpty)
                      _buildTablaItems(itemsPredefinidos!)
                    else
                      FutureBuilder<List<PedidoDetalleItem>>(
                        future: ContadorService().getDetalleRecibo(idFactura),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Compra registrada por valor total de ${_formatearPrecio(total)}.',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            );
                          }

                          final itemsConvertidos = snapshot.data!.map((d) => ReciboItemSimple(
                            nombre: d.nombreProducto,
                            cantidad: d.cantidad,
                            precioUnitario: d.precioUnitario,
                          )).toList();

                          return _buildTablaItems(itemsConvertidos);
                        },
                      ),

                    const SizedBox(height: 16),

                    // RESUMEN FINANCIERO
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              Text(_formatearPrecio(total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Envío Nacional:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              Text('Gratis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL COMPRA:',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                              ),
                              Text(
                                _formatearPrecio(total),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // NOTA AL PIE Y REMISIÓN AL CONTADOR
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.mark_email_read_outlined, color: Color(0xFF0284C7), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este Recibo de Compra ha sido emitido y remitido directamente al Perfil del Contador para control fiscal y contable.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF0369A1), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOTONES INFERIORES
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Imprimir'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Recibo RC-${idFactura.toString().padLeft(4, '0')} preparado para imprimir.'),
                            backgroundColor: AppTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aceptar'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaItems(List<ReciboItemSimple> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1.8),
            3: FlexColumnWidth(1.8),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text('Producto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text('Cant', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Text('Precio', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...items.map(
              (item) => TableRow(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      item.nombre,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      '${item.cantidad}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Text(
                      _formatearPrecio(item.precioUnitario),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      _formatearPrecio(item.subtotal),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
