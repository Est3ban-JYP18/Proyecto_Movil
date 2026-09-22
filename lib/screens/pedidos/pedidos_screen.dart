import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../models/devolucion_model.dart';
import '../../models/pedido_model.dart';
import '../../services/pedido_service.dart';
import '../../services/permission_service.dart';
import '../../widgets/recibo_compra_dialog.dart';

class PedidosScreen extends StatefulWidget {
  final bool showAppBar;

  const PedidosScreen({super.key, this.showAppBar = false});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final PedidoService _pedidoService = PedidoService();

  // Sección activa: "pedidos" o "devoluciones"
  String _seccionActiva = 'pedidos';

  // Datos de pedidos
  List<PedidoModel> _pedidos = [];
  bool _cargandoPedidos = true;
  String? _errorPedidos;

  // Datos de devoluciones
  List<DevolucionModel> _devoluciones = [];
  bool _cargandoDevoluciones = false;
  String? _errorDevoluciones;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    final session = SessionManager();
    if (!session.isLoggedIn || session.usuarioActual == null) {
      setState(() {
        _cargandoPedidos = false;
        _errorPedidos = 'Inicia sesión para consultar tus pedidos.';
      });
      return;
    }

    setState(() {
      _cargandoPedidos = true;
      _errorPedidos = null;
    });

    try {
      final data = await _pedidoService.getHistorialCliente(session.usuarioActual!.id);
      if (mounted) {
        setState(() {
          _pedidos = data;
          _cargandoPedidos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoPedidos = false;
          _errorPedidos = 'No se pudieron cargar los pedidos. Intenta nuevamente.';
        });
      }
    }
  }

  Future<void> _cargarDevoluciones() async {
    final session = SessionManager();
    if (!session.isLoggedIn || session.usuarioActual == null) return;

    setState(() {
      _cargandoDevoluciones = true;
      _errorDevoluciones = null;
    });

    try {
      final data = await _pedidoService.getDevolucionesCliente(session.usuarioActual!.id);
      if (mounted) {
        setState(() {
          _devoluciones = data;
          _cargandoDevoluciones = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoDevoluciones = false;
          _errorDevoluciones = 'No se pudieron cargar las devoluciones.';
        });
      }
    }
  }

  String _formatearMoneda(double valor) {
    return '\$${valor.toStringAsFixed(2)}';
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagada':
      case 'entregado':
      case 'aprobada':
      case 'resuelta':
        return const Color(0xFF10B981);
      case 'pendiente':
      case 'preparando':
      case 'en proceso':
      case 'solicitada':
        return const Color(0xFFF59E0B);
      case 'enviado':
        return const Color(0xFF3B82F6);
      case 'cancelada':
      case 'cancelado':
      case 'rechazada':
        return const Color(0xFFEF4444);
      default:
        return Colors.blueGrey;
    }
  }

  // ============================================================
  // MODALES DE ACCIÓN (VER ARTÍCULOS Y SEGUIMIENTO)
  // ============================================================

  void _mostrarModalDetalles(PedidoModel pedido) {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<PedidoDetalleItem>>(
          future: _pedidoService.getDetallePedido(pedido.id),
          builder: (context, snapshot) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              actionsPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0047AB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0047AB)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles del Pedido #${pedido.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Fecha: ${pedido.fecha.split('T')[0]}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : snapshot.hasError
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Error al cargar productos: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          )
                        : (snapshot.data == null || snapshot.data!.isEmpty)
                            ? const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No hay detalles registrados para este pedido.'),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: snapshot.data!.length,
                                separatorBuilder: (context, _) => const Divider(height: 16),
                                itemBuilder: (context, idx) {
                                  final item = snapshot.data![idx];
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: item.imagen != null && item.imagen!.startsWith('http')
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  item.imagen!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                                    Icons.inventory_2_outlined,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.inventory_2_outlined,
                                                color: Colors.blueGrey,
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.nombreProducto,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Cant: ${item.cantidad} × ${_formatearMoneda(item.precioUnitario)}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _formatearMoneda(item.subtotal),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF0047AB),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              _abrirModalDevolucion(pedido, snapshot.data!, itemPreseleccionado: item);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                                              ),
                                              child: const Text(
                                                'Garantía/Dev.',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFD97706),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${_formatearMoneda(pedido.total)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0047AB),
                      ),
                    ),
                    Row(
                      children: [
                        if (snapshot.data != null && snapshot.data!.isNotEmpty)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFD97706),
                            ),
                            icon: const Icon(Icons.assignment_return_outlined, size: 16),
                            label: const Text('Devolución', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _abrirModalDevolucion(pedido, snapshot.data!);
                            },
                          ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0047AB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _abrirNuevaSolicitudGeneral() async {
    final session = SessionManager();
    if (!session.isLoggedIn || session.usuarioActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para gestionar garantías o devoluciones.')),
      );
      return;
    }

    if (_pedidos.isEmpty) {
      await _cargarPedidos();
    }

    if (!mounted) return;

    if (_pedidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aún no tienes pedidos registrados para solicitar garantía.')),
      );
      return;
    }

    PedidoModel pedidoSeleccionado = _pedidos.first;
    List<PedidoDetalleItem> articulos = await _pedidoService.getDetallePedido(pedidoSeleccionado.id);
    if (!mounted) return;
    _abrirModalDevolucion(pedidoSeleccionado, articulos, pedidosDisponibles: _pedidos);
  }

  void _abrirModalDevolucion(
    PedidoModel pedido,
    List<PedidoDetalleItem> articulos, {
    PedidoDetalleItem? itemPreseleccionado,
    List<PedidoModel>? pedidosDisponibles,
  }) {
    if (articulos.isEmpty && (pedidosDisponibles == null || pedidosDisponibles.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos disponibles para devolución.')),
      );
      return;
    }

    final session = SessionManager();
    final usuarioId = session.usuarioActual?.id;
    if (usuarioId == null) return;

    PedidoModel pedidoActual = pedido;
    List<PedidoDetalleItem> itemsActuales = List.from(articulos);
    PedidoDetalleItem? itemSeleccionado = itemPreseleccionado ?? (itemsActuales.isNotEmpty ? itemsActuales.first : null);
    int cantidad = 1;
    String motivoCategoria = 'Defecto de fábrica';
    String metodoReembolso = 'Cambio de producto';
    String metodoRetorno = 'Recogida a domicilio';
    final direccionController = TextEditingController(text: session.usuarioActual?.direccion ?? 'Calle 45 # 28-14, Bogotá');
    final notasController = TextEditingController();
    String? evidenciaAdjunta;
    bool enviando = false;
    bool cargandoItems = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              actionsPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_return_outlined, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Solicitud de Garantía / Devolución',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'Factura #${pedidoActual.id} • ${_formatearMoneda(pedidoActual.total)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selector de Factura / Pedido si hay múltiples disponibles
                      if (pedidosDisponibles != null && pedidosDisponibles.length > 1) ...[
                        const Text(
                          'Selecciona el pedido de compra:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<PedidoModel>(
                          initialValue: pedidoActual,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Pedido de referencia',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: pedidosDisponibles.map((p) {
                            return DropdownMenuItem<PedidoModel>(
                              value: p,
                              child: Text('Factura #${p.id} - ${p.fecha.split('T')[0]} (${_formatearMoneda(p.total)})', style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (p) async {
                            if (p != null) {
                              setModalState(() {
                                pedidoActual = p;
                                cargandoItems = true;
                              });
                              final nuevosItems = await _pedidoService.getDetallePedido(p.id);
                              setModalState(() {
                                itemsActuales = nuevosItems;
                                itemSeleccionado = nuevosItems.isNotEmpty ? nuevosItems.first : null;
                                cantidad = 1;
                                cargandoItems = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      const Text(
                        'Producto y Motivo de la Solicitud:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),

                      // Selector de producto
                      if (cargandoItems)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else if (itemsActuales.isNotEmpty)
                        DropdownButtonFormField<PedidoDetalleItem>(
                          initialValue: itemSeleccionado,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Producto a devolver',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: itemsActuales.map((item) {
                            return DropdownMenuItem<PedidoDetalleItem>(
                              value: item,
                              child: Text(
                                '${item.nombreProducto} (Comprados: ${item.cantidad})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                itemSeleccionado = val;
                                if (cantidad > val.cantidad) cantidad = val.cantidad;
                              });
                            }
                          },
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Cargando artículos comprados...', style: TextStyle(fontSize: 12)),
                        ),
                      const SizedBox(height: 12),

                      // Cantidad y Categoría de Motivo
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: cantidad > 1 ? () => setModalState(() => cantidad--) : null,
                                  ),
                                  Text(
                                    '$cantidad',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: (itemSeleccionado != null && cantidad < itemSeleccionado!.cantidad)
                                        ? () => setModalState(() => cantidad++)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: motivoCategoria,
                              decoration: InputDecoration(
                                labelText: 'Categoría',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Defecto de fábrica', child: Text('Defecto de fábrica', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'Talla incorrecta', child: Text('Talla / Medida incorrecta', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'Producto dañado en transporte', child: Text('Dañado en transporte', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'Producto no corresponde al pedido', child: Text('Producto equivocado', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'Incompatibilidad técnica', child: Text('Incompatibilidad', style: TextStyle(fontSize: 12))),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => motivoCategoria = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Preferencia de Resolución / Reembolso
                      DropdownButtonFormField<String>(
                        initialValue: metodoReembolso,
                        decoration: InputDecoration(
                          labelText: 'Solución preferida',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cambio de producto', child: Text('🔄 Cambio por otra talla / producto', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Cupón de tienda', child: Text('🎟️ Cupón de tienda (100% + Descuento)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Reembolso de dinero', child: Text('💳 Reembolso a medio de pago original', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => metodoReembolso = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Logística de Retorno
                      DropdownButtonFormField<String>(
                        initialValue: metodoRetorno,
                        decoration: InputDecoration(
                          labelText: 'Método de entrega',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Recogida a domicilio', child: Text('🚚 Recogida a domicilio por mensajería', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Entrega en sucursal', child: Text('🏢 Entrega en punto de atención / sucursal', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => metodoRetorno = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Dirección de retorno si es recogida
                      if (metodoRetorno == 'Recogida a domicilio') ...[
                        TextField(
                          controller: direccionController,
                          decoration: InputDecoration(
                            labelText: 'Dirección de recogida',
                            hintText: 'Calle, número, barrio y ciudad...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Motivo detallado
                      TextField(
                        controller: notasController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Descripción detallada del motivo',
                          hintText: 'Describe claramente qué falla o detalle presenta el producto...',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Adjuntar Pruebas Fotográficas (Cámara y Almacenamiento)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '📸 Pruebas y Evidencias:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                ),
                                if (evidenciaAdjunta != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('✓ Adjunta', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Adjunta una foto clara del defecto o etiqueta para agilizar la aprobación:',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF1E3A8A),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.camera_alt, size: 16),
                                    label: const Text('Cámara', style: TextStyle(fontSize: 12)),
                                    onPressed: () async {
                                      final granted = await PermissionService.solicitarCamara(context);
                                      if (granted) {
                                        try {
                                          final picker = ImagePicker();
                                          final XFile? foto = await picker.pickImage(
                                            source: ImageSource.camera,
                                            maxWidth: 1200,
                                            maxHeight: 1200,
                                            imageQuality: 85,
                                          );
                                          if (foto != null) {
                                            setModalState(() {
                                              evidenciaAdjunta = foto.path;
                                            });
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Foto capturada correctamente con la cámara.')),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error al abrir la cámara: $e')),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF1E3A8A),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.photo_library, size: 16),
                                    label: const Text('Galería', style: TextStyle(fontSize: 12)),
                                    onPressed: () async {
                                      final granted = await PermissionService.solicitarAlmacenamiento(context);
                                      if (granted) {
                                        try {
                                          final picker = ImagePicker();
                                          final XFile? foto = await picker.pickImage(
                                            source: ImageSource.gallery,
                                            maxWidth: 1200,
                                            maxHeight: 1200,
                                            imageQuality: 85,
                                          );
                                          if (foto != null) {
                                            setModalState(() {
                                              evidenciaAdjunta = foto.path;
                                            });
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Imagen seleccionada de la galería.')),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error al abrir galería: $e')),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (evidenciaAdjunta != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: evidenciaAdjunta!.startsWith('http')
                                            ? Image.network(evidenciaAdjunta!, fit: BoxFit.cover)
                                            : Image.file(
                                                File(evidenciaAdjunta!),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Icon(
                                                  Icons.image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Foto adjunta',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            evidenciaAdjunta!.split(Platform.pathSeparator).last,
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                      onPressed: () {
                                        setModalState(() {
                                          evidenciaAdjunta = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: enviando
                      ? null
                      : () async {
                          final motivo = notasController.text.trim();
                          if (motivo.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor escribe el motivo detallado')),
                            );
                            return;
                          }

                          if (itemSeleccionado == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Selecciona el producto a devolver')),
                            );
                            return;
                          }

                          setModalState(() => enviando = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(ctx);

                          try {
                            await _pedidoService.crearSolicitudDevolucion(
                              facturaId: pedidoActual.id,
                              productoId: itemSeleccionado!.idProducto,
                              usuarioId: usuarioId,
                              cantidad: cantidad,
                              motivo: motivo,
                              motivoCategoria: motivoCategoria,
                              metodoReembolso: metodoReembolso,
                              metodoRetorno: metodoRetorno,
                              direccionRetorno: direccionController.text.trim(),
                              evidenciaUrl: evidenciaAdjunta ?? 'https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?w=500',
                            );

                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('¡Solicitud de devolución registrada con éxito en Supabase!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );

                            if (mounted) {
                              setState(() {
                                _seccionActiva = 'devoluciones';
                              });
                              _cargarDevoluciones();
                            }
                          } catch (e) {
                            setModalState(() => enviando = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Enviar Solicitud'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarModalSeguimiento(PedidoModel pedido) {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<PedidoSeguimiento>(
          future: _pedidoService.getSeguimientoPedido(pedido.id, estadoFallback: pedido.estado),
          builder: (context, snapshot) {
            final seg = snapshot.data;
            final estadoActual = seg?.estadoEntrega ?? pedido.estado;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              actionsPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seguimiento Pedido #${pedido.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Estado actual: $estadoActual',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _obtenerColorEstado(estadoActual),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Línea de tiempo simple
                          _buildPasoSeguimiento(
                            titulo: 'Pedido Realizado',
                            descripcion: 'Orden registrada en el sistema.',
                            completado: true,
                          ),
                          _buildPasoSeguimiento(
                            titulo: 'En Preparación',
                            descripcion: 'Artículos verificados en almacén.',
                            completado: estadoActual.toLowerCase() != 'cancelado' &&
                                estadoActual.toLowerCase() != 'cancelada',
                          ),
                          _buildPasoSeguimiento(
                            titulo: 'En Tránsito / Despachado',
                            descripcion: 'El paquete se encuentra en ruta logística.',
                            completado: estadoActual.toLowerCase() == 'enviado' ||
                                estadoActual.toLowerCase() == 'entregado' ||
                                estadoActual.toLowerCase() == 'pagada',
                          ),
                          _buildPasoSeguimiento(
                            titulo: 'Entregado',
                            descripcion: 'Pedido recibido a satisfacción.',
                            completado: estadoActual.toLowerCase() == 'entregado',
                            esUltimo: true,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Observaciones Logísticas:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  seg?.observaciones ?? 'El pedido está siendo procesado en bodega.',
                                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                ),
                                if (seg?.fechaEntrega != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Fecha estimada de entrega: ${seg!.fechaEntrega!.split('T')[0]}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0047AB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPasoSeguimiento({
    required String titulo,
    required String descripcion,
    required bool completado,
    bool esUltimo = false,
  }) {
    final color = completado ? const Color(0xFF10B981) : Colors.grey.shade300;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: completado ? const Color(0xFF10B981) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: completado
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!esUltimo)
              Container(
                width: 2,
                height: 28,
                color: completado ? const Color(0xFF10B981) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: completado ? const Color(0xFF0F172A) : Colors.grey,
                ),
              ),
              Text(
                descripcion,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONSTRUCCIÓN VISUAL PRINCIPAL (RÉPLICA IMAGEN 2)
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Historial de Compras'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          if (_seccionActiva == 'pedidos') {
            await _cargarPedidos();
          } else {
            await _cargarDevoluciones();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TÍTULO Y SUBTÍTULO
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('📦', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  const Text(
                    'Historial de Compras',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0047AB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Revisa tus pedidos anteriores, realiza seguimiento logístico y solicita devoluciones.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // 2. BOTONES / PESTAÑAS PILL ("Mis Pedidos" / "Mis Devoluciones")
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildPillTab(
                      id: 'pedidos',
                      label: 'Mis Pedidos',
                      icon: Icons.table_chart_outlined,
                    ),
                    const SizedBox(width: 10),
                    _buildPillTab(
                      id: 'devoluciones',
                      label: 'Mis Devoluciones',
                      icon: Icons.swap_horiz,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. CONTENEDOR PRINCIPAL BLANCO
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(16.0),
                child: _seccionActiva == 'pedidos'
                    ? _buildContenidoPedidos()
                    : _buildContenidoDevoluciones(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final bool activo = _seccionActiva == id;

    return InkWell(
      onTap: () {
        setState(() {
          _seccionActiva = id;
        });
        if (id == 'devoluciones' && _devoluciones.isEmpty) {
          _cargarDevoluciones();
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF0047AB) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: activo ? const Color(0xFF0047AB) : const Color(0xFFCBD5E1),
          ),
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: const Color(0xFF0047AB).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: activo ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: activo ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VISTA: MIS PEDIDOS (REGISTRO DE COMPRAS)
  // ============================================================

  Widget _buildContenidoPedidos() {
    if (_cargandoPedidos) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorPedidos != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _errorPedidos!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _cargarPedidos,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0047AB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtítulo de sección con icono de caja
        Row(
          children: const [
            Text('📦', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              'Registro de Compras',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0047AB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_pedidos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'Aún no tienes pedidos registrados.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pedidos.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pedido = _pedidos[index];
              return _buildFilaPedido(pedido);
            },
          ),
      ],
    );
  }

  Widget _buildFilaPedido(PedidoModel pedido) {
    final colorEstado = _obtenerColorEstado(pedido.estado);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila Superior: Pedido # y Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${pedido.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                _formatearMoneda(pedido.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0047AB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Fila Media: Fecha, Artículos y Badge de Estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    pedido.fecha.split('T')[0],
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  pedido.estado,
                  style: TextStyle(
                    color: colorEstado,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          const Text(
            'Artículos: Detalles en botón ver',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),

          // Fila Inferior: Botones de Acción (Ver, Generar Recibo y Seguimiento)
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 6,
            children: [
              // Botón "Generar Recibo" (Estilo recibo comercial)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(60, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.receipt_long, size: 14),
                label: const Text('Generar Recibo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  final session = SessionManager();
                  ReciboCompraDialog.mostrar(
                    context,
                    idFactura: pedido.id,
                    fecha: pedido.fecha,
                    clienteNombre: pedido.cliente,
                    clienteCorreo: pedido.correo ?? session.usuarioActual?.correo,
                    clienteTelefono: pedido.telefono,
                    total: pedido.total,
                    estado: pedido.estado,
                  );
                },
              ),

              // Botón "Ver" (Azul estilo captura)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0047AB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(60, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => _mostrarModalDetalles(pedido),
                child: const Text('Ver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),

              // Botón "Seguimiento" (Blanco con borde estilo captura)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(80, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => _mostrarModalSeguimiento(pedido),
                child: const Text('Seguimiento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VISTA: MIS DEVOLUCIONES
  // ============================================================

  Widget _buildContenidoDevoluciones() {
    if (_cargandoDevoluciones) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorDevoluciones != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_errorDevoluciones!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cargarDevoluciones,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner superior para radicar nueva solicitud de garantía o devolución
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Garantías y Devoluciones',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tramita cambios de talla o defectos con evidencia fotográfica.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Solicitar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: _abrirNuevaSolicitudGeneral,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_devoluciones.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.assignment_return_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'No tienes solicitudes de devolución activas.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Presiona el botón "Solicitar" arriba o entra a cualquiera de tus pedidos para tramitar una garantía.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _devoluciones.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final dev = _devoluciones[index];
              final color = _obtenerColorEstado(dev.estado);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Devolución #${dev.id} (Factura #${dev.facturaId})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            dev.estado,
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Producto: ${dev.producto} (Cant: ${dev.cantidad})',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Motivo: ${dev.motivo}',
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                    if (dev.comentariosAdmin != null && dev.comentariosAdmin!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Respuesta Admin: ${dev.comentariosAdmin}',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    if (dev.codigoCupon != null && dev.codigoCupon!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Cupón de Reembolso: ${dev.codigoCupon}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
