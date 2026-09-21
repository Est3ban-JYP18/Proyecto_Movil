import 'package:flutter/material.dart';
import '../../models/producto_model.dart';
import '../../services/producto_service.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ProductoService _productoService = ProductoService();

  List<Producto> _productos = [];
  List<CategoriaProducto> _categorias = [];
  bool _loading = true;
  String? _error;

  // Filtros
  String _busqueda = '';
  String _filtroEstado = '';
  String _filtroCategoria = '';
  double? _precioMinimo;
  double? _precioMaximo;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resultados = await Future.wait([
        _productoService.obtenerProductos(),
        _productoService.obtenerCategorias(),
      ]);

      if (!mounted) return;

      setState(() {
        _productos = resultados[0] as List<Producto>;
        _categorias = resultados[1] as List<CategoriaProducto>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  // Formato Moneda COP (ej. $ 45.000)
  String _formatoMoneda(double valor) {
    final entero = valor.round().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = entero.length - 1; i >= 0; i--) {
      buffer.write(entero[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '\$ ${buffer.toString().split('').reversed.join('')}';
  }

  // Filtrado de productos en memoria
  List<Producto> get _productosFiltrados {
    return _productos.where((p) {
      final coincideNombre = _busqueda.isEmpty ||
          p.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
          (p.marca != null && p.marca!.toLowerCase().contains(_busqueda.toLowerCase()));

      final coincideEstado = _filtroEstado.isEmpty ||
          p.estado.toLowerCase() == _filtroEstado.toLowerCase() ||
          (_filtroEstado == 'Activo' && (p.estado.toLowerCase() == 'disponible' || p.estado.toLowerCase() == 'activo'));

      final coincideCategoria = _filtroCategoria.isEmpty ||
          p.categoria.toLowerCase() == _filtroCategoria.toLowerCase();

      final coincideMin = _precioMinimo == null || p.precio >= _precioMinimo!;
      final coincideMax = _precioMaximo == null || p.precio <= _precioMaximo!;

      return coincideNombre && coincideEstado && coincideCategoria && coincideMin && coincideMax;
    }).toList();
  }

  // Estadísticas KPI
  int get _totalProductos => _productos.length;
  double get _valorInventario => _productos.fold(0.0, (sum, p) => sum + (p.precio * p.stock));
  int get _agotados => _productos.where((p) => p.stock == 0).length;
  int get _bajoStock => _productos.where((p) => p.stock >= 1 && p.stock <= p.stockMinimo).length;

  // ============================================================
  // AGREGAR PRODUCTO (SweetAlert2 Style)
  // ============================================================
  void _mostrarDialogoAgregar() {
    final nombreCtrl = TextEditingController();
    final tipoCtrl = TextEditingController(text: 'Dotación');
    final descCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');
    final marcaCtrl = TextEditingController(text: 'Tecnomatic');
    final stockMinCtrl = TextEditingController(text: '5');
    final imagenCtrl = TextEditingController();

    int? categoriaSeleccionada = _categorias.isNotEmpty ? _categorias.first.id : 1;
    String estadoSeleccionado = 'Activo';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              title: const Row(
                children: [
                  Icon(Icons.add_box_rounded, color: Color(0xFF0047AB), size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Agregar Producto',
                    style: TextStyle(
                      color: Color(0xFF0047AB),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Nombre del Producto *'),
                      TextField(
                        controller: nombreCtrl,
                        decoration: _inputDecoration('Ej. Guantes de Nitrilo'),
                      ),
                      const SizedBox(height: 12),

                      _buildInputLabel('Tipo'),
                      TextField(
                        controller: tipoCtrl,
                        decoration: _inputDecoration('Ej. Uniformes / Protección'),
                      ),
                      const SizedBox(height: 12),

                      _buildInputLabel('Descripción'),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: _inputDecoration('Detalles técnicos...'),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Precio (\$ COP) *'),
                                TextField(
                                  controller: precioCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Ej. 45000'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Stock Inicial'),
                                TextField(
                                  controller: stockCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Ej. 10'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Marca'),
                                TextField(
                                  controller: marcaCtrl,
                                  decoration: _inputDecoration('Ej. 3M / Steelpro'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Stock Mínimo'),
                                TextField(
                                  controller: stockMinCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Ej. 5'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildInputLabel('Ruta / URL Imagen'),
                      TextField(
                        controller: imagenCtrl,
                        decoration: _inputDecoration('https://... o ruta'),
                      ),
                      const SizedBox(height: 12),

                      _buildInputLabel('Categoría *'),
                      DropdownButtonFormField<int>(
                        initialValue: categoriaSeleccionada,
                        decoration: _inputDecoration('Selecciona una categoría'),
                        items: _categorias.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Text(cat.nombre),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => categoriaSeleccionada = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildInputLabel('Estado'),
                      DropdownButtonFormField<String>(
                        initialValue: estadoSeleccionado,
                        decoration: _inputDecoration('Estado del producto'),
                        items: const [
                          DropdownMenuItem(value: 'Activo', child: Text('Disponible')),
                          DropdownMenuItem(value: 'Agotado', child: Text('Agotado')),
                          DropdownMenuItem(value: 'Inactivo', child: Text('No disponible')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => estadoSeleccionado = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.all(16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20B2AA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    final nombre = nombreCtrl.text.trim();
                    final precio = double.tryParse(precioCtrl.text.trim());

                    if (nombre.isEmpty || precio == null || categoriaSeleccionada == null) {
                      _mostrarAlerta('Validación', 'Nombre, precio y categoría son obligatorios', Colors.orange);
                      return;
                    }

                    final catObj = _categorias.firstWhere(
                      (c) => c.id == categoriaSeleccionada,
                      orElse: () => CategoriaProducto(id: categoriaSeleccionada!, nombre: 'General'),
                    );

                    try {
                      await _productoService.crearProducto({
                        'nombre': nombre,
                        'tipo': tipoCtrl.text.trim().isNotEmpty ? tipoCtrl.text.trim() : 'Dotación',
                        'descripcion': descCtrl.text.trim(),
                        'precio': precio,
                        'stock': int.tryParse(stockCtrl.text.trim()) ?? 0,
                        'marca': marcaCtrl.text.trim().isNotEmpty ? marcaCtrl.text.trim() : 'Tecnomatic',
                        'stockMinimo': int.tryParse(stockMinCtrl.text.trim()) ?? 5,
                        'imagen': imagenCtrl.text.trim(),
                        'categoria': categoriaSeleccionada,
                        'categoriaNombre': catObj.nombre,
                        'estado': estadoSeleccionado,
                      });

                      if (!dialogCtx.mounted) return;
                      Navigator.pop(dialogCtx);
                      _mostrarAlerta('¡Producto Creado!', 'El producto se ha guardado exitosamente.', const Color(0xFF20B2AA));
                      _cargarDatos();
                    } catch (e) {
                      if (!dialogCtx.mounted) return;
                      _mostrarAlerta('Error', e.toString().replaceAll('Exception: ', ''), Colors.red);
                    }
                  },
                  child: const Text('Guardar Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EDITAR PRODUCTO (SweetAlert2 Style)
  // ============================================================
  void _mostrarDialogoEditar(Producto prod) {
    final nombreCtrl = TextEditingController(text: prod.nombre);
    final tipoCtrl = TextEditingController(text: prod.tipo);
    final descCtrl = TextEditingController(text: prod.descripcion);
    final precioCtrl = TextEditingController(text: prod.precio.toStringAsFixed(0));
    final stockCtrl = TextEditingController(text: prod.stock.toString());
    final marcaCtrl = TextEditingController(text: prod.marca ?? 'Tecnomatic');
    final stockMinCtrl = TextEditingController(text: prod.stockMinimo.toString());
    final imagenCtrl = TextEditingController(text: prod.imagen ?? '');

    int? categoriaSeleccionada = prod.categoriaId;
    if (categoriaSeleccionada == null && _categorias.isNotEmpty) {
      final match = _categorias.where((c) => c.nombre.toLowerCase() == prod.categoria.toLowerCase());
      if (match.isNotEmpty) {
        categoriaSeleccionada = match.first.id;
      } else {
        categoriaSeleccionada = _categorias.first.id;
      }
    }

    String estadoSeleccionado = (prod.estado == 'Disponible' || prod.estado == 'Activo')
        ? 'Activo'
        : (prod.estado == 'Agotado' ? 'Agotado' : 'Inactivo');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              title: const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: Color(0xFF0047AB), size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Editar Producto',
                    style: TextStyle(
                      color: Color(0xFF0047AB),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Nombre del Producto *'),
                      TextField(
                        controller: nombreCtrl,
                        decoration: _inputDecoration('Nombre'),
                      ),
                      const SizedBox(height: 12),

                      _buildInputLabel('Tipo'),
                      TextField(
                        controller: tipoCtrl,
                        decoration: _inputDecoration('Tipo'),
                      ),
                      const SizedBox(height: 12),

                      _buildInputLabel('Descripción'),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: _inputDecoration('Descripción'),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Precio (\$ COP) *'),
                                TextField(
                                  controller: precioCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Precio'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Stock'),
                                TextField(
                                  controller: stockCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Stock'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Marca'),
                                TextField(
                                  controller: marcaCtrl,
                                  decoration: _inputDecoration('Marca'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Stock Mínimo'),
                                TextField(
                                  controller: stockMinCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Stock Mínimo'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildInputLabel('Ruta / URL Imagen'),
                      TextField(
                        controller: imagenCtrl,
                        decoration: _inputDecoration('URL Imagen'),
                      ),
                      const SizedBox(height: 12),

                      _buildInputLabel('Categoría *'),
                      DropdownButtonFormField<int>(
                        initialValue: categoriaSeleccionada,
                        decoration: _inputDecoration('Categoría'),
                        items: _categorias.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Text(cat.nombre),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => categoriaSeleccionada = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildInputLabel('Estado'),
                      DropdownButtonFormField<String>(
                        initialValue: estadoSeleccionado,
                        decoration: _inputDecoration('Estado'),
                        items: const [
                          DropdownMenuItem(value: 'Activo', child: Text('Disponible')),
                          DropdownMenuItem(value: 'Agotado', child: Text('Agotado')),
                          DropdownMenuItem(value: 'Inactivo', child: Text('No disponible')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => estadoSeleccionado = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.all(16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20B2AA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    final nombre = nombreCtrl.text.trim();
                    final precio = double.tryParse(precioCtrl.text.trim());

                    if (nombre.isEmpty || precio == null) {
                      _mostrarAlerta('Validación', 'Por favor completa los campos requeridos', Colors.orange);
                      return;
                    }

                    final catObj = _categorias.firstWhere(
                      (c) => c.id == categoriaSeleccionada,
                      orElse: () => CategoriaProducto(id: categoriaSeleccionada ?? 1, nombre: prod.categoria),
                    );

                    try {
                      await _productoService.actualizarProducto(prod.id, {
                        'nombre': nombre,
                        'tipo': tipoCtrl.text.trim(),
                        'descripcion': descCtrl.text.trim(),
                        'precio': precio,
                        'stock': int.tryParse(stockCtrl.text.trim()) ?? 0,
                        'marca': marcaCtrl.text.trim(),
                        'stockMinimo': int.tryParse(stockMinCtrl.text.trim()) ?? 5,
                        'imagen': imagenCtrl.text.trim(),
                        'categoria': categoriaSeleccionada,
                        'categoriaNombre': catObj.nombre,
                        'estado': estadoSeleccionado,
                      });

                      if (!dialogCtx.mounted) return;
                      Navigator.pop(dialogCtx);
                      _mostrarAlerta('¡Producto Actualizado!', 'Los cambios se han sincronizado correctamente.', const Color(0xFF20B2AA));
                      _cargarDatos();
                    } catch (e) {
                      if (!dialogCtx.mounted) return;
                      _mostrarAlerta('Error', e.toString().replaceAll('Exception: ', ''), Colors.red);
                    }
                  },
                  child: const Text('Actualizar Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FICHA TÉCNICA & VARIANTES
  // ============================================================
  void _mostrarFichaTecnica(Producto prod) async {
    final marcaCtrl = TextEditingController(text: prod.marca ?? 'Tecnomatic');
    final materialCtrl = TextEditingController(text: prod.material ?? '');
    final proteccionCtrl = TextEditingController(text: prod.nivelProteccion ?? '');
    final stockMinCtrl = TextEditingController(text: prod.stockMinimo.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          title: Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: Color(0xFF0047AB), size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ficha Técnica: ${prod.nombre}',
                  style: const TextStyle(color: Color(0xFF0047AB), fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputLabel('Marca Fabricante'),
                TextField(controller: marcaCtrl, decoration: _inputDecoration('Ej. 3M / Steelpro')),
                const SizedBox(height: 12),

                _buildInputLabel('Material de Fabricación'),
                TextField(controller: materialCtrl, decoration: _inputDecoration('Ej. Poliéster / Nitrilo / Cuero')),
                const SizedBox(height: 12),

                _buildInputLabel('Nivel / Certificación de Protección'),
                TextField(controller: proteccionCtrl, decoration: _inputDecoration('Ej. ANSI Z87.1 / CE EN 388')),
                const SizedBox(height: 12),

                _buildInputLabel('Stock Mínimo para Alertas'),
                TextField(
                  controller: stockMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Ej. 5'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20B2AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                try {
                  await _productoService.guardarCatalogoDetallado(prod.id, {
                    'atributos': {
                      'marca': marcaCtrl.text.trim(),
                      'material': materialCtrl.text.trim(),
                      'nivelProteccion': proteccionCtrl.text.trim(),
                      'stockMinimo': int.tryParse(stockMinCtrl.text.trim()) ?? 5,
                    },
                  });

                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  _mostrarAlerta('Guardado', 'Ficha técnica guardada correctamente.', const Color(0xFF20B2AA));
                  _cargarDatos();
                } catch (e) {
                  if (!dialogCtx.mounted) return;
                  _mostrarAlerta('Error', 'No se pudo actualizar la ficha técnica.', Colors.red);
                }
              },
              child: const Text('Guardar Ficha Técnica'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HISTORIAL DE MOVIMIENTOS (KÁRDEX)
  // ============================================================
  void _mostrarHistorialMovimientos(Producto prod) async {
    showDialog(
      context: context,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    List<MovimientoInventario> movimientos = [];
    try {
      movimientos = await _productoService.obtenerMovimientosInventario(prod.id);
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context); // Cierra loader

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          title: Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF0047AB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Movimientos: ${prod.nombre}',
                  style: const TextStyle(color: Color(0xFF0047AB), fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: movimientos.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No hay movimientos registrados para este producto.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1.2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(3),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(color: Colors.grey.shade200),
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey.shade100),
                          children: const [
                            Padding(padding: EdgeInsets.all(8), child: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Cant.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Observación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                        ...movimientos.map((m) {
                          final esEntrada = m.tipoMovimiento.toLowerCase().contains('entrada');
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  m.tipoMovimiento,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: esEntrada ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('${m.cantidad}', style: const TextStyle(fontSize: 12)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  m.fecha != null
                                      ? '${m.fecha!.day}/${m.fecha!.month}/${m.fecha!.year}'
                                      : 'Sin fecha',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(m.observacion, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0047AB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ELIMINAR PRODUCTO (SweetAlert2 Style)
  // ============================================================
  void _confirmarEliminarProducto(Producto prod) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                '¿Enviar a papelera?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            'El producto "${prod.nombre}" se ocultará del catálogo y se registrará en la papelera.',
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC3545),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                try {
                  await _productoService.eliminarProductoPapelera(prod.id);
                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  _mostrarAlerta('Producto en Papelera', 'El producto ha sido enviado a la papelera.', const Color(0xFF20B2AA));
                  _cargarDatos();
                } catch (e) {
                  if (!dialogCtx.mounted) return;
                  _mostrarAlerta('Error', 'No se pudo eliminar el producto.', Colors.red);
                }
              },
              child: const Text('Sí, mover a papelera'),
            ),
          ],
        );
      },
    );
  }

  // Helper alert SnackBar
  void _mostrarAlerta(String titulo, String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            Text(mensaje, style: const TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // Helpers de estilos para inputs
  Widget _buildInputLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0047AB), width: 1.5),
      ),
    );
  }

  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Catálogo e Inventario'),
        backgroundColor: const Color(0xFF0F2C59),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENCABEZADO CON BOTÓN AGREGAR
              _buildHeader(),
              const SizedBox(height: 16),

              // TARJETAS KPI / ESTADÍSTICAS
              _buildMetricCards(),
              const SizedBox(height: 20),

              // SECCIÓN DE FILTROS
              _buildFiltersSection(),
              const SizedBox(height: 16),

              // LISTA / TABLA DE PRODUCTOS
              _buildProductosList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF20B2AA),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _mostrarDialogoAgregar,
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  '📦 CRUD de Catálogo e Inventario',
                  style: TextStyle(
                    color: Color(0xFF0047AB),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20B2AA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Agregar Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _mostrarDialogoAgregar,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Gestiona productos, fichas técnicas, stocks y kárdex en tiempo real.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Tarjetas KPI
  Widget _buildMetricCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 2.2 : 1.8,
          children: [
            _buildKpiCard(
              icon: Icons.inventory_2_outlined,
              label: 'Total Productos',
              value: '$_totalProductos',
              color: const Color(0xFF0047AB),
            ),
            _buildKpiCard(
              icon: Icons.attach_money_rounded,
              label: 'Valor de Inventario',
              value: _formatoMoneda(_valorInventario),
              color: const Color(0xFF059669),
            ),
            _buildKpiCard(
              icon: Icons.cancel_outlined,
              label: 'Agotados',
              value: '$_agotados',
              color: const Color(0xFFDC3545),
            ),
            _buildKpiCard(
              icon: Icons.warning_amber_rounded,
              label: 'Bajo Stock',
              value: '$_bajoStock',
              color: const Color(0xFFD97706),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filtros
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Buscador
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o marca...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _busqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _busqueda = '';
                        });
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => setState(() => _busqueda = val),
          ),
          const SizedBox(height: 10),

          // Filtros de Estado y Categoría
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filtroEstado,
                  isDense: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todos los estados', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Activo', child: Text('Activo / Disponible', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Agotado', child: Text('Agotado', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) => setState(() => _filtroEstado = val ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filtroCategoria,
                  isDense: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Todas las categorías', style: TextStyle(fontSize: 12))),
                    ..._categorias.map((cat) => DropdownMenuItem(
                          value: cat.nombre,
                          child: Text(cat.nombre, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (val) => setState(() => _filtroCategoria = val ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filtros de Precio Min y Max
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Min \$',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _precioMinimo = double.tryParse(val);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Max \$',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _precioMaximo = double.tryParse(val);
                    });
                  },
                ),
              ),
              if (_busqueda.isNotEmpty || _filtroEstado.isNotEmpty || _filtroCategoria.isNotEmpty || _precioMinimo != null || _precioMaximo != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Limpiar filtros',
                  icon: const Icon(Icons.filter_alt_off, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _minPriceController.clear();
                      _maxPriceController.clear();
                      _busqueda = '';
                      _filtroEstado = '';
                      _filtroCategoria = '';
                      _precioMinimo = null;
                      _precioMaximo = null;
                    });
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Lista de Productos
  Widget _buildProductosList() {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: const Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF0047AB)),
            SizedBox(height: 12),
            Text('Cargando catálogo...', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 10),
            Text('Error al cargar datos:\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final lista = _productosFiltrados;

    if (lista.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.shopping_basket_outlined, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text('No se encontraron productos coincidentes.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final p = lista[index];
        return _buildProductCard(p);
      },
    );
  }

  // Tarjeta de Producto individual
  Widget _buildProductCard(Producto p) {
    final esAgotado = p.stock == 0;
    final esBajoStock = p.stock <= p.stockMinimo && !esAgotado;
    final colorStock = esAgotado
        ? const Color(0xFFDC3545)
        : esBajoStock
            ? const Color(0xFFD97706)
            : const Color(0xFF059669);

    final esDisponible = p.estado == 'Activo' || p.estado == 'Disponible';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen miniatura
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 58,
                    height: 58,
                    color: Colors.grey.shade100,
                    child: p.imagen != null && p.imagen!.isNotEmpty
                        ? Image.network(
                            p.imagen!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, color: Colors.grey),
                          )
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),

                // Info principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                      ),
                      if (p.marca != null && p.marca!.isNotEmpty)
                        Text(
                          'Marca: ${p.marca}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.categoria,
                              style: TextStyle(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatoMoneda(p.precio),
                            style: const TextStyle(
                              color: Color(0xFF0047AB),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badges de Stock y Estado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.stock} uds',
                      style: TextStyle(color: colorStock, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: esDisponible
                            ? const Color(0xFFECFDF5)
                            : esAgotado
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: esDisponible
                              ? const Color(0xFFA7F3D0)
                              : esAgotado
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        esDisponible
                            ? 'Disponible'
                            : esAgotado
                                ? 'Agotado'
                                : 'No disponible',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: esDisponible
                              ? const Color(0xFF047857)
                              : esAgotado
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 18),

            // BOTONES DE ACCIONES
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 1. Ficha Técnica
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.assignment_outlined, size: 15),
                  label: const Text('Ficha', style: TextStyle(fontSize: 11)),
                  onPressed: () => _mostrarFichaTecnica(p),
                ),
                const SizedBox(width: 6),

                // 2. Historial de movimientos
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    side: const BorderSide(color: Color(0xFF9CA3AF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.history, size: 15),
                  label: const Text('Kárdex', style: TextStyle(fontSize: 11)),
                  onPressed: () => _mostrarHistorialMovimientos(p),
                ),
                const SizedBox(width: 6),

                // 3. Editar
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0047AB),
                    side: const BorderSide(color: Color(0xFF0047AB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Editar', style: TextStyle(fontSize: 11)),
                  onPressed: () => _mostrarDialogoEditar(p),
                ),
                const SizedBox(width: 6),

                // 4. Eliminar / Papelera
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC3545),
                    side: const BorderSide(color: Color(0xFFDC3545)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _confirmarEliminarProducto(p),
                  child: const Icon(Icons.delete_outline, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
