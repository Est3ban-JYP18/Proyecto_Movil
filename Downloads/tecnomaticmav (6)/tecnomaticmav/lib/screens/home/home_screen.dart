import 'package:flutter/material.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../services/cart_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../cart/cart_screen.dart';
import '../catalog/catalog_screen.dart';
import '../contador/generar_recibos_screen.dart';
import '../pedidos/pedidos_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    final bool esAdmin = session.isLoggedIn &&
        session.usuarioActual?.rol.toLowerCase() == 'administrador';

    if (esAdmin) {
      return AdminDashboardScreen(
        onCerrarSesion: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      );
    }

    final bool isLoggedIn = session.isLoggedIn;

    // Construir páginas y items dinámicamente según estado de sesión
    final List<Widget> pages = [];
    final List<BottomNavigationBarItem> navItems = [];
    final List<String> titulos = [];

    // 1. Catálogo (siempre)
    pages.add(const CatalogScreen(showAppBar: false));
    navItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.widgets_outlined),
      label: 'Catálogo',
    ));
    titulos.add('Catálogo');

    // 2. Carrito (siempre)
    pages.add(CartScreen(
      showAppBar: false,
      onExplorarCatalogo: () {
        setState(() {
          _selectedIndex = 0; // Catálogo es el índice 0
        });
      },
    ));
    navItems.add(BottomNavigationBarItem(
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
    ));
    titulos.add('Carrito de Compras');

    // Si está logueado como Contador:
    final bool esContador = session.isLoggedIn &&
        session.usuarioActual?.rol.toLowerCase() == 'contador';

    if (esContador) {
      pages.add(const GenerarRecibosScreen(showAppBar: false));
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_outlined),
        activeIcon: Icon(Icons.receipt_long),
        label: 'Generar Recibos',
      ));
      titulos.add('Generar Recibos');
    } else if (isLoggedIn) {
      // Si está logueado como cliente:
      pages.add(const PedidosScreen(showAppBar: false));
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_outlined),
        activeIcon: Icon(Icons.receipt_long),
        label: 'Historial',
      ));
      titulos.add('Historial de Pedidos');
    } else {
      // Si NO está logueado:
      // Se mantiene Perfil en la barra inferior para que pueda iniciar sesión.
      pages.add(ProfileScreen(
        onSessionChanged: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      ));
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Perfil',
      ));
      titulos.add('Mi Perfil');
    }

    // Asegurar que el índice sea válido
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titulos[_selectedIndex]),
        backgroundColor: AppTheme.primaryColor,
        elevation: 1,
        actions: isLoggedIn
            ? [
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined),
                  tooltip: 'Mi Perfil',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          onSessionChanged: () {
                            setState(() {});
                          },
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar Sesión',
                  onPressed: () {
                    SessionManager().cerrarSesion();
                    setState(() {
                      _selectedIndex = 0;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sesión cerrada correctamente')),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
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
        items: navItems,
      ),
    );
  }
}