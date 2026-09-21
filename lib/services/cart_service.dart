import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/session/storage/session_storage.dart';
import '../models/cart_item_model.dart';
import '../models/producto_model.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;

  final List<CartItem> _items = [];

  CartService._internal() {
    _restaurarCarrito();
  }

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.cantidad);

  double get total => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  bool get estaVacio => _items.isEmpty;

  void _restaurarCarrito() {
    try {
      final dataStr = PlatformLocalStorage.getItem('carrito');
      if (dataStr != null && dataStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(dataStr);
        _items.clear();
        for (var item in list) {
          _items.add(CartItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } catch (_) {}
  }

  void _guardarCarrito() {
    try {
      final jsonList = _items.map((i) => i.toJson()).toList();
      PlatformLocalStorage.setItem('carrito', jsonEncode(jsonList));
    } catch (_) {}
  }

  void agregarProducto(Producto producto, {int cantidad = 1, String? talla, String? color}) {
    final index = _items.indexWhere((item) => item.producto.id == producto.id);
    if (index >= 0) {
      _items[index].cantidad += cantidad;
    } else {
      _items.add(CartItem(
        producto: producto,
        cantidad: cantidad,
        talla: talla ?? 'M',
        color: color ?? 'Único',
      ));
    }
    _guardarCarrito();
    notifyListeners();
  }

  void actualizarCantidad(int productoId, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      eliminarProducto(productoId);
      return;
    }

    final index = _items.indexWhere((item) => item.producto.id == productoId);
    if (index >= 0) {
      _items[index].cantidad = nuevaCantidad;
      _guardarCarrito();
      notifyListeners();
    }
  }

  void eliminarProducto(int productoId) {
    _items.removeWhere((item) => item.producto.id == productoId);
    _guardarCarrito();
    notifyListeners();
  }

  void vaciarCarrito() {
    _items.clear();
    _guardarCarrito();
    notifyListeners();
  }
}
