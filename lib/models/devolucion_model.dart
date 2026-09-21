class DevolucionModel {
  final int id;
  final int facturaId;
  final String cliente;
  final String producto;
  final int cantidad;
  final String motivo;
  final String estado;
  final String fecha;
  final String? comentariosAdmin;
  final String? codigoCupon;
  final String estadoTracking;

  DevolucionModel({
    required this.id,
    required this.facturaId,
    required this.cliente,
    required this.producto,
    required this.cantidad,
    required this.motivo,
    required this.estado,
    required this.fecha,
    this.comentariosAdmin,
    this.codigoCupon,
    this.estadoTracking = 'Solicitada',
  });

  factory DevolucionModel.fromJson(Map<String, dynamic> json) {
    String clienteNombre = json['cliente']?.toString() ?? '';
    if (clienteNombre.isEmpty && json['Nombres'] != null) {
      final nombres = json['Nombres']?.toString() ?? '';
      final apellidos = json['Apellidos']?.toString() ?? '';
      clienteNombre = '$nombres $apellidos'.trim();
    }

    return DevolucionModel(
      id: int.tryParse((json['idDevoluciones'] ?? json['id'] ?? 0).toString()) ?? 0,
      facturaId: int.tryParse((json['Facturas_idFacturas'] ?? json['facturaId'] ?? 0).toString()) ?? 0,
      cliente: clienteNombre.isNotEmpty ? clienteNombre : 'Cliente #${json['Usuarios_idUsuarios'] ?? ""}',
      producto: json['Nombre_Producto']?.toString() ?? json['producto']?.toString() ?? 'Producto',
      cantidad: int.tryParse((json['Cantidad'] ?? json['cantidad'] ?? 1).toString()) ?? 1,
      motivo: json['Motivo']?.toString() ?? json['motivo']?.toString() ?? 'Sin motivo especificado',
      estado: json['Estado']?.toString() ?? json['estado']?.toString() ?? 'Pendiente',
      fecha: json['Fecha']?.toString() ?? json['fecha']?.toString() ?? '',
      comentariosAdmin: json['Comentarios_Admin']?.toString(),
      codigoCupon: json['Codigo_Cupon']?.toString(),
      estadoTracking: json['Estado_Tracking']?.toString() ?? 'Solicitada',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facturaId': facturaId,
      'cliente': cliente,
      'producto': producto,
      'cantidad': cantidad,
      'motivo': motivo,
      'estado': estado,
      'fecha': fecha,
      'comentariosAdmin': comentariosAdmin,
      'codigoCupon': codigoCupon,
      'estadoTracking': estadoTracking,
    };
  }
}
