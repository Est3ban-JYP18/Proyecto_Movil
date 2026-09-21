# Resumen de Trabajo y Control de Cambios: Proyecto Tecnomatic MAV

Este documento resume las tareas realizadas, los nuevos archivos creados y las modificaciones implementadas durante esta sesión de desarrollo en los proyectos **Web (Backend Node.js/Express)** y **Móvil (Flutter)**.

---

## 1. ¿Qué se estuvo trabajando durante este chat?

Durante esta sesión nos enfocamos en solucionar problemas estructurales de autenticación y desarrollar la experiencia de compra completa para el cliente en el proyecto móvil:

1. **Generación y Persistencia del Token JWT:**
   - Se diagnosticó por qué no aparecía el token en `localStorage` o pruebas tras iniciar sesión o registrarse.
   - Se corrigió el backend para que el endpoint de registro (`/registro`) genere y devuelva el token JWT de inmediato al cliente.
   - Se adaptó el proyecto móvil para guardar de forma persistente el token y usuario en el `localStorage` del navegador (en Web) y en memoria (en Móvil), evitando que llamadas secundarias lo sobreescribieran con `null`.

2. **Implementación Completa del Carrito de Compras en Flutter:**
   - Se replicó el diseño visual del carrito web de React al proyecto móvil, adaptándolo a pantallas de celular.
   - Se creó un servicio reactivo para manejar productos agregados, cantidades en tiempo real (+/-), subtotales y vaciado.
   - En el detalle de productos se programó el botón "Añadir al Carrito" con un aviso interactivo que ofrece "Seguir comprando" o "Comprar".
   - Se integró la 4ta Tarjeta de Acceso Rápido en el Inicio y la pestaña "Carrito" con contador (*badge*) en la barra de navegación inferior.

3. **Integración con la Pasarela de Pago Mercado Pago:**
   - Conexión del carrito móvil con los endpoints de creación de órdenes (`POST /pedidos`) y generación de preferencia de Mercado Pago (`POST /crear-pago`).
   - Apertura automática de la pasarela oficial de pago.

4. **Corrección de Errores y Deprecaciones:**
   - Se corrigieron 4 advertencias en la pantalla de administración (`admin_dashboard_screen.dart`).
   - Se solucionó el error de pantalla blanca al hacer clic en "Explorar Catálogo".
   - Se corrigió el error `MissingPluginException` que ocurría al abrir Mercado Pago en Google Chrome / Web.

---

## 2. Detalle de Archivos Nuevos y Modificaciones

### A. Proyecto Web / Backend (`Proyecto-tecnomaticmav/backend`)

| Archivo | Tipo | Descripción del Cambio |
| :--- | :---: | :--- |
| `server.cjs` | **Modificado** | • Se agregó generación de JWT con `jwt.sign()` en la ruta `POST /registro`, devolviendo `token` y objeto `usuario`.<br>• Se agregó fallback de seguridad `process.env.JWT_SECRET \|\| 'tecnomaticmav2026'` en `/login` y `/registro`. |
| `middleware/verifyToken.js` | **Modificado** | • Se agregó fallback para la clave secreta al verificar el token JWT. |

---

### B. Proyecto Móvil Flutter (`tecnomaticmav`)

#### 📁 Archivos Nuevos Creados:
1. **`lib/models/cart_item_model.dart`**
   - Modela el ítem del carrito: producto, cantidad, talla, color, subtotal y serialización a JSON.
2. **`lib/services/cart_service.dart`**
   - Servicio Singleton reactivo (`ChangeNotifier`) que gestiona la lista de productos en el carrito, persistencia local y cambios de cantidad.
3. **`lib/core/session/storage/session_storage_web.dart`**
   - Adaptador para persistir sesión y carrito en `window.localStorage` en la web.
4. **`lib/core/session/storage/session_storage_stub.dart`**
   - Adaptador en memoria para plataformas nativas (Android/iOS).
5. **`lib/core/session/storage/session_storage.dart`**
   - Exportación condicional automática entre web y móvil.
6. **`lib/services/launcher/url_launcher_web.dart`**
   - Abre URLs (Mercado Pago) de forma nativa en la web con `window.open(url, '_blank')`.
7. **`lib/services/launcher/url_launcher_stub.dart`**
   - Abre URLs en celulares Android/iOS mediante el paquete `url_launcher`.
8. **`lib/services/launcher/url_launcher_helper.dart`**
   - Exportación condicional del lanzador según la plataforma.

#### 📝 Archivos Modificados:
1. **`lib/core/session/session_manager.dart`**
   - Persistencia automática de `token` y `usuario` en `localStorage`.
   - Protección contra borrado accidental de token por llamadas sin argumentos.
   - Restauración de sesión al reiniciar la aplicación.
2. **`lib/models/usuario_model.dart`**
   - Se añadió el método `toJson()` para permitir la serialización y guardado del usuario.
3. **`lib/services/auth_service.dart`**
   - Métodos `login()` y `registrar()` actualizados para guardar sesión y token en `SessionManager`.
4. **`lib/screens/auth/login_screen.dart` y `register_screen.dart`**
   - Se eliminaron las llamadas redundantes a `SessionManager` que sobreescribían el token con `null`.
5. **`lib/services/payment_service.dart`**
   - Métodos para `crearPagoMercadoPago(items)` y `registrarPedidoBackend(...)`.
   - Método `abrirPasarelaMercadoPago(...)` utilizando el adaptador multiplataforma sin errores de plugins.
6. **`lib/screens/catalog/product_detail_screen.dart`**
   - Botón naranja "Añadir al Carrito" funcional con diálogo de opciones "Seguir comprando" o "Comprar".
7. **`lib/screens/cart/cart_screen.dart`**
   - Réplica móvil de la interfaz web: Resumen de Artículos, Controles (+/-), Datos de Pago y Envío, Selector Mercado Pago/PSE y Botón de Pago.
   - Corrección del botón "Explorar Catálogo" para evitar que la pantalla quede en blanco.
8. **`lib/screens/home/home_screen.dart`**
   - 4ta Tarjeta de Acceso Rápido ("Carrito") en el Dashboard.
   - Pestaña "Carrito" en el navbar azul central con badge de artículos.
   - Parámetro `initialIndex` y callback de navegación hacia el catálogo.
9. **`lib/screens/admin/admin_dashboard_screen.dart`**
   - Corrección de 4 avisos de deprecación (`value` a `initialValue`) y buenas prácticas (`final String _categoriaProducto`).
