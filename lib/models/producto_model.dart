class Producto {
  final int id;
  final String nombre;
  final String tipo;
  final String descripcion;
  final double precio;
  final String? imagen;
  final String categoria;
  final int? categoriaId;
  final int stock;
  final String? marca;
  final String? material;
  final String? nivelProteccion;
  final int stockMinimo;
  final String estado;

  Producto({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.precio,
    this.imagen,
    required this.categoria,
    this.categoriaId,
    required this.stock,
    this.marca,
    this.material,
    this.nivelProteccion,
    this.stockMinimo = 5,
    this.estado = 'Activo',
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: int.tryParse(json['idProductos']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      nombre: json['Nombre_Producto']?.toString() ?? json['nombre']?.toString() ?? '',
      tipo: json['Tipo']?.toString() ?? json['tipo']?.toString() ?? 'Dotación',
      descripcion: json['Descripcion']?.toString() ?? json['descripcion']?.toString() ?? '',
      precio: double.tryParse(json['Precio']?.toString() ?? json['precio']?.toString() ?? '0') ?? 0.0,
      imagen: json['Imagen']?.toString() ?? json['imagen']?.toString(),
      categoria: json['Categoria']?.toString() ?? json['categoria']?.toString() ?? 'Sin categoría',
      categoriaId: int.tryParse(json['categoria_id']?.toString() ?? json['Categoria_producto_idCategoria']?.toString() ?? json['idCategorias']?.toString() ?? ''),
      stock: int.tryParse(json['Stock']?.toString() ?? json['stock']?.toString() ?? '0') ?? 0,
      marca: json['Marca']?.toString() ?? json['marca']?.toString() ?? 'Tecnomatic',
      material: json['Material']?.toString() ?? json['material']?.toString(),
      nivelProteccion: json['Nivel_Proteccion']?.toString() ?? json['nivelProteccion']?.toString() ?? json['nivel_proteccion']?.toString(),
      stockMinimo: int.tryParse(json['Stock_Minimo']?.toString() ?? json['stockMinimo']?.toString() ?? json['stock_minimo']?.toString() ?? '5') ?? 5,
      estado: json['Estado']?.toString() ?? json['estado']?.toString() ?? 'Activo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'precio': precio,
      'imagen': imagen,
      'categoria': categoria,
      'categoria_id': categoriaId,
      'stock': stock,
      'marca': marca,
      'material': material,
      'nivel_proteccion': nivelProteccion,
      'stock_minimo': stockMinimo,
      'estado': estado,
    };
  }

  Producto copyWith({
    int? id,
    String? nombre,
    String? tipo,
    String? descripcion,
    double? precio,
    String? imagen,
    String? categoria,
    int? categoriaId,
    int? stock,
    String? marca,
    String? material,
    String? nivelProteccion,
    int? stockMinimo,
    String? estado,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      imagen: imagen ?? this.imagen,
      categoria: categoria ?? this.categoria,
      categoriaId: categoriaId ?? this.categoriaId,
      stock: stock ?? this.stock,
      marca: marca ?? this.marca,
      material: material ?? this.material,
      nivelProteccion: nivelProteccion ?? this.nivelProteccion,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      estado: estado ?? this.estado,
    );
  }
}

class MovimientoInventario {
  final String tipoMovimiento; // Entrada, Salida
  final int cantidad;
  final DateTime? fecha;
  final String observacion;

  MovimientoInventario({
    required this.tipoMovimiento,
    required this.cantidad,
    this.fecha,
    required this.observacion,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['Fecha'] != null || json['fecha'] != null) {
      parsedDate = DateTime.tryParse(json['Fecha']?.toString() ?? json['fecha']?.toString() ?? '');
    }

    return MovimientoInventario(
      tipoMovimiento: json['Tipo_Movimiento']?.toString() ?? json['tipo_movimiento']?.toString() ?? 'Entrada',
      cantidad: int.tryParse(json['Cantidad']?.toString() ?? json['cantidad']?.toString() ?? '0') ?? 0,
      fecha: parsedDate,
      observacion: json['Observacion']?.toString() ?? json['observacion']?.toString() ?? 'Sin observación',
    );
  }
}

class CategoriaProducto {
  final int id;
  final String nombre;

  CategoriaProducto({
    required this.id,
    required this.nombre,
  });

  factory CategoriaProducto.fromJson(Map<String, dynamic> json) {
    return CategoriaProducto(
      id: int.tryParse(json['id']?.toString() ?? json['idCategorias']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString() ?? json['Nombre']?.toString() ?? '',
    );
  }
}