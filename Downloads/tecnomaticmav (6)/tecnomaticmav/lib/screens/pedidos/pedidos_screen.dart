import 'package:flutter/material.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../models/devolucion_model.dart';
import '../../models/pedido_model.dart';
import '../../services/pedido_service.dart';
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
                                      Text(
                                        _formatearMoneda(item.subtotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF0047AB),
                                        ),
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
              Row(
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

    if (_devoluciones.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.assignment_return_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'No has solicitado devoluciones.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Si necesitas ayuda con un producto entregado, comunícate con atención al cliente o solicita soporte desde el detalle de tu pedido.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
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
    );
  }
}
