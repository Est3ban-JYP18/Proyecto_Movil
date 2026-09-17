import 'package:flutter/material.dart';

import '../../models/usuario_model.dart';
import '../../services/admin_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final AdminService _adminService = AdminService();

  List<Usuario> usuarios = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  // ============================================================
  // CONSULTAR USUARIOS
  // ============================================================

  Future<void> cargarUsuarios() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resultado = await _adminService.obtenerUsuarios();

      if (!mounted) return;

      setState(() {
        usuarios = resultado;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = e.toString();
      });
    }
  }

  // ============================================================
  // AGREGAR USUARIO
  // ============================================================

  void _mostrarFormularioAgregar() {
    final nombresController = TextEditingController();
    final apellidosController = TextEditingController();
    final correoController = TextEditingController();
    final contrasenaController = TextEditingController();

    int rolSeleccionado = 3;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Agregar usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombresController,
                      decoration: const InputDecoration(
                        labelText: 'Nombres',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: apellidosController,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contrasenaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: rolSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Administrador'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Contador'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('Cliente'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setDialogState(() {
                            rolSeleccionado = valor;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nombresController.text.trim().isEmpty ||
                        apellidosController.text.trim().isEmpty ||
                        correoController.text.trim().isEmpty ||
                        contrasenaController.text.isEmpty) {
                      _mostrarMensaje('Completa todos los campos');
                      return;
                    }

                    try {
                      await _adminService.crearUsuario(
                        nombres: nombresController.text.trim(),
                        apellidos: apellidosController.text.trim(),
                        correo: correoController.text.trim(),
                        contrasena: contrasenaController.text,
                        rol: rolSeleccionado,
                      );

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      _mostrarMensaje(
                        'Usuario creado correctamente',
                      );

                      await cargarUsuarios();
                    } catch (e) {
                      if (!mounted) return;

                      _mostrarMensaje(
                        'Error al crear usuario: $e',
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EDITAR USUARIO
  // ============================================================

  void _mostrarFormularioEditar(Usuario usuario) {
    final partesNombre = usuario.nombre.trim().split(' ');

    String nombresIniciales = usuario.nombre;
    String apellidosIniciales = '';

    if (partesNombre.length > 1) {
      nombresIniciales = partesNombre.first;
      apellidosIniciales = partesNombre.skip(1).join(' ');
    }

    final nombresController = TextEditingController(
      text: nombresIniciales,
    );

    final apellidosController = TextEditingController(
      text: apellidosIniciales,
    );

    final correoController = TextEditingController(
      text: usuario.correo,
    );

    final contrasenaController = TextEditingController();

    int rolSeleccionado = _obtenerIdRol(usuario.rol);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombresController,
                      decoration: const InputDecoration(
                        labelText: 'Nombres',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: apellidosController,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contrasenaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nueva contraseña',
                        hintText: 'Déjalo vacío para no cambiarla',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: rolSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Administrador'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Contador'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('Cliente'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setDialogState(() {
                            rolSeleccionado = valor;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nombresController.text.trim().isEmpty ||
                        apellidosController.text.trim().isEmpty ||
                        correoController.text.trim().isEmpty) {
                      _mostrarMensaje('Completa todos los campos');
                      return;
                    }

                    try {
                      await _adminService.actualizarUsuario(
                        id: usuario.id,
                        nombres: nombresController.text.trim(),
                        apellidos: apellidosController.text.trim(),
                        correo: correoController.text.trim(),
                        rol: rolSeleccionado,
                        contrasena:
                            contrasenaController.text.trim().isEmpty
                                ? null
                                : contrasenaController.text,
                      );

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      _mostrarMensaje(
                        'Usuario actualizado correctamente',
                      );

                      await cargarUsuarios();
                    } catch (e) {
                      if (!mounted) return;

                      _mostrarMensaje(
                        'Error al actualizar usuario: $e',
                      );
                    }
                  },
                  child: const Text('Guardar cambios'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ELIMINAR USUARIO
  // ============================================================

  Future<void> _eliminarUsuario(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar usuario'),
          content: Text(
            '¿Seguro que quieres eliminar a ${usuario.nombre}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _adminService.eliminarUsuario(usuario.id);

      if (!mounted) return;

      _mostrarMensaje(
        'Usuario eliminado correctamente',
      );

      await cargarUsuarios();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error al eliminar usuario: $e',
      );
    }
  }

  // ============================================================
  // OBTENER ID DEL ROL
  // ============================================================

  int _obtenerIdRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return 1;
      case 'contador':
        return 2;
      case 'cliente':
        return 3;
      default:
        return 3;
    }
  }

  // ============================================================
  // MENSAJES
  // ============================================================

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            onPressed: cargarUsuarios,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioAgregar,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ============================================================
  // CUERPO
  // ============================================================

  Widget _buildBody() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'No se pudieron cargar los usuarios',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: cargarUsuarios,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (usuarios.isEmpty) {
      return RefreshIndicator(
        onRefresh: cargarUsuarios,
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(
              child: Text(
                'No hay usuarios registrados',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cargarUsuarios,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: usuarios.length,
        itemBuilder: (context, index) {
          final usuario = usuarios[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  usuario.nombre.isNotEmpty
                      ? usuario.nombre[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(
                usuario.nombre.isEmpty
                    ? 'Usuario ${usuario.id}'
                    : usuario.nombre,
              ),
              subtitle: Text(
                '${usuario.correo}\nRol: ${usuario.rol}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (opcion) {
                  if (opcion == 'editar') {
                    _mostrarFormularioEditar(usuario);
                  }

                  if (opcion == 'eliminar') {
                    _eliminarUsuario(usuario);
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 10),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 10),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ),
          );
        },
      ),
    );
  }
}