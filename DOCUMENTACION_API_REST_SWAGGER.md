# Documentación Oficial de la API REST - Tecnomatic MAV (Trimestre 5)

**Versión:** 1.0.0  
**Arquitectura:** RESTful / OpenAPI 3.0 / PostgREST  
**Base URL:** `https://ssjqphfzebgrgskjkccc.supabase.co/rest/v1`  
**Autenticación:** `Bearer Token` / `apikey`  

---

## 1. Módulo de Autenticación y Usuarios

### 1.1 Iniciar Sesión (Login)
* **Método:** `POST`
* **Endpoint:** `/auth/v1/token?grant_type=password` o consulta a `/Usuarios`
* **Descripción:** Valida credenciales y retorna el token JWT junto con el rol del usuario (Cliente, Contador, Administrador).
* **Headers:**
  ```http
  apikey: <SUPABASE_ANON_KEY>
  Content-Type: application/json
  ```
* **Body Request:**
  ```json
  {
    "email": "cliente@gmail.com",
    "password": "123"
  }
  ```
* **Respuestas:**
  * `200 OK`:
    ```json
    {
      "idUsuarios": 3,
      "nombres": "Cliente",
      "apellidos": "Frecuente",
      "correo": "cliente@gmail.com",
      "rol": "Cliente",
      "rol_id": 3,
      "token": "eyJhbGciOiJIUzI1NiIsInR..."
    }
    ```
  * `401 Unauthorized`: `{"message": "Credenciales inválidas"}`

---

### 1.2 Registro de Clientes
* **Método:** `POST`
* **Endpoint:** `/Usuarios`
* **Descripción:** Registra un nuevo cliente con rol ID `3`.
* **Body Request:**
  ```json
  {
    "Nombres": "Carlos",
    "Apellidos": "Mendoza",
    "Correo": "carlos@gmail.com",
    "Contrasena": "clave123",
    "Roles_idRoles": 3
  }
  ```
* **Respuestas:**
  * `201 Created`: `{"idUsuarios": 8, "Nombres": "Carlos", "Correo": "carlos@gmail.com"}`
  * `400 Bad Request`: `{"message": "El correo ya se encuentra registrado"}`

---

### 1.3 CRUD Administrativo de Usuarios
* `GET /Usuarios?select=*&order=idUsuarios.desc`: Lista todos los usuarios con sus roles.
* `PATCH /Usuarios?idUsuarios=eq.{id}`: Actualiza datos y rol de un usuario.
* `DELETE /Usuarios?idUsuarios=eq.{id}`: Elimina un usuario por su identificador.

---

## 2. Módulo de Catálogo y Productos

### 2.1 Listar Productos (Catálogo)
* **Método:** `GET`
* **Endpoint:** `/Productos?select=*&order=idProductos.asc`
* **Parámetros Opcionales de Filtro:**
  * `Categoria_producto_idCategoria=eq.1` (Filtrar por categoría: Cascos, Guantes, Botas, etc.)
  * `Estado=eq.Activo` (Filtrar solo productos activos)
* **Respuesta `200 OK`:**
  ```json
  [
    {
      "idProductos": 3,
      "Nombre_Producto": "Casco Dieléctrico Tipo II con Tafilete Ratchet",
      "Tipo": "Protección Cabeza",
      "Descripcion": "Casco industrial con protección eléctrica hasta 20.000 V.",
      "Precio": 52000.0,
      "Imagen": "https://images.unsplash.com/photo-1578873375972-031f74812f86",
      "Estado": "Activo",
      "Categoria_producto_idCategoria": 1
    }
  ]
  ```

### 2.2 Listar Categorías
* **Método:** `GET`
* **Endpoint:** `/Categoria_productos?select=*&order=idCategorias.asc`
* **Respuesta `200 OK`:**
  ```json
  [
    {"idCategorias": 1, "nombre": "Cascos", "descripcion": "Protección para cabeza"},
    {"idCategorias": 2, "nombre": "Guantes", "descripcion": "Protección para manos"},
    {"idCategorias": 3, "nombre": "Botas", "descripcion": "Calzado de seguridad"}
  ]
  ```

---

## 3. Módulo de Facturación, Recibos y Pedidos

### 3.1 Registrar Nueva Factura / Pedido
* **Método:** `POST`
* **Endpoint:** `/Facturas`
* **Body Request:**
  ```json
  {
    "Usuarios_idUsuarios": 3,
    "Total": 104000.0,
    "Estado": "Pagada",
    "Fecha": "2026-09-22T05:00:00.000Z"
  }
  ```
* **Respuesta `201 Created`:** `{"idFacturas": 12, "Total": 104000.0, "Estado": "Pagada"}`

### 3.2 Insertar Detalle de Factura (Ítems Comprados)
* **Método:** `POST`
* **Endpoint:** `/Detalle_Facturas`
* **Body Request:**
  ```json
  [
    {
      "Factura_idFactura": 12,
      "Productos_idProductos": 3,
      "Cantidad": 2,
      "Precio_Unitario": 52000.0
    }
  ]
  ```

### 3.3 Consultar Historial de Pedidos del Cliente
* **Método:** `GET`
* **Endpoint:** `/Facturas?Usuarios_idUsuarios=eq.{idUsuario}&order=idFacturas.desc`

### 3.4 Consultar Reporte Contable y Recibos (Perfil Contador)
* **Método:** `GET`
* **Endpoint:** `/Facturas?select=*&order=idFacturas.desc`
* **Endpoint Detalle Recibo:** `/Detalle_Facturas?Factura_idFactura=eq.{idFactura}`

---

## 4. Módulo de Garantías y Devoluciones

### 4.1 Crear Solicitud de Devolución
* **Método:** `POST`
* **Endpoint:** `/Devoluciones`
* **Body Request:**
  ```json
  {
    "Facturas_idFacturas": 2,
    "Productos_idProductos": 7,
    "Usuarios_idUsuarios": 3,
    "Cantidad": 1,
    "Motivo": "Talla muy ajustada. Solicito cambio por talla 41.",
    "Estado": "Pendiente",
    "Motivo_Categoria": "Talla incorrecta",
    "Metodo_Reembolso": "Cambio de producto",
    "Metodo_Retorno": "Recogida a domicilio",
    "Direccion_Retorno": "Cra 15 # 85-30, Bogotá",
    "Evidencia_Url": "https://images.unsplash.com/photo-1542291026-7eec264c27ff"
  }
  ```

### 4.2 Resolver Devolución (Aprobación / Cupón / Rechazo)
* **Método:** `PATCH`
* **Endpoint:** `/Devoluciones?idDevoluciones=eq.{id}`
* **Body Request:**
  ```json
  {
    "Estado": "Aprobada",
    "Estado_Tracking": "Resuelta",
    "Comentarios_Admin": "Garantía aprobada exitosamente.",
    "Codigo_Cupon": "CUPON-DEV-100"
  }
  ```

---

## 5. Módulo de Pagos (Mercado Pago)

### 5.1 Crear Preferencia de Pago
* **Método:** `POST`
* **Endpoint:** `/crear-pago`
* **Body Request:**
  ```json
  {
    "carrito": [
      {
        "idProductos": 3,
        "Nombre_Producto": "Casco Dieléctrico Tipo II",
        "Precio": 52000,
        "cantidad": 2
      }
    ]
  }
  ```
* **Respuesta `200 OK`:**
  ```json
  {
    "id": "123456789",
    "init_point": "https://www.mercadopago.com.co/checkout/v1/redirect?pref_id=123456789"
  }
  ```
