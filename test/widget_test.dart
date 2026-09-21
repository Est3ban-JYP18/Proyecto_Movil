import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnomaticmav/core/session/session_manager.dart';
import 'package:tecnomaticmav/main.dart';
import 'package:tecnomaticmav/models/usuario_model.dart';

void main() {
  setUp(() {
    SessionManager().cerrarSesion();
  });

  testWidgets('Sin sesión: muestra Catálogo, Carrito y Perfil; NO muestra Historial', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // No debe aparecer Inicio ni Historial
    expect(find.text('Inicio'), findsNothing);
    expect(find.text('Historial'), findsNothing);

    // Sí debe mostrar Catálogo, Carrito y Perfil en la barra inferior
    expect(find.text('Catálogo'), findsWidgets);
    expect(find.text('Carrito'), findsWidgets);
    expect(find.text('Perfil'), findsOneWidget);

    // No debe haber botón de logout en la barra superior
    expect(find.byIcon(Icons.logout), findsNothing);
  });

  testWidgets('Cliente logueado: Perfil eliminado de barra inferior y colocado en barra superior', (WidgetTester tester) async {
    SessionManager().iniciarSesion(
      Usuario(id: 10, nombre: 'Juan Cliente', correo: 'juan@email.com', rol: 'Cliente'),
    );

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // En la barra inferior NO debe aparecer Perfil ni Inicio
    expect(find.text('Inicio'), findsNothing);
    expect(find.text('Perfil'), findsNothing);

    // En la barra inferior SÍ deben estar Catálogo, Carrito e Historial
    expect(find.text('Catálogo'), findsWidgets);
    expect(find.text('Carrito'), findsWidgets);
    expect(find.text('Historial'), findsOneWidget);

    // En la barra superior SÍ deben estar los iconos de Mi Perfil y Cerrar Sesión
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('Administrador: barra inferior con Productos, Pedidos, Usuarios, Devoluciones y acciones en barra superior', (WidgetTester tester) async {
    SessionManager().iniciarSesion(
      Usuario(id: 1, nombre: 'Admin Master', correo: 'admin@tecnomatic.com', rol: 'Administrador'),
    );

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // No debe aparecer Inicio
    expect(find.text('Inicio'), findsNothing);

    // Debe mostrar las 4 pestañas del administrador en la barra inferior
    expect(find.text('Productos'), findsWidgets);
    expect(find.text('Pedidos'), findsWidgets);
    expect(find.text('Usuarios'), findsWidgets);
    expect(find.text('Devoluciones'), findsWidgets);
    expect(find.text('Historial'), findsWidgets);

    // En la barra superior deben estar Mi Perfil y Cerrar Sesión
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
