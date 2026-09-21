import '../models/pedido_model.dart';
import 'pedido_service.dart';

class CompraService {
  final PedidoService _pedidoService = PedidoService();

  // Historial Cliente
  Future<List<PedidoModel>> getHistorialCliente({
    required int usuarioId,
    required String token,
  }) async {
    return _pedidoService.getHistorialCliente(usuarioId);
  }

  // Historial Admin
  Future<List<PedidoModel>> getHistorialAdmin({
    required String adminToken,
  }) async {
    return _pedidoService.getHistorialAdmin();
  }
}