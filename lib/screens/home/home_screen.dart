import 'package:flutter/material.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../services/cart_service.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../catalog/catalog_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TECNOMATIC MAV'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardView(context),
          const CatalogScreen(),
          CartScreen(
            showAppBar: false,
            onExplorarCatalogo: () {
              setState(() {
                _selectedIndex = 1; // Cambia a la pestaña Catálogo
              });
            },
          ),
          ProfileScreen(
            onSessionChanged: () {
              setState(() {}); // Refresca Home al iniciar o cerrar sesión
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.accentColor,
        unselectedItemColor: Colors.white70,
        backgroundColor: AppTheme.primaryColor,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.widgets_outlined),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: ListenableBuilder(
              listenable: CartService(),
              builder: (context, _) {
                final count = CartService().totalItems;
                if (count > 0) {
                  return Badge.count(
                    count: count,
                    backgroundColor: AppTheme.accentColor,
                    child: const Icon(Icons.shopping_cart_outlined),
                  );
                }
                return const Icon(Icons.shopping_cart_outlined);
              },
            ),
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // Vista Principal con la grilla interactiva
  Widget _buildDashboardView(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              '¡Hola, Bienvenido!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '¿Qué deseas hacer hoy?',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 30),

            // Grilla con las tarjetas interactivas
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _OptionCard(
                    icon: Icons.storefront_outlined,
                    label: 'Catálogo',
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1; // Cambia a la pestaña Catálogo
                      });
                    },
                  ),
                  _OptionCard(
                    icon: Icons.info_outline_rounded,
                    label: '¿Quiénes somos?',
                    onTap: () => _showQuienesSomos(context),
                  ),
                  _OptionCard(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Carrito',
                    onTap: () {
                      if (SessionManager().isLoggedIn) {
                        setState(() {
                          _selectedIndex = 2; // Cambia a la pestaña Carrito
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Inicia sesión para acceder a tu carrito de compras.'),
                            action: SnackBarAction(
                              label: 'Ingresar',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                ).then((_) => setState(() {}));
                              },
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _OptionCard(
                    icon: Icons.person_outline_rounded,
                    label: 'Perfil',
                    onTap: () {
                      setState(() {
                        _selectedIndex = 3; // Cambia a la pestaña Perfil
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ventana modal desplegable para "¿Quiénes somos?"
  void _showQuienesSomos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.business_outlined, size: 48, color: AppTheme.primaryColor),
              const SizedBox(height: 12),
              const Text(
                'TECNOMATIC MAV',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Soluciones automatizadas e industriales a tu alcance. Explora nuestros servicios y catálogo de productos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget de Tarjeta Reutilizable
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 42,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}