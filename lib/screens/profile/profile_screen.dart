import 'package:flutter/material.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../productos/productos_screen.dart';
import '../usuarios/usuarios_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onSessionChanged;

  const ProfileScreen({super.key, required this.onSessionChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final session = SessionManager();

  @override
  Widget build(BuildContext context) {
    if (!session.isLoggedIn || session.usuarioActual == null) {
      // Si NO está logueado, muestra la vista de bienvenida
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                const Text(
                  '¡Bienvenido a Tecnomatic!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inicia sesión para gestionar tus compras, ver tu perfil y acceder a funciones exclusivas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                      setState(() {});
                      widget.onSessionChanged(); // Notifica el cambio de estado
                    },
                    child: const Text('Iniciar Sesión / Registrarse'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final usuario = session.usuarioActual!;

    // Si SÍ está logueado, muestra sus datos desde usuarioActual
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Tarjeta de Usuario
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario.nombre,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            usuario.correo,
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(usuario.rol),
                            backgroundColor: AppTheme.accentColor.withValues(alpha: 0.2),
                            labelStyle: const TextStyle(color: AppTheme.accentColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // OPCIONES SEGÚN EL ROL
            if (usuario.rol == 'Administrador') ...[
              _buildOptionTile(
                icon: Icons.inventory_2_outlined,
                title: 'Gestión de Productos',
                subtitle: 'CRUD de catálogo, inventario y kárdex',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductosScreen(),
                    ),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.manage_accounts_outlined,
                title: 'Gestión de Usuarios',
                subtitle: 'Administrar cuentas y roles',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UsuariosScreen(),
                    ),
                  );
                },
              ),
            ],

            if (usuario.rol == 'Contador') ...[
              _buildOptionTile(
                icon: Icons.receipt_long,
                title: 'Reportes Financieros',
                subtitle: 'Facturas e historial de ventas',
                onTap: () {},
              ),
            ],

            _buildOptionTile(
              icon: Icons.history,
              title: 'Mis Compras',
              subtitle: 'Historial de pedidos realizados',
              onTap: () {},
            ),

            _buildOptionTile(
              icon: Icons.lock_outline,
              title: 'Seguridad',
              subtitle: 'Cambiar contraseña',
              onTap: () {},
            ),

            const SizedBox(height: 20),

            // Botón Cerrar Sesión
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  setState(() {
                    session.cerrarSesion();
                  });
                  widget.onSessionChanged();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}