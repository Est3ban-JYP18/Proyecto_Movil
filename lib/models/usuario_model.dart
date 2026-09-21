class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final nombres = json['Nombres']?.toString() ?? '';
    final apellidos = json['Apellidos']?.toString() ?? '';

    return Usuario(
      id: int.tryParse(
            (json['idUsuarios'] ?? 0).toString(),
          ) ??
          0,
      nombre: '$nombres $apellidos'.trim(),
      correo: json['Correo']?.toString() ?? '',
      rol: _obtenerNombreRol(json['Roles_idRoles']),
    );
  }

  static String _obtenerNombreRol(dynamic rol) {
    switch (rol.toString()) {
      case '1':
        return 'Administrador';
      case '2':
        return 'Contador';
      case '3':
        return 'Cliente';
      default:
        return 'Desconocido';
    }
  }
}