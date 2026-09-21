import 'producto_model.dart';

class CartItem {
  final Producto producto;
  int cantidad;
  final String? talla;
  final String? color;

  CartItem({
    required this.producto,
    this.cantidad = 1,
    this.talla,
    this.color,
  });

  double get subtotal => producto.precio * cantidad;

  Map<String, dynamic> toJson() {
    return {
      'producto': producto.toJson(),
      'cantidad': cantidad,
      'talla': talla,
      'color': color,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      producto: Producto.fromJson(Map<String, dynamic>.from(json['producto'] ?? json)),
      cantidad: int.tryParse(json['cantidad']?.toString() ?? '1') ?? 1,
      talla: json['talla']?.toString(),
      color: json['color']?.toString(),
    );
  }
}
