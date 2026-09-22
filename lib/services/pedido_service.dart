import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/session/session_manager.dart';
import '../models/devolucion_model.dart';
import '../models/pedido_model.dart';

class PedidoService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Helper para enriquecer datos con información de usuarios
  Future<Map<dynamic, Map<String, dynamic>>> _getUsersMap() async {
    final Map<dynamic, Map<String, dynamic>> userMap = {};
    try {
      final List<dynamic> users = await _supabase.from('Usuarios').select('*');
      for (final u in users) {
        final map = Map<String, dynamic>.from(u as Map);
        final id = map['idUsuarios'] ?? map['id'];
        if (id != null) userMap[id] = map;
      }
    } catch (_) {}
    return userMap;
  }

  // Helper para enriquecer datos con información de productos
  Future<Map<dynamic, Map<String, dynamic>>> _getProductsMap() async {
    final Map<dynamic, Map<String, dynamic>> prodMap = {};
    try {
      final List<dynamic> prods = await _supabase.from('Productos').select('*');
      for (final p in prods) {
        final map = Map<String, dynamic>.from(p as Map);
        final id = map['idProductos'] ?? map['id'];
        if (id != null) prodMap[id] = map;
      }
    } catch (_) {}
    return prodMap;
  }

  // ============================================================
  // APIS Y MÉTODOS DE HISTORIAL (ADMIN Y CLIENTE)
  // ============================================================

  /// [ADMIN] Obtiene la lista completa de todas las facturas/pedidos registrados.
  Future<List<PedidoModel>> getHistorialAdmin() async {
    try {
      List<dynamic> data = [];

      try {
        data = await _supabase
            .from('Facturas')
            .select('*')
            .order('idFacturas', ascending: false);
      } catch (_) {
        try {
          data = await _supabase.from('Facturas').select('*');
        } catch (_) {
          data = await _supabase.from('facturas').select('*');
        }
      }

      final users = await _getUsersMap();

      return data.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final uid = map['Usuarios_idUsuarios'] ?? map['usuario_id'];
        if (uid != null && users.containsKey(uid)) {
          final u = users[uid]!;
          map['Nombres'] = u['Nombres'] ?? u['nombres'];
          map['Apellidos'] = u['Apellidos'] ?? u['apellidos'];
          map['Correo'] = u['Correo'] ?? u['correo'];
          map['Telefono'] = u['Telefono'] ?? u['telefono'];
        }
        return PedidoModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener facturas desde Supabase: $e');
    }
  }

  /// [CLIENTE] Obtiene el historial de pedidos de un cliente específico.
  Future<List<PedidoModel>> getHistorialCliente(dynamic usuarioId) async {
    try {
      int? parsedId = int.tryParse(usuarioId.toString());

      // Si el id no es entero válido, buscar el idUsuarios en Supabase por el correo de sesión
      if (parsedId == null || parsedId <= 0) {
        final sessionEmail = SessionManager().usuarioActual?.correo;
        if (sessionEmail != null && sessionEmail.isNotEmpty) {
          try {
            final u = await _supabase
                .from('Usuarios')
                .select('idUsuarios')
                .ilike('Correo', sessionEmail.trim())
                .maybeSingle();
            if (u != null) {
              parsedId = int.tryParse(u['idUsuarios'].toString());
            }
          } catch (_) {}
        }
      }

      List<dynamic> data = [];

      if (parsedId != null && parsedId > 0) {
        try {
          data = await _supabase
              .from('Facturas')
              .select('*')
              .eq('Usuarios_idUsuarios', parsedId)
              .order('idFacturas', ascending: false);
        } catch (_) {
          try {
            data = await _supabase
                .from('facturas')
                .select('*')
                .eq('usuario_id', parsedId.toString())
                .order('id', ascending: false);
          } catch (_) {
            data = [];
          }
        }
      }

      final users = await _getUsersMap();

      return data.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final uid = map['Usuarios_idUsuarios'] ?? map['usuario_id'] ?? parsedId;
        if (uid != null && users.containsKey(uid)) {
          final u = users[uid]!;
          map['Nombres'] = u['Nombres'] ?? u['nombres'];
          map['Apellidos'] = u['Apellidos'] ?? u['apellidos'];
          map['Correo'] = u['Correo'] ?? u['correo'];
          map['Telefono'] = u['Telefono'] ?? u['telefono'];
        }
        return PedidoModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener historial del cliente desde Supabase: $e');
    }
  }

  /// [AMBOS] Obtiene los artículos detallados de un pedido específico.
  Future<List<PedidoDetalleItem>> getDetallePedido(int idFactura) async {
    try {
      List<dynamic> data = [];

      try {
        data = await _supabase
            .from('Detalle_Facturas')
            .select('*')
            .eq('Factura_idFactura', idFactura);
      } catch (_) {
        try {
          data = await _supabase
              .from('Detalle_Facturas')
              .select('*')
              .eq('Facturas_idFacturas', idFactura);
        } catch (_) {
          try {
            data = await _supabase
                .from('detalle_facturas')
                .select('*')
                .eq('factura_id', idFactura);
          } catch (_) {
            data = [];
          }
        }
      }

      if (data.isEmpty) return [];

      final prods = await _getProductsMap();
      final List<PedidoDetalleItem> items = [];

      for (final raw in data) {
        final map = Map<String, dynamic>.from(raw as Map);
        final prodId = map['Productos_idProductos'] ?? map['producto_id'];
        if (prodId != null && prods.containsKey(prodId)) {
          final p = prods[prodId]!;
          map['Nombre_Producto'] ??= p['Nombre_Producto'] ?? p['nombre_producto'];
          map['Imagen'] ??= p['Imagen'] ?? p['imagen'];
        }
        items.add(PedidoDetalleItem.fromJson(map));
      }

      return items;
    } catch (e) {
      throw Exception('Error al consultar detalle del pedido en Supabase: $e');
    }
  }

  /// [AMBOS] Obtiene el estado de entrega y seguimiento logístico.
  Future<PedidoSeguimiento> getSeguimientoPedido(
    int idFactura, {
    String estadoFallback = 'Pendiente',
  }) async {
    try {
      Map<String, dynamic>? res;

      try {
        res = await _supabase
            .from('Entregas')
            .select('*')
            .eq('Factura_idFactura', idFactura)
            .maybeSingle();
      } catch (_) {
        try {
          res = await _supabase
              .from('Entregas')
              .select('*')
              .eq('Facturas_idFacturas', idFactura)
              .maybeSingle();
        } catch (_) {
          try {
            res = await _supabase
                .from('entregas')
                .select('*')
                .eq('factura_id', idFactura)
                .maybeSingle();
          } catch (_) {}
        }
      }

      if (res != null) {
        return PedidoSeguimiento.fromJson(Map<String, dynamic>.from(res));
      }

      return PedidoSeguimiento(
        estadoEntrega: estadoFallback,
        observaciones: 'El pedido está siendo procesado en bodega.',
      );
    } catch (e) {
      return PedidoSeguimiento(
        estadoEntrega: estadoFallback,
        observaciones: 'El pedido se encuentra registrado y en trámite logístico.',
      );
    }
  }

  /// [ADMIN] Actualiza el estado de una factura.
  Future<bool> actualizarEstadoPedido(int idFactura, String nuevoEstado) async {
    try {
      try {
        await _supabase.from('Facturas').update({'Estado': nuevoEstado}).eq('idFacturas', idFactura);
      } catch (_) {
        await _supabase.from('facturas').update({'estado': nuevoEstado}).eq('id', idFactura);
      }

      // Sincronizar estado de entrega si aplica
      try {
        String estadoEntrega = 'En Proceso';
        if (nuevoEstado.toLowerCase() == 'enviado') {
          estadoEntrega = 'En Camino';
        } else if (nuevoEstado.toLowerCase() == 'entregado' || nuevoEstado.toLowerCase() == 'entregada') {
          estadoEntrega = 'Entregado';
        }

        try {
          await _supabase.from('Entregas').update({
            'Estado_Entrega': estadoEntrega,
          }).or('Facturas_idFacturas.eq.$idFactura,Factura_idFactura.eq.$idFactura');
        } catch (_) {
          await _supabase.from('entregas').update({
            'estado_entrega': estadoEntrega,
          }).eq('factura_id', idFactura);
        }
      } catch (_) {}

      return true;
    } catch (e) {
      throw Exception('Error al actualizar estado en Supabase: $e');
    }
  }

  /// [ADMIN] Elimina un pedido y sus registros asociados en Supabase.
  Future<bool> eliminarPedido(int idFactura) async {
    try {
      try {
        await _supabase.from('Detalle_Facturas').delete().or('Facturas_idFacturas.eq.$idFactura,Factura_idFactura.eq.$idFactura');
      } catch (_) {
        try {
          await _supabase.from('detalle_facturas').delete().eq('factura_id', idFactura);
        } catch (_) {}
      }

      try {
        await _supabase.from('Entregas').delete().or('Facturas_idFacturas.eq.$idFactura,Factura_idFactura.eq.$idFactura');
      } catch (_) {
        try {
          await _supabase.from('entregas').delete().eq('factura_id', idFactura);
        } catch (_) {}
      }

      try {
        await _supabase.from('Devoluciones').delete().or('Facturas_idFacturas.eq.$idFactura,Factura_idFactura.eq.$idFactura');
      } catch (_) {
        try {
          await _supabase.from('devoluciones').delete().eq('factura_id', idFactura);
        } catch (_) {}
      }

      try {
        await _supabase.from('Facturas').delete().eq('idFacturas', idFactura);
      } catch (_) {
        await _supabase.from('facturas').delete().eq('id', idFactura);
      }

      return true;
    } catch (e) {
      throw Exception('Error al eliminar pedido en Supabase: $e');
    }
  }

  /// [ADMIN] Obtiene la cantidad de ítems del catálogo para las métricas.
  Future<int> getCantidadProductos() async {
    try {
      try {
        final List<dynamic> data = await _supabase.from('Productos').select('idProductos');
        return data.length;
      } catch (_) {
        final List<dynamic> data = await _supabase.from('productos').select('id');
        return data.length;
      }
    } catch (_) {
      return 0;
    }
  }

  // ============================================================
  // APIS Y MÉTODOS DE DEVOLUCIONES
  // ============================================================

  /// [ADMIN] Obtiene todas las devoluciones solicitadas en la plataforma.
  Future<List<DevolucionModel>> getDevolucionesAdmin() async {
    try {
      List<dynamic> data = [];
      try {
        data = await _supabase.from('Devoluciones').select('*').order('idDevoluciones', ascending: false);
      } catch (_) {
        data = await _supabase.from('devoluciones').select('*').order('id', ascending: false);
      }

      final users = await _getUsersMap();
      final prods = await _getProductsMap();

      return data.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final uid = map['Usuarios_idUsuarios'] ?? map['usuario_id'];
        if (uid != null && users.containsKey(uid)) {
          final u = users[uid]!;
          map['Nombres'] = u['Nombres'] ?? u['nombres'];
          map['Apellidos'] = u['Apellidos'] ?? u['apellidos'];
        }
        final pid = map['Productos_idProductos'] ?? map['producto_id'];
        if (pid != null && prods.containsKey(pid)) {
          final p = prods[pid]!;
          map['Nombre_Producto'] = p['Nombre_Producto'] ?? p['nombre_producto'];
        }
        return DevolucionModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw Exception('Error al sincronizar devoluciones con Supabase: $e');
    }
  }

  /// [CLIENTE] Obtiene las devoluciones pertenecientes al usuario logueado.
  Future<List<DevolucionModel>> getDevolucionesCliente(dynamic usuarioId) async {
    try {
      int? parsedId = int.tryParse(usuarioId.toString());

      if (parsedId == null || parsedId <= 0) {
        final sessionEmail = SessionManager().usuarioActual?.correo;
        if (sessionEmail != null && sessionEmail.isNotEmpty) {
          try {
            final u = await _supabase
                .from('Usuarios')
                .select('idUsuarios')
                .ilike('Correo', sessionEmail.trim())
                .maybeSingle();
            if (u != null) {
              parsedId = int.tryParse(u['idUsuarios'].toString());
            }
          } catch (_) {}
        }
      }

      List<dynamic> data = [];
      if (parsedId != null && parsedId > 0) {
        try {
          data = await _supabase
              .from('Devoluciones')
              .select('*')
              .eq('Usuarios_idUsuarios', parsedId)
              .order('idDevoluciones', ascending: false);
        } catch (_) {
          try {
            data = await _supabase
                .from('devoluciones')
                .select('*')
                .eq('usuario_id', parsedId.toString())
                .order('id', ascending: false);
          } catch (_) {
            data = [];
          }
        }
      }

      final prods = await _getProductsMap();

      return data.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final pid = map['Productos_idProductos'] ?? map['producto_id'];
        if (pid != null && prods.containsKey(pid)) {
          final p = prods[pid]!;
          map['Nombre_Producto'] = p['Nombre_Producto'] ?? p['nombre_producto'];
        }
        return DevolucionModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener tus devoluciones desde Supabase: $e');
    }
  }

  /// [ADMIN] Aprueba una devolución solicitada.
  Future<bool> aprobarDevolucion(int idDevolucion, {String? comentarios, String? cupon}) async {
    try {
      try {
        await _supabase.from('Devoluciones').update({
          'Estado': 'Aprobada',
          'Estado_Tracking': 'Resuelta',
          'Comentarios_Admin': comentarios ?? 'Aprobada por administración',
          'Codigo_Cupon': cupon ?? 'CUPON-DEV-$idDevolucion',
        }).eq('idDevoluciones', idDevolucion);
      } catch (_) {
        await _supabase.from('devoluciones').update({
          'estado': 'Aprobada',
          'estado_tracking': 'Resuelta',
          'comentarios_admin': comentarios ?? 'Aprobada por administración',
          'codigo_cupon': cupon ?? 'CUPON-DEV-$idDevolucion',
        }).eq('id', idDevolucion);
      }

      return true;
    } catch (e) {
      throw Exception('Error al aprobar devolución en Supabase: $e');
    }
  }

  /// [ADMIN] Rechaza una devolución solicitada.
  Future<bool> rechazarDevolucion(int idDevolucion, {String? comentarios}) async {
    try {
      try {
        await _supabase.from('Devoluciones').update({
          'Estado': 'Rechazada',
          'Estado_Tracking': 'Rechazada',
          'Comentarios_Admin': comentarios ?? 'Rechazada por administración',
        }).eq('idDevoluciones', idDevolucion);
      } catch (_) {
        await _supabase.from('devoluciones').update({
          'estado': 'Rechazada',
          'estado_tracking': 'Rechazada',
          'comentarios_admin': comentarios ?? 'Rechazada por administración',
        }).eq('id', idDevolucion);
      }

      return true;
    } catch (e) {
      throw Exception('Error al rechazar devolución en Supabase: $e');
    }
  }

  /// [CLIENTE] Registra una nueva solicitud de devolución con pruebas y detalles.
  Future<bool> crearSolicitudDevolucion({
    required int facturaId,
    required int productoId,
    required dynamic usuarioId,
    required int cantidad,
    required String motivo,
    String motivoCategoria = 'Defecto de fábrica',
    String metodoReembolso = 'Cambio de producto',
    String metodoRetorno = 'Recogida a domicilio',
    String? direccionRetorno,
    String? evidenciaUrl,
  }) async {
    try {
      // 1. Resolver usuario ID
      int? parsedUser = int.tryParse(usuarioId.toString());

      if (parsedUser == null || parsedUser <= 0) {
        final sessionEmail = SessionManager().usuarioActual?.correo;
        if (sessionEmail != null && sessionEmail.isNotEmpty) {
          try {
            final u = await _supabase
                .from('Usuarios')
                .select('idUsuarios')
                .ilike('Correo', sessionEmail.trim())
                .maybeSingle();
            if (u != null) {
              parsedUser = int.tryParse(u['idUsuarios'].toString());
            }
          } catch (_) {}
        }
      }

      if (parsedUser == null || parsedUser <= 0) {
        try {
          final primerUser = await _supabase.from('Usuarios').select('idUsuarios').limit(1).maybeSingle();
          if (primerUser != null) {
            parsedUser = int.tryParse(primerUser['idUsuarios'].toString());
          }
        } catch (_) {}
      }
      parsedUser ??= 3;

      // 2. Resolver y validar productoId en la tabla Productos
      int? resolvedProductoId = productoId > 0 ? productoId : null;

      if (resolvedProductoId != null) {
        try {
          final prodCheck = await _supabase
              .from('Productos')
              .select('idProductos')
              .eq('idProductos', resolvedProductoId)
              .maybeSingle();
          if (prodCheck == null) {
            resolvedProductoId = null;
          }
        } catch (_) {}
      }

      // Si no existe directamente, buscar en Detalle_Facturas de este pedido
      if (resolvedProductoId == null) {
        try {
          final detalles = await _supabase
              .from('Detalle_Facturas')
              .select('*')
              .or('Factura_idFactura.eq.$facturaId,Facturas_idFacturas.eq.$facturaId');
          if (detalles.isNotEmpty) {
            for (final d in detalles) {
              final pid = int.tryParse((d['Productos_idProductos'] ?? d['producto_id'] ?? 0).toString());
              if (pid != null && pid > 0) {
                resolvedProductoId = pid;
                break;
              }
            }
          }
        } catch (_) {}
      }

      // Si aún no se resuelve, obtener el primer ID válido de la tabla Productos
      if (resolvedProductoId == null || resolvedProductoId <= 0) {
        try {
          final primerProd = await _supabase.from('Productos').select('idProductos').limit(1).maybeSingle();
          if (primerProd != null) {
            resolvedProductoId = int.tryParse(primerProd['idProductos'].toString());
          }
        } catch (_) {}
      }
      resolvedProductoId ??= 1;

      // 3. Resolver y validar facturaId en la tabla Facturas
      int? resolvedFacturaId = facturaId > 0 ? facturaId : null;
      if (resolvedFacturaId != null) {
        try {
          final factCheck = await _supabase
              .from('Facturas')
              .select('idFacturas')
              .eq('idFacturas', resolvedFacturaId)
              .maybeSingle();
          if (factCheck == null) {
            resolvedFacturaId = null;
          }
        } catch (_) {}
      }
      if (resolvedFacturaId == null || resolvedFacturaId <= 0) {
        try {
          final primeraFact = await _supabase.from('Facturas').select('idFacturas').limit(1).maybeSingle();
          if (primeraFact != null) {
            resolvedFacturaId = int.tryParse(primeraFact['idFacturas'].toString());
          }
        } catch (_) {}
      }
      resolvedFacturaId ??= 1;

      final insertData = {
        'Facturas_idFacturas': resolvedFacturaId,
        'Productos_idProductos': resolvedProductoId,
        'Usuarios_idUsuarios': parsedUser,
        'Cantidad': cantidad,
        'Motivo': motivo,
        'Motivo_Categoria': motivoCategoria,
        'Metodo_Reembolso': metodoReembolso,
        'Metodo_Retorno': metodoRetorno,
        'Direccion_Retorno': direccionRetorno?.trim().isNotEmpty == true ? direccionRetorno!.trim() : 'Recogida a domicilio',
        'Evidencia_Url': evidenciaUrl ?? 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
        'Estado': 'Pendiente',
        'Estado_Tracking': 'Solicitada',
      };

      await _supabase.from('Devoluciones').insert(insertData);
      return true;
    } catch (e) {
      throw Exception('Error al enviar solicitud de devolución a Supabase: $e');
    }
  }
}
