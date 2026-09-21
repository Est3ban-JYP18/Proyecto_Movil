import 'package:flutter/material.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../models/devolucion_model.dart';
import '../../models/producto_model.dart';
import '../../models/usuario_model.dart';
import '../../services/admin_service.dart';
import '../../services/producto_service.dart';
import '../../widgets/panel_tarjeta.dart';
import '../pedidos/historial_compras_screen.dart';
import '../profile/profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int initialIndex;
  final VoidCallback? onCerrarSesion;

  const AdminDashboardScreen({
    super.key,
    this.initialIndex = 0,
    this.onCerrarSesion,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedIndex;

  final ProductoService _productoService = ProductoService();
  final AdminService _adminService = AdminService();

  // Estados de Productos
  List<Producto> _productos = [];
  bool _cargandoProductos = true;
  String _busquedaProducto = '';
  final String _categoriaProducto = 'Todas';


  // Estados de Usuarios
  List<Usuario> _usuarios = [];
  bool _cargandoUsuarios = true;
  String _busquedaUsuario = '';

  // Estados de Devoluciones
  List<DevolucionModel> _devoluciones = [];
  bool _cargandoDevoluciones = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _selectedIndex != _tabController.index) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
    _cargarTodo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _cargarTodo() {
    _cargarProductos();
    _cargarUsuarios();
    _cargarDevoluciones();
  }

  Future<void> _cargarProductos() async {
    setState(() => _cargandoProductos = true);
    try {
      final list = await _productoService.getProductos();
      if (mounted) {
        setState(() {
          _productos = list;
          _cargandoProductos = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoProductos = false);
    }
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargandoUsuarios = true);
    try {
      final list = await _adminService.getUsuarios();
      if (mounted) {
        setState(() {
          _usuarios = list;
          _cargandoUsuarios = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoUsuarios = false);
    }
  }

  Future<void> _cargarDevoluciones() async {
    setState(() => _cargandoDevoluciones = true);
    try {
      final list = await _adminService.getDevoluciones();
      if (mounted) {
        setState(() {
          _devoluciones = list;
          _cargandoDevoluciones = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoDevoluciones = false);
    }
  }

  String _formatearPrecio(double p) {
    return '\$${p.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final titulos = [
      'Gestión de Productos',
      'Gestión de Pedidos',
      'Gestión de Usuarios',
      'Gestión de Devoluciones',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(titulos[_selectedIndex]),
        backgroundColor: AppTheme.primaryColor,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Mi Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    onSessionChanged: () {
                      setState(() {});
                      widget.onCerrarSesion?.call();
                    },
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              SessionManager().cerrarSesion();
              widget.onCerrarSesion?.call();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildProductosTab(),
          _buildPedidosTab(),
          _buildUsuariosTab(),
          _buildDevolucionesTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _tabController.animateTo(index);
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white70,
        backgroundColor: AppTheme.primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_outlined),
            activeIcon: Icon(Icons.swap_horiz),
            label: 'Devoluciones',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 1: PRODUCTOS / INVENTARIO
  // ============================================================
  Widget _buildProductosTab() {
    final filtrados = _productos.where((p) {
      final matchText = p.nombre.toLowerCase().contains(_busquedaProducto.toLowerCase()) ||
          p.tipo.toLowerCase().contains(_busquedaProducto.toLowerCase());
      final matchCat = _categoriaProducto == 'Todas' || p.categoria.toLowerCase() == _categoriaProducto.toLowerCase();
      return matchText && matchCat;
    }).toList();

    final valorTotal = _productos.fold(0.0, (acc, p) => acc + (p.precio * (p.stock > 0 ? p.stock : 1)));
    final agotados = _productos.where((p) => p.stock == 0 || p.estado.toLowerCase() == 'agotado').length;
    final activos = _productos.where((p) => p.stock > 0 && p.estado.toLowerCase() == 'activo').length;

    return RefreshIndicator(
      onRefresh: _cargarProductos,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Métricas superiores
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _cardBox('Total Productos', '${_productos.length}', Icons.inventory_2_outlined, Colors.blue),
                _cardBox('Valor Catálogo', _formatearPrecio(valorTotal), Icons.payments_outlined, Colors.green),
                _cardBox('Disponibles', '$activos', Icons.check_circle_outline, Colors.teal),
                _cardBox('Agotados', '$agotados', Icons.cancel_outlined, Colors.red),
              ],
            ),
            const SizedBox(height: 18),

            // Filtros y Botón Nuevo
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o tipo...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _busquedaProducto = val),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _abrirModalProducto(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Lista / Tabla de Productos
            _cargandoProductos
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                : Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('PRODUCTO', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('CATEGORÍA', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('PRECIO', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('STOCK', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ESTADO', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtrados.map((prod) {
                          final colorEstado = prod.estado.toLowerCase() == 'activo'
                              ? Colors.green
                              : (prod.estado.toLowerCase() == 'agotado' ? Colors.red : Colors.orange);

                          return DataRow(cells: [
                            DataCell(Text('#${prod.id}')),
                            DataCell(Text(prod.nombre, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(prod.categoria)),
                            DataCell(Text(_formatearPrecio(prod.precio), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0047AB)))),
                            DataCell(Text('${prod.stock} uds', style: TextStyle(color: prod.stock > 0 ? const Color(0xFF00A896) : Colors.red, fontWeight: FontWeight.bold))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: colorEstado.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                child: Text(prod.estado, style: TextStyle(color: colorEstado, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue), onPressed: () => _abrirModalProducto(producto: prod)),
                                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _eliminarProducto(prod)),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _cardBox(String titulo, String valor, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = MediaQuery.of(context).size.width;
        final cardW = w < 600 ? (w - 44) / 2 : 180.0;
        return SizedBox(
          width: cardW,
          child: PanelTarjeta(titulo: titulo, valor: valor, icono: icon, colorIcono: color),
        );
      },
    );
  }

  void _abrirModalProducto({Producto? producto}) {
    final esEdicion = producto != null;
    final nombreCtrl = TextEditingController(text: producto?.nombre ?? '');
    final tipoCtrl = TextEditingController(text: producto?.tipo ?? '');
    final descCtrl = TextEditingController(text: producto?.descripcion ?? '');
    final precioCtrl = TextEditingController(text: producto != null ? producto.precio.toStringAsFixed(0) : '');
    final stockCtrl = TextEditingController(text: producto != null ? producto.stock.toString() : '10');
    final imagenCtrl = TextEditingController(text: producto?.imagen ?? '');

    int categoriaId = producto?.categoriaId ?? 1;
    String estado = producto?.estado ?? 'Activo';

    final categorias = [
      {'id': 1, 'nombre': 'Protección Corporal'},
      {'id': 2, 'nombre': 'Protección de Pies'},
      {'id': 3, 'nombre': 'Protección de Manos'},
      {'id': 4, 'nombre': 'Protección de Cabeza'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0047AB))),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del Producto *', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: tipoCtrl, decoration: const InputDecoration(labelText: 'Tipo / Subtipo', border: OutlineInputBorder()))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: categoriaId,
                              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                              items: categorias.map((c) => DropdownMenuItem<int>(value: c['id'] as int, child: Text(c['nombre'] as String, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => categoriaId = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: precioCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio (COP)', prefixText: '\$ ', border: OutlineInputBorder()))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: estado,
                        decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                          DropdownMenuItem(value: 'Agotado', child: Text('Agotado')),
                          DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => estado = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: imagenCtrl, decoration: const InputDecoration(labelText: 'URL de Imagen (Opcional)', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Descripción técnica', border: OutlineInputBorder())),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0047AB), foregroundColor: Colors.white),
                  onPressed: () async {
                    final nombre = nombreCtrl.text.trim();
                    final precio = double.tryParse(precioCtrl.text.trim()) ?? 0.0;
                    final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

                    if (nombre.isEmpty || precio <= 0) return;

                    final catNombre = categorias.firstWhere((c) => c['id'] == categoriaId, orElse: () => {'nombre': 'Protección Corporal'})['nombre'] as String;

                    Navigator.pop(ctx);

                    if (esEdicion) {
                      final act = producto.copyWith(
                        nombre: nombre,
                        tipo: tipoCtrl.text.trim(),
                        categoriaId: categoriaId,
                        categoria: catNombre,
                        precio: precio,
                        stock: stock,
                        estado: estado,
                        imagen: imagenCtrl.text.trim().isNotEmpty ? imagenCtrl.text.trim() : null,
                        descripcion: descCtrl.text.trim(),
                      );
                      await _productoService.actualizarProducto(act);
                    } else {
                      final nuevo = Producto(
                        id: 0,
                        nombre: nombre,
                        tipo: tipoCtrl.text.trim(),
                        categoriaId: categoriaId,
                        categoria: catNombre,
                        precio: precio,
                        stock: stock,
                        estado: estado,
                        imagen: imagenCtrl.text.trim().isNotEmpty ? imagenCtrl.text.trim() : null,
                        descripcion: descCtrl.text.trim(),
                      );
                      await _productoService.crearProducto(nuevo);
                    }
                    _cargarProductos();
                  },
                  child: Text(esEdicion ? 'Actualizar' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _eliminarProducto(Producto p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Deseas eliminar "${p.nombre}" de la base de datos MySQL?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _productoService.eliminarProducto(p.id);
              _cargarProductos();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 2: PEDIDOS Y FACTURACIÓN (LOGÍSTICA & CONTABILIDAD)
  // ============================================================
  Widget _buildPedidosTab() {
    return const HistorialComprasScreen(showAppBar: false);
  }


  // ============================================================
  // TAB 3: USUARIOS (CRUD MYSQL)
  // ============================================================
  Widget _buildUsuariosTab() {
    final filtrados = _usuarios.where((u) {
      return u.nombre.toLowerCase().contains(_busquedaUsuario.toLowerCase()) ||
          u.correo.toLowerCase().contains(_busquedaUsuario.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: _cargarUsuarios,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o correo...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _busquedaUsuario = val),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _abrirModalUsuario(),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _cargandoUsuarios
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                : Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('NOMBRE', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('CORREO', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ROL', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtrados.map((u) {
                          Color rolColor = Colors.green;
                          if (u.rol == 'Administrador') rolColor = Colors.red;
                          if (u.rol == 'Contador') rolColor = Colors.blue;

                          return DataRow(cells: [
                            DataCell(Text('#${u.id}')),
                            DataCell(Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(u.correo)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: rolColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                child: Text(u.rol, style: TextStyle(color: rolColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    onPressed: () => _eliminarUsuario(u),
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _abrirModalUsuario() {
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final claveCtrl = TextEditingController();
    int rol = 3; // 1: Admin, 2: Contador, 3: Cliente

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Crear Usuario en MySQL', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0047AB))),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombres *', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: apellidoCtrl, decoration: const InputDecoration(labelText: 'Apellidos *', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: correoCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo Electrónico *', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: claveCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña *', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: rol,
                        decoration: const InputDecoration(labelText: 'Rol en el Sistema', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Administrador')),
                          DropdownMenuItem(value: 2, child: Text('Contador')),
                          DropdownMenuItem(value: 3, child: Text('Cliente')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => rol = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0047AB), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nombreCtrl.text.isEmpty || correoCtrl.text.isEmpty || claveCtrl.text.isEmpty) return;
                    Navigator.pop(ctx);
                    await _adminService.crearUsuario(
                      nombres: nombreCtrl.text.trim(),
                      apellidos: apellidoCtrl.text.trim(),
                      correo: correoCtrl.text.trim(),
                      contrasena: claveCtrl.text.trim(),
                      rol: rol,
                    );
                    _cargarUsuarios();
                  },
                  child: const Text('Crear Usuario'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _eliminarUsuario(Usuario u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Deseas eliminar a ${u.nombre} (${u.correo})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _adminService.eliminarUsuario(u.id);
              _cargarUsuarios();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 4: DEVOLUCIONES
  // ============================================================
  Widget _buildDevolucionesTab() {
    return RefreshIndicator(
      onRefresh: _cargarDevoluciones,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _cardBox('Total Solicitudes', '${_devoluciones.length}', Icons.swap_horiz, Colors.blue),
                _cardBox('Pendientes', '${_devoluciones.where((d) => d.estado.toLowerCase() == 'pendiente').length}', Icons.pending_actions, Colors.amber),
                _cardBox('Aprobadas', '${_devoluciones.where((d) => d.estado.toLowerCase() == 'aprobada').length}', Icons.check_circle_outline, Colors.green),
                _cardBox('Rechazadas', '${_devoluciones.where((d) => d.estado.toLowerCase() == 'rechazada').length}', Icons.cancel_outlined, Colors.red),
              ],
            ),
            const SizedBox(height: 18),

            _cargandoDevoluciones
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                : _devoluciones.isEmpty
                    ? Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: const Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.swap_horiz_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No hay solicitudes de devolución registradas en MySQL', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    : Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('CLIENTE', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('PRODUCTO', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('CANT.', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('MOTIVO', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('ESTADO', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _devoluciones.map((dev) {
                              return DataRow(cells: [
                                DataCell(Text('#${dev.id}')),
                                DataCell(Text(dev.cliente)),
                                DataCell(Text(dev.producto, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text('${dev.cantidad}')),
                                DataCell(Text(dev.motivo)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: dev.estado.toLowerCase() == 'aprobada' ? Colors.green.withValues(alpha: 0.15) : (dev.estado.toLowerCase() == 'rechazada' ? Colors.red.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(dev.estado, style: TextStyle(color: dev.estado.toLowerCase() == 'aprobada' ? Colors.green.shade800 : (dev.estado.toLowerCase() == 'rechazada' ? Colors.red.shade800 : Colors.amber.shade900), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                                DataCell(
                                  dev.estado.toLowerCase() == 'pendiente'
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                              tooltip: 'Aprobar',
                                              onPressed: () async {
                                                await _adminService.aprobarDevolucion(dev.id);
                                                _cargarDevoluciones();
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                              tooltip: 'Rechazar',
                                              onPressed: () async {
                                                await _adminService.rechazarDevolucion(dev.id);
                                                _cargarDevoluciones();
                                              },
                                            ),
                                          ],
                                        )
                                      : const Text('-'),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
