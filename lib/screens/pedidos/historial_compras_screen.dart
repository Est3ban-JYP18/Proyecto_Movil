import 'package:flutter/material.dart';
import '../../models/devolucion_model.dart';
import '../../models/pedido_model.dart';
import '../../services/pedido_service.dart';

class HistorialComprasScreen extends StatefulWidget {
  final String? userRole;
  final int? userId;
  final String? token;
  final bool showAppBar;

  const HistorialComprasScreen({
    super.key,
    this.userRole,
    this.userId,
    this.token,
    this.showAppBar = true,
  });

  @override
  State<HistorialComprasScreen> createState() => _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends State<HistorialComprasScreen> {
  final PedidoService _pedidoService = PedidoService();
  final TextEditingController _searchController = TextEditingController();

  // Pestaña activa: "pedidos" o "devoluciones"
  String _seccionActiva = 'pedidos';

  // Datos pedidos
  List<PedidoModel> _todosLosPedidos = [];
  List<PedidoModel> _pedidosFiltrados = [];
  bool _cargando = true;
  String? _error;
  String _filtroEstado = 'Todos';

  // Datos métricas
  int _totalProductosCatalogo = 0;

  // Datos devoluciones
  List<DevolucionModel> _devoluciones = [];
  bool _cargandoDevoluciones = false;
  String? _errorDevoluciones;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    await Future.wait([
      _cargarPedidos(),
      _cargarCantidadCatalogo(),
    ]);
  }

  Future<void> _cargarPedidos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final pedidos = await _pedidoService.getHistorialAdmin();
      if (mounted) {
        setState(() {
          _todosLosPedidos = pedidos;
          _cargando = false;
          _aplicarFiltros();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'Error al cargar facturas: $e';
        });
      }
    }
  }

  Future<void> _cargarCantidadCatalogo() async {
    try {
      final total = await _pedidoService.getCantidadProductos();
      if (mounted) {
        setState(() {
          _totalProductosCatalogo = total;
        });
      }
    } catch (_) {}
  }

  Future<void> _cargarDevoluciones() async {
    setState(() {
      _cargandoDevoluciones = true;
      _errorDevoluciones = null;
    });

    try {
      final devs = await _pedidoService.getDevolucionesAdmin();
      if (mounted) {
        setState(() {
          _devoluciones = devs;
          _cargandoDevoluciones = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoDevoluciones = false;
          _errorDevoluciones = 'Error al cargar devoluciones: $e';
        });
      }
    }
  }

  void _aplicarFiltros() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _pedidosFiltrados = _todosLosPedidos.where((pedido) {
        final coincideBusqueda = query.isEmpty ||
            pedido.id.toString().contains(query) ||
            pedido.cliente.toLowerCase().contains(query);

        final coincideEstado = _filtroEstado == 'Todos' ||
            pedido.estado.toLowerCase() == _filtroEstado.toLowerCase();

        return coincideBusqueda && coincideEstado;
      }).toList();
    });
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
  // ACCIONES ADMINISTRATIVAS: DETALLES, CAMBIAR ESTADO, ELIMINAR
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
                    child: const Icon(Icons.receipt_long, color: Color(0xFF0047AB)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Factura #${pedido.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Cliente: ${pedido.cliente}',
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
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : (snapshot.data == null || snapshot.data!.isEmpty)
                            ? const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No hay productos asociados a esta factura.'),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: snapshot.data!.length,
                                separatorBuilder: (context, _) => const Divider(height: 16),
                                itemBuilder: (context, idx) {
                                  final item = snapshot.data![idx];
                                  return Row(
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
                                            : const Icon(Icons.inventory_2_outlined, color: Colors.blueGrey),
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

  void _mostrarModalCambiarEstado(PedidoModel pedido) {
    const estados = ['Pendiente', 'Preparando', 'Enviado', 'Entregado', 'Cancelado'];
    String estadoSeleccionado = estados.contains(pedido.estado) ? pedido.estado : 'Pendiente';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Actualizar Estado',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0047AB)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona el nuevo estado para el pedido #${pedido.id}:',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: estadoSeleccionado,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => estadoSeleccionado = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20B2AA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    try {
                      await _pedidoService.actualizarEstadoPedido(pedido.id, estadoSeleccionado);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Pedido #${pedido.id} actualizado a $estadoSeleccionado'),
                          backgroundColor: const Color(0xFF20B2AA),
                        ),
                      );
                      _cargarPedidos();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmarEliminarPedido(PedidoModel pedido) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '¿Eliminar pedido?',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            'Esta acción eliminará de forma permanente el pedido #${pedido.id}, sus detalles, entregas y devoluciones relacionadas en MySQL.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  await _pedidoService.eliminarPedido(pedido.id);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Pedido #${pedido.id} eliminado correctamente'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                  _cargarPedidos();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Sí, eliminar'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CONSTRUCCIÓN VISUAL PRINCIPAL (RÉPLICA IMAGEN 1)
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Panel Logístico y de Pedidos'),
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          if (_seccionActiva == 'pedidos') {
            await _cargarTodo();
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
                  const Text('📋', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  const Text(
                    'Panel Logístico y de Pedidos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0047AB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Gestiona los pedidos de compra de los clientes y aprueba solicitudes de devoluciones.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // 2. BOTONES / PESTAÑAS PILL (Pedidos Recibidos / Devoluciones Solicitadas)
              Row(
                children: [
                  _buildPillTab(
                    id: 'pedidos',
                    label: 'Pedidos Recibidos',
                    icon: Icons.table_chart_outlined,
                  ),
                  const SizedBox(width: 10),
                  _buildPillTab(
                    id: 'devoluciones',
                    label: 'Devoluciones Solicitadas',
                    icon: Icons.swap_horiz,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3. TARJETAS DE MÉTRICAS (Las 4 de la Imagen 1)
              _buildTarjetasMetricas(),
              const SizedBox(height: 18),

              // 4. CONTENEDOR PRINCIPAL BLANCO (Buscador, Filtros y Lista)
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
  // TARJETAS DE MÉTRICAS (RÉPLICA EXACTA IMAGEN 1)
  // ============================================================

  Widget _buildTarjetasMetricas() {
    final pendientes = _todosLosPedidos
        .where((p) => p.estado.toLowerCase() == 'pendiente' || p.estado.isEmpty)
        .length;

    final entregados = _todosLosPedidos
        .where((p) => p.estado.toLowerCase() == 'entregado' || p.estado.toLowerCase() == 'pagada')
        .length;

    final totalIngresos = _todosLosPedidos
        .where((p) => p.estado.toLowerCase() != 'cancelado' && p.estado.toLowerCase() != 'cancelada')
        .fold<double>(0.0, (sum, item) => sum + item.total);

    final catalogoCount = _totalProductosCatalogo > 0 ? _totalProductosCatalogo : 11;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // Si la pantalla es tablet/escritorio o móvil ancho
        final int crossAxis = w > 600 ? 4 : 2;
        final double ratio = w > 600 ? 1.6 : 1.35;

        return GridView.count(
          crossAxisCount: crossAxis,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: ratio,
          children: [
            _buildMetricaCard(
              titulo: 'CATÁLOGO DE ITEMS',
              valor: '$catalogoCount',
              subtitulo: 'Productos registrados en MySQL',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF0047AB),
              iconBgColor: const Color(0xFF0047AB).withValues(alpha: 0.08),
            ),
            _buildMetricaCard(
              titulo: 'PEDIDOS PENDIENTES',
              valor: '$pendientes',
              subtitulo: 'Esperando procesamiento logístico',
              icon: Icons.access_time_rounded,
              iconColor: const Color(0xFFB45309),
              iconBgColor: const Color(0xFFFDE68A).withValues(alpha: 0.35),
            ),
            _buildMetricaCard(
              titulo: 'PEDIDOS ENTREGADOS',
              valor: '$entregados',
              subtitulo: 'Entregas finalizadas con éxito',
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF047857),
              iconBgColor: const Color(0xFFA7F3D0).withValues(alpha: 0.35),
            ),
            _buildMetricaCard(
              titulo: 'INGRESOS TOTALES',
              valor: '\$${totalIngresos.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
              subtitulo: 'Recaudación de facturación real',
              icon: Icons.payments_outlined,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricaCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            subtitulo,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENIDO DE PEDIDOS (BUSCADOR, CHIPS FILTRO Y FILAS)
  // ============================================================

  Widget _buildContenidoPedidos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buscador "Buscar por cliente o factura..."
        TextField(
          controller: _searchController,
          onChanged: (_) => _aplicarFiltros(),
          decoration: InputDecoration(
            hintText: 'Buscar por cliente o factura...',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filtros de estado por Chips + Botón de refrescar
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Todos',
                    'Pendiente',
                    'Preparando',
                    'Enviado',
                    'Entregado',
                    'Cancelado',
                  ].map((estado) {
                    final seleccionado = _filtroEstado == estado;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(estado),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: seleccionado ? Colors.white : const Color(0xFF475569),
                        ),
                        selected: seleccionado,
                        selectedColor: const Color(0xFF0047AB),
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: seleccionado ? const Color(0xFF0047AB) : const Color(0xFFCBD5E1),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _filtroEstado = estado;
                              _aplicarFiltros();
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Botón de refresco (⟳)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF0047AB), size: 22),
              tooltip: 'Refrescar',
              onPressed: _cargarTodo,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Lista de Facturas
        if (_cargando)
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          )
        else if (_pedidosFiltrados.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'No se encontraron facturas con los filtros seleccionados.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pedidosFiltrados.length,
            separatorBuilder: (context, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final pedido = _pedidosFiltrados[index];
              return _buildFilaFacturaAdmin(pedido);
            },
          ),
      ],
    );
  }

  Widget _buildFilaFacturaAdmin(PedidoModel pedido) {
    final colorEstado = _obtenerColorEstado(pedido.estado);

    return Container(
      padding: const EdgeInsets.all(12),
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
          // Fila 1: Factura #, Fecha y Total
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
                  fontSize: 15,
                  color: Color(0xFF0047AB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Fila 2: Cliente y Fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pedido.cliente,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF334155),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                pedido.fecha.split('T')[0],
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fila 3: Badge de Estado y Acciones (Ver, Estado, Eliminar)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              Row(
                children: [
                  // Botón "Ver" (Azul estilo captura)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0047AB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(48, 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => _mostrarModalDetalles(pedido),
                    child: const Text('Ver', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),

                  // Botón "Estado" (Borde sutil gris)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(56, 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => _mostrarModalCambiarEstado(pedido),
                    child: const Text('Estado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),

                  // Botón "Eliminar" (Papelera roja en contorno rojo)
                  IconButton(
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(30, 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: () => _confirmarEliminarPedido(pedido),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENIDO DE DEVOLUCIONES ADMINISTRATIVAS
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
        child: Center(
          child: Text(_errorDevoluciones!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_devoluciones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No hay solicitudes de devolución pendientes.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _devoluciones.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final dev = _devoluciones[index];
        final color = _obtenerColorEstado(dev.estado);

        return Container(
          padding: const EdgeInsets.all(12),
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
              const SizedBox(height: 4),
              Text(
                'Cliente: ${dev.cliente}',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              ),
              Text(
                'Producto: ${dev.producto} (Cant: ${dev.cantidad})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              Text(
                'Motivo: ${dev.motivo}',
                style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),

              if (dev.estado.toLowerCase() == 'pendiente' ||
                  dev.estado.toLowerCase() == 'solicitada')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(60, 28),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () async {
                        await _pedidoService.aprobarDevolucion(dev.id);
                        _cargarDevoluciones();
                      },
                      child: const Text('Aprobar', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(60, 28),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () async {
                        await _pedidoService.rechazarDevolucion(dev.id);
                        _cargarDevoluciones();
                      },
                      child: const Text('Rechazar', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}