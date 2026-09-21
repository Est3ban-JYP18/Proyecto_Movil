class Producto {
  final int id;
  final String nombre;
  final String tipo;
  final String descripcion;
  final double precio;
  final String? imagen;
  final String categoria;
  final int categoriaId;
  final String estado;
  final int stock;

  Producto({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.precio,
    this.imagen,
    required this.categoria,
    this.categoriaId = 1,
    this.estado = 'Activo',
    required this.stock,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: int.tryParse((json['idProductos'] ?? json['id'] ?? json['idProducto'] ?? 0).toString()) ?? 0,
      nombre: json['Nombre_Producto']?.toString() ?? json['nombre']?.toString() ?? '',
      tipo: json['Tipo']?.toString() ?? json['tipo']?.toString() ?? '',
      descripcion: json['Descripcion']?.toString() ?? json['descripcion']?.toString() ?? '',
      precio: double.tryParse((json['Precio'] ?? json['precio'] ?? 0).toString()) ?? 0.0,
      imagen: json['Imagen']?.toString() ?? json['imagen']?.toString(),
      categoria: json['Categoria']?.toString() ?? json['categoria']?.toString() ?? '',
      categoriaId: int.tryParse((json['Categoria_producto_idCategoria'] ?? json['categoriaId'] ?? 1).toString()) ?? 1,
      estado: json['Estado']?.toString() ?? json['estado']?.toString() ?? 'Activo',
      stock: int.tryParse((json['Stock'] ?? json['stock'] ?? json['Cantidad_Actual'] ?? 0).toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'idProductos': id,
      'Nombre_Producto': nombre,
      'nombre': nombre,
      'Tipo': tipo,
      'tipo': tipo,
      'Descripcion': descripcion,
      'descripcion': descripcion,
      'Precio': precio,
      'precio': precio,
      'Imagen': imagen,
      'imagen': imagen,
      'Estado': estado,
      'estado': estado,
      'Categoria_producto_idCategoria': categoriaId,
      'categoriaId': categoriaId,
      'Stock': stock,
      'stock': stock,
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
    String? estado,
    int? stock,
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
      estado: estado ?? this.estado,
      stock: stock ?? this.stock,
    );
  }
}