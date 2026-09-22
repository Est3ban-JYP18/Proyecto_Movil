import 'package:flutter/material.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../../services/payment_service.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../../widgets/recibo_compra_dialog.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onExplorarCatalogo;
  final bool showAppBar;

  const CartScreen({
    super.key,
    this.onExplorarCatalogo,
    this.showAppBar = true,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final CartService _cartService = CartService();
  final PaymentService _paymentService = PaymentService();

  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  String _metodoPago = 'mercadopago'; // 'mercadopago' o 'pse'
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final usuario = SessionManager().usuarioActual;
    _nombreController = TextEditingController(text: usuario?.nombre ?? '');
    _correoController = TextEditingController(text: usuario?.correo ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  String _formatearPrecio(double precio) {
    final entero = precio.toStringAsFixed(0);
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formateado = entero.replaceAllMapped(regExp, (Match m) => '${m[1]}.');
    return '\$$formateado';
  }

  Future<void> _procesarPago() async {
    final session = SessionManager();
    if (!session.isLoggedIn || session.usuarioActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes iniciar sesión para realizar la compra.'),
          backgroundColor: Colors.orange.shade800,
          action: SnackBarAction(
            label: 'Iniciar sesión',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    if (_cartService.estaVacio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu carrito está vacío. Añade productos antes de continuar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cedula = _cedulaController.text.trim();
    final telefono = _telefonoController.text.trim();

    if (cedula.isEmpty || telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor completa tu Cédula y Teléfono Celular.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final items = List<CartItem>.from(_cartService.items);
      final total = _cartService.total;
      final usuarioId = session.usuarioActual!.id;

      // 1. Registrar pedido en el backend (MySQL)
      final idFactura = await _paymentService.registrarPedidoBackend(
        idUsuario: usuarioId,
        total: total,
        items: items,
      );

      // 2. Crear pago o preferencia en Mercado Pago
      final mpRes = await _paymentService.crearPagoMercadoPago(items);
      final initPoint = mpRes?['init_point']?.toString();

      setState(() => _isProcessing = false);

      if (!mounted) return;

      if (initPoint != null && initPoint.isNotEmpty && !initPoint.contains('localhost')) {
        // Abrir pasarela real de Mercado Pago
        await _paymentService.abrirPasarelaMercadoPago(initPoint);

        _cartService.vaciarCarrito();

        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            icon: const Icon(Icons.shield_outlined, color: Color(0xFF20B2AA), size: 55),
            title: const Text(
              'Redireccionando a Mercado Pago',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'Tu pedido #${idFactura ?? "N/A"} ha sido registrado correctamente.\nTe hemos redirigido a la pasarela de pago.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20B2AA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        );
      } else {
        // Flujo de confirmación y generación de recibo de compra
        final numRecibo = idFactura ?? (DateTime.now().millisecondsSinceEpoch % 100000);
        final reciboItems = items.map((i) => ReciboItemSimple(
          nombre: i.producto.nombre,
          cantidad: i.cantidad,
          precioUnitario: i.producto.precio,
        )).toList();

        final clienteNombre = _nombreController.text.trim().isNotEmpty
            ? _nombreController.text.trim()
            : (session.usuarioActual?.nombre ?? 'Cliente');
        final clienteCorreo = _correoController.text.trim();
        final clienteTelefono = telefono;
        final clienteCedula = cedula;

        _cartService.vaciarCarrito();

        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF20B2AA), size: 55),
            title: const Text(
              '¡Compra registrada con éxito!',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Se ha generado tu Recibo de Compra oficial por un total de ${_formatearPrecio(total)}.\n\nUna copia ha sido enviada automáticamente al Perfil del Contador.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'N° Recibo: RC-${numRecibo.toString().padLeft(4, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0047AB)),
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20B2AA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('Generar Recibo de Compra', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  ReciboCompraDialog.mostrar(
                    context,
                    idFactura: numRecibo,
                    fecha: DateTime.now().toIso8601String(),
                    clienteNombre: clienteNombre,
                    clienteCorreo: clienteCorreo,
                    clienteCedula: clienteCedula,
                    clienteTelefono: clienteTelefono,
                    total: total,
                    estado: 'Pagado',
                    items: reciboItems,
                  );
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar el pago: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Carrito de Compras'),
              backgroundColor: AppTheme.primaryColor,
              elevation: 1,
            )
          : null,
      body: AnimatedBuilder(
        animation: _cartService,
        builder: (context, _) {
          if (_cartService.estaVacio) {
            return _buildCarritoVacio();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildResumenArticulos(),
                const SizedBox(height: 24),
                _buildFormularioPago(),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryColor, size: 28),
            SizedBox(width: 8),
            Text(
              'Carrito de Compras',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Revisa tus artículos seleccionados y completa la transacción de forma segura.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCarritoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 70,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explora nuestro catálogo para añadir productos de protección y seguridad industrial.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (widget.onExplorarCatalogo != null) {
                  widget.onExplorarCatalogo!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(initialIndex: 1),
                    ),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Explorar Catálogo', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenArticulos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Resumen de Artículos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cartService.items.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = _cartService.items[index];
              return _buildCartItemTile(item);
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Vaciar Carrito', style: TextStyle(fontSize: 13)),
              onPressed: () {
                _cartService.vaciarCarrito();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 70,
            height: 70,
            color: Colors.grey.shade100,
            child: item.producto.imagen != null && item.producto.imagen!.isNotEmpty
                ? Image.network(
                    item.producto.imagen!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: Colors.grey),
                  )
                : const Icon(Icons.image, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 12),

        // Datos del producto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.producto.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Talla: ${item.talla ?? 'M'}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                'Color: ${item.color ?? 'Único'}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                '${_formatearPrecio(item.producto.precio)} c/u',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),

              // Controles de cantidad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            _cartService.actualizarCantidad(item.producto.id, item.cantidad - 1);
                          },
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Icon(Icons.remove, size: 16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${item.cantidad}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _cartService.actualizarCantidad(item.producto.id, item.cantidad + 1);
                          },
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Icon(Icons.add, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatearPrecio(item.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _cartService.eliminarProducto(item.producto.id);
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Eliminar',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormularioPago() {
    final subtotal = _cartService.total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.payment_outlined, color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Datos de Pago y Envío',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nombre Completo
            const Text(
              'Nombre Completo',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                hintText: 'Tu nombre completo',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Correo Electrónico
            const Text(
              'Correo Electrónico',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'correo@ejemplo.com',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Cédula y Teléfono en dos columnas
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cédula de Ciudadanía',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cedulaController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Ej. 10203040',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teléfono Celular',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Ej. 3001234567',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Método de Pago Seguro
            const Text(
              'Método de Pago Seguro',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetodoPagoCard(
                    id: 'mercadopago',
                    titulo: 'Mercado Pago',
                    subtitulo: 'Tarjetas y Saldo',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF009EE3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetodoPagoCard(
                    id: 'pse',
                    titulo: 'PSE',
                    subtitulo: 'Débito Bancario',
                    icon: Icons.account_balance_outlined,
                    iconColor: const Color(0xFF00A9E0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Resumen de precios
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text(_formatearPrecio(subtotal), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Envío nacional', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text('Gratis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total de la Compra',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                Text(
                  _formatearPrecio(subtotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botón Pagar con Mercado Pago
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00838F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : _procesarPago,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.shield_outlined, size: 20),
                label: Text(
                  _isProcessing
                      ? 'Procesando pago...'
                      : _metodoPago == 'mercadopago'
                          ? 'Pagar con Mercado Pago'
                          : 'Continuar con PSE',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodoPagoCard({
    required String id,
    required String titulo,
    required String subtitulo,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _metodoPago == id;

    return InkWell(
      onTap: () {
        setState(() {
          _metodoPago = id;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F7FA) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00838F) : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 6),
            Text(
              titulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? const Color(0xFF00838F) : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF00695C) : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
