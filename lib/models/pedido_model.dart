class PedidoModel {
  final int id;
  final String cliente;
  final String fecha;
  final double total;
  final String estado;
  final String estadoEntrega;

  PedidoModel({
    required this.id,
    required this.cliente,
    required this.fecha,
    required this.total,
    required this.estado,
    this.estadoEntrega = 'En Proceso',
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    // Resolver nombre del cliente
    String clienteNombre = json['cliente']?.toString() ?? '';
    if (clienteNombre.isEmpty && json['Nombres'] != null) {
      final nombres = json['Nombres']?.toString() ?? '';
      final apellidos = json['Apellidos']?.toString() ?? '';
      clienteNombre = '$nombres $apellidos'.trim();
    }

    return PedidoModel(
      id: int.tryParse((json['idFacturas'] ?? json['id'] ?? 0).toString()) ?? 0,
      cliente: clienteNombre.isNotEmpty ? clienteNombre : 'Cliente #${json['Usuarios_idUsuarios'] ?? ""}',
      fecha: json['Fecha']?.toString() ?? json['fecha']?.toString() ?? '',
      total: double.tryParse((json['Total'] ?? json['total'] ?? 0).toString()) ?? 0.0,
      estado: json['Estado']?.toString() ?? json['estado']?.toString() ?? 'Pendiente',
      estadoEntrega: json['Estado_Entrega']?.toString() ?? 'En Proceso',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente': cliente,
      'fecha': fecha,
      'total': total,
      'estado': estado,
      'estadoEntrega': estadoEntrega,
    };
  }
}

class PedidoDetalleItem {
  final int idProducto;
  final String nombreProducto;
  final String? imagen;
  final int cantidad;
  final double precioUnitario;

  PedidoDetalleItem({
    required this.idProducto,
    required this.nombreProducto,
    this.imagen,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;

  factory PedidoDetalleItem.fromJson(Map<String, dynamic> json) {
    return PedidoDetalleItem(
      idProducto: int.tryParse((json['idProductos'] ?? json['idProducto'] ?? 0).toString()) ?? 0,
      nombreProducto: json['Nombre_Producto']?.toString() ?? json['nombre'] ?? 'Producto',
      imagen: json['Imagen']?.toString() ?? json['imagen']?.toString(),
      cantidad: int.tryParse((json['Cantidad'] ?? json['cantidad'] ?? 1).toString()) ?? 1,
      precioUnitario: double.tryParse((json['Precio_Unitario'] ?? json['precio'] ?? 0).toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idProductos': idProducto,
      'Nombre_Producto': nombreProducto,
      'Imagen': imagen,
      'Cantidad': cantidad,
      'Precio_Unitario': precioUnitario,
    };
  }
}

class PedidoSeguimiento {
  final int? idEntrega;
  final String? fechaEntrega;
  final String estadoEntrega;
  final String observaciones;
  final String? estadoFactura;

  PedidoSeguimiento({
    this.idEntrega,
    this.fechaEntrega,
    required this.estadoEntrega,
    required this.observaciones,
    this.estadoFactura,
  });

  factory PedidoSeguimiento.fromJson(Map<String, dynamic> json) {
    return PedidoSeguimiento(
      idEntrega: int.tryParse((json['idEntregas'] ?? 0).toString()),
      fechaEntrega: json['Fecha_entrega']?.toString(),
      estadoEntrega: json['Estado_Entrega']?.toString() ?? 'En Proceso',
      observaciones: json['Observaciones']?.toString() ?? 'El pedido está siendo procesado en bodega.',
      estadoFactura: json['EstadoFactura']?.toString(),
    );
  }
}

