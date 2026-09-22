import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pedido_model.dart';
import '../../services/contador_service.dart';
import '../../widgets/recibo_compra_dialog.dart';

class GenerarRecibosScreen extends StatefulWidget {
  final bool showAppBar;

  const GenerarRecibosScreen({super.key, this.showAppBar = true});

  @override
  State<GenerarRecibosScreen> createState() => _GenerarRecibosScreenState();
}

class _GenerarRecibosScreenState extends State<GenerarRecibosScreen> {
  final ContadorService _contadorService = ContadorService();
  final TextEditingController _searchController = TextEditingController();

  List<PedidoModel> _todosLosRecibos = [];
  List<PedidoModel> _recibosFiltrados = [];
  bool _cargando = true;
  String? _error;
  String _filtroEstado = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarRecibos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarRecibos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final recibos = await _contadorService.getRecibosContador();

      if (mounted) {
        setState(() {
          _todosLosRecibos = recibos;
          _cargando = false;
          _aplicarFiltros();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'Error al cargar los recibos de compra: $e';
        });
      }
    }
  }

  void _aplicarFiltros() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _recibosFiltrados = _todosLosRecibos.where((r) {
        final matchQuery =
            query.isEmpty ||
            r.id.toString().contains(query) ||
            r.cliente.toLowerCase().contains(query) ||
            (r.correo != null &&
                r.correo!.toLowerCase().contains(query));

        final matchEstado =
            _filtroEstado == 'Todos' ||
            r.estado.toLowerCase() == _filtroEstado.toLowerCase();

        return matchQuery && matchEstado;
      }).toList();
    });
  }

  String _formatearPrecio(double precio) {
    final entero = precio.toStringAsFixed(0);
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formateado =
        entero.replaceAllMapped(regExp, (Match m) => '${m[1]}.');

    return '\$$formateado';
  }

  String _formatearFecha(String fechaRaw) {
    try {
      final limpia =
          fechaRaw.contains('T') ? fechaRaw.split('T')[0] : fechaRaw;

      final partes = limpia.split('-');

      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }

      return limpia;
    } catch (_) {
      return fechaRaw;
    }
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagada':
      case 'pagado':
      case 'entregado':
      case 'aprobada':
        return const Color(0xFF10B981);

      case 'pendiente':
      case 'preparando':
      case 'en proceso':
        return const Color(0xFFF59E0B);

      case 'enviado':
        return const Color(0xFF3B82F6);

      case 'cancelada':
      case 'cancelado':
        return const Color(0xFFEF4444);

      default:
        return Colors.blueGrey;
    }
  }

  void _cambiarEstadoDialog(PedidoModel recibo) {
    String nuevoEstado = recibo.estado;

    final opciones = [
      'Pagado',
      'Pendiente',
      'Preparando',
      'Enviado',
      'Entregado',
      'Cancelado',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Gestionar Recibo RC-${recibo.id.toString().padLeft(4, '0')}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el nuevo estado fiscal/contable:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: opciones.contains(nuevoEstado)
                      ? nuevoEstado
                      : 'Pendiente',
                  items: opciones
                      .map(
                        (op) => DropdownMenuItem(
                          value: op,
                          child: Text(op),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      nuevoEstado = val;
                      setModalState(() {});
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);

                  final ok =
                      await _contadorService.actualizarEstadoRecibo(
                    recibo.id,
                    nuevoEstado,
                  );

                  if (ok) {
                    _cargarRecibos();

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Estado de recibo actualizado correctamente',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Error al actualizar estado del recibo',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRecibos = _todosLosRecibos.length;

    final totalIngresos = _todosLosRecibos
        .where(
          (r) =>
              r.estado.toLowerCase() == 'pagado' ||
              r.estado.toLowerCase() == 'pagada' ||
              r.estado.toLowerCase() == 'entregado',
        )
        .fold(0.0, (sum, r) => sum + r.total);

    final pagados = _todosLosRecibos
        .where(
          (r) =>
              r.estado.toLowerCase() == 'pagado' ||
              r.estado.toLowerCase() == 'pagada' ||
              r.estado.toLowerCase() == 'entregado',
        )
        .length;

    final pendientes = _todosLosRecibos
        .where(
          (r) =>
              r.estado.toLowerCase() == 'pendiente' ||
              r.estado.toLowerCase() == 'preparando',
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Recibos de Compra'),
              backgroundColor: AppTheme.primaryColor,
              elevation: 1,
            )
          : null,

      body: RefreshIndicator(
        onRefresh: _cargarRecibos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF002B73),
                      Color(0xFF0047AB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0047AB)
                          .withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.amber,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'RECIBOS DE COMPRA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bandeja oficial del Contador. Los recibos generados tras las compras de los clientes se asientan directamente aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildMetricCard(
                    'Total Recibos',
                    '$totalRecibos',
                    Icons.receipt_outlined,
                    Colors.blue,
                  ),
                  _buildMetricCard(
                    'Recaudado',
                    _formatearPrecio(totalIngresos),
                    Icons.attach_money_rounded,
                    Colors.green,
                  ),
                  _buildMetricCard(
                    'Pagados',
                    '$pagados',
                    Icons.check_circle_outline,
                    Colors.teal,
                  ),
                  _buildMetricCard(
                    'Pendientes',
                    '$pendientes',
                    Icons.access_time_rounded,
                    Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              TextField(
                controller: _searchController,
                onChanged: (_) => _aplicarFiltros(),
                decoration: InputDecoration(
                  hintText:
                      'Buscar por cliente, correo o N° de recibo...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _aplicarFiltros();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Todos',
                    'Pagado',
                    'Pendiente',
                    'Preparando',
                    'Enviado',
                    'Cancelado',
                  ].map((st) {
                    final isSelected =
                        _filtroEstado.toLowerCase() ==
                            st.toLowerCase();

                    return Padding(
                      padding:
                          const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(st),
                        selected: isSelected,
                        selectedColor:
                            AppTheme.primaryColor.withValues(
                          alpha: 0.15,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (bool val) {
                          setState(() {
                            _filtroEstado = st;
                          });
                          _aplicarFiltros();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              if (_cargando)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _cargarRecibos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              else if (_recibosFiltrados.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No se encontraron recibos de compra con los filtros aplicados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: _recibosFiltrados.length,
                  separatorBuilder: (context, _) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = _recibosFiltrados[index];
                    return _buildReciboCard(r);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReciboCard(PedidoModel recibo) {
    final colorEstado =
        _obtenerColorEstado(recibo.estado);

    final codigoRecibo =
        'RC-${recibo.id.toString().padLeft(4, '0')}';

    final fechaFormateada =
        _formatearFecha(recibo.fecha);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor
                            .withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                        codigoRecibo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppTheme.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorEstado
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: colorEstado
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        recibo.estado,
                        style: TextStyle(
                          color: colorEstado,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Cliente: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            TextSpan(
                              text: recibo.cliente,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Fecha: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          TextSpan(
                            text: fechaFormateada,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.attach_money_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Total: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          TextSpan(
                            text:
                                _formatearPrecio(recibo.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color:
                                  AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (recibo.correo != null &&
                    recibo.correo!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        recibo.correo!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(
                      Icons.tune,
                      size: 16,
                    ),
                    label: const Text(
                      'Estado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () =>
                        _cambiarEstadoDialog(recibo),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      elevation: 1,
                    ),
                    icon: const Icon(
                      Icons.receipt_long,
                      size: 18,
                    ),
                    label: const Text(
                      'Ver recibo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () {
                      ReciboCompraDialog.mostrar(
                        context,
                        idFactura: recibo.id,
                        fecha: recibo.fecha,
                        clienteNombre: recibo.cliente,
                        clienteCorreo: recibo.correo,
                        clienteTelefono: recibo.telefono,
                        total: recibo.total,
                        estado: recibo.estado,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 