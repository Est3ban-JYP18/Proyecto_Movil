class PedidoModel {
  final int id;
  final String cliente;
  final String fecha;
  final double total;
  final String estado;
  final String estadoEntrega;
  final String? correo;
  final String? telefono;
  final dynamic usuarioId;

  PedidoModel({
    required this.id,
    required this.cliente,
    required this.fecha,
    required this.total,
    required this.estado,
    this.estadoEntrega = 'En Proceso',
    this.correo,
    this.telefono,
    this.usuarioId,
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    // Resolver nombre del cliente (soporte join con usuarios)
    String clienteNombre = json['cliente']?.toString() ?? '';
    if (clienteNombre.isEmpty && json['usuarios'] is Map) {
      final u = json['usuarios'] as Map;
      final nom = u['nombres']?.toString() ?? '';
      final ape = u['apellidos']?.toString() ?? '';
      clienteNombre = '$nom $ape'.trim();
    } else if (clienteNombre.isEmpty && json['Nombres'] != null) {
      final nombres = json['Nombres']?.toString() ?? '';
      final apellidos = json['Apellidos']?.toString() ?? '';
      clienteNombre = '$nombres $apellidos'.trim();
    }

    String? clienteCorreo = json['correo']?.toString() ??
        json['Correo']?.toString() ??
        (json['usuarios'] is Map ? json['usuarios']['correo']?.toString() : null);

    String? clienteTelefono = json['telefono']?.toString() ??
        json['Telefono']?.toString() ??
        (json['usuarios'] is Map ? json['usuarios']['telefono']?.toString() : null);

    // Resolver estado de entrega si viene embebido
    String resolvedEntrega = 'En Proceso';
    if (json['entregas'] is List && (json['entregas'] as List).isNotEmpty) {
      resolvedEntrega = json['entregas'][0]['estado_entrega']?.toString() ?? 'En Proceso';
    } else if (json['estado_entrega'] != null || json['Estado_Entrega'] != null) {
      resolvedEntrega = (json['estado_entrega'] ?? json['Estado_Entrega']).toString();
    }

    return PedidoModel(
      id: int.tryParse((json['id'] ?? json['idFacturas'] ?? 0).toString()) ?? 0,
      cliente: clienteNombre.isNotEmpty ? clienteNombre : 'Cliente Registrado',
      fecha: json['fecha']?.toString() ?? json['Fecha']?.toString() ?? json['created_at']?.toString() ?? '',
      total: double.tryParse((json['total'] ?? json['Total'] ?? 0).toString()) ?? 0.0,
      estado: json['estado']?.toString() ?? json['Estado']?.toString() ?? 'Pendiente',
      estadoEntrega: resolvedEntrega,
      correo: clienteCorreo,
      telefono: clienteTelefono,
      usuarioId: json['usuario_id'] ?? json['Usuarios_idUsuarios'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente': cliente,
      'fecha': fecha,
      'total': total,
      'estado': estado,
      'estado_entrega': estadoEntrega,
      'correo': correo,
      'telefono': telefono,
      'usuario_id': usuarioId,
    };
  }
}

class PedidoDetalleItem {
  final int idProducto;
  final String nombreProducto;
  final String? imagen;
  final int cantidad;
  final double precioUnitario;
  final String? talla;
  final String? color;

  PedidoDetalleItem({
    required this.idProducto,
    required this.nombreProducto,
    this.imagen,
    required this.cantidad,
    required this.precioUnitario,
    this.talla,
    this.color,
  });

  double get subtotal => cantidad * precioUnitario;

  factory PedidoDetalleItem.fromJson(Map<String, dynamic> json) {
    String nombre = json['nombre_producto']?.toString() ??
        json['Nombre_Producto']?.toString() ??
        json['nombre']?.toString() ??
        '';

    String? img = json['imagen']?.toString() ?? json['Imagen']?.toString();

    // Si viene anidado en el join de Supabase con `productos`
    if (json['productos'] is Map) {
      final p = json['productos'] as Map;
      if (nombre.isEmpty) {
        nombre = p['nombre_producto']?.toString() ?? p['nombre']?.toString() ?? 'Producto';
      }
      img ??= p['imagen']?.toString();
    }

    return PedidoDetalleItem(
      idProducto: int.tryParse((json['Productos_idProductos'] ??
              json['Productos_idProducto'] ??
              json['idProductos'] ??
              json['producto_id'] ??
              json['idProducto'] ??
              json['id'] ??
              0)
          .toString()) ??
          0,
      nombreProducto: nombre.isNotEmpty ? nombre : 'Producto',
      imagen: img,
      cantidad: int.tryParse((json['cantidad'] ?? json['Cantidad'] ?? 1).toString()) ?? 1,
      precioUnitario: double.tryParse((json['precio_unitario'] ?? json['Precio_Unitario'] ?? json['precio'] ?? 0).toString()) ?? 0.0,
      talla: json['talla']?.toString() ?? json['Talla']?.toString(),
      color: json['color']?.toString() ?? json['Color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'producto_id': idProducto,
      'nombre_producto': nombreProducto,
      'imagen': imagen,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'talla': talla,
      'color': color,
    };
  }
}

class PedidoSeguimiento {
  final int? idEntrega;
  final String? fechaEntrega;
  final String estadoEntrega;
  final String observaciones;
  final String? transportadora;
  final String? numeroGuia;
  final String? estadoFactura;

  PedidoSeguimiento({
    this.idEntrega,
    this.fechaEntrega,
    required this.estadoEntrega,
    required this.observaciones,
    this.transportadora,
    this.numeroGuia,
    this.estadoFactura,
  });

  factory PedidoSeguimiento.fromJson(Map<String, dynamic> json) {
    return PedidoSeguimiento(
      idEntrega: int.tryParse((json['id'] ?? json['idEntregas'] ?? 0).toString()),
      fechaEntrega: json['fecha_entrega']?.toString() ?? json['Fecha_entrega']?.toString(),
      estadoEntrega: json['estado_entrega']?.toString() ?? json['Estado_Entrega']?.toString() ?? 'En Proceso',
      observaciones: json['observaciones']?.toString() ?? json['Observaciones']?.toString() ?? 'El pedido está siendo procesado en bodega.',
      transportadora: json['transportadora']?.toString(),
      numeroGuia: json['numero_guia']?.toString(),
      estadoFactura: json['estado_factura']?.toString() ?? json['EstadoFactura']?.toString(),
    );
  }
}
