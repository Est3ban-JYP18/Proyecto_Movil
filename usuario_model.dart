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
    // Resolver nombre
    String resolvedNombre = json['Nombre']?.toString() ?? json['nombre']?.toString() ?? '';
    if (resolvedNombre.isEmpty && json['Nombres'] != null) {
      final nombres = json['Nombres']?.toString() ?? '';
      final apellidos = json['Apellidos']?.toString() ?? '';
      resolvedNombre = '$nombres $apellidos'.trim();
    }

    // Resolver rol
    String resolvedRol = json['Rol']?.toString() ??
        json['rol']?.toString() ??
        json['Nombre_rol']?.toString() ??
        json['Nombre_Rol']?.toString() ??
        '';

    if (resolvedRol.isEmpty) {
      final dynamic roleId = json['Roles_idRoles'] ?? json['rolId'];
      if (roleId == 1 || roleId == '1') {
        resolvedRol = 'Administrador';
      } else if (roleId == 2 || roleId == '2') {
        resolvedRol = 'Contador';
      } else {
        resolvedRol = 'Cliente';
      }
    }

    return Usuario(
      id: int.tryParse((json['idUsuario'] ?? json['id'] ?? json['idUsuarios'] ?? 0).toString()) ?? 0,
      nombre: resolvedNombre.isNotEmpty ? resolvedNombre : 'Usuario',
      correo: json['Correo']?.toString() ?? json['correo']?.toString() ?? '',
      rol: resolvedRol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
    };
  }
}