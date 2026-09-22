import 'package:flutter/material.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _claveController = TextEditingController();
  final TextEditingController _confirmarClaveController = TextEditingController();

  bool _mostrarClave = false;
  bool _mostrarConfirmar = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _claveController.dispose();
    _confirmarClaveController.dispose();
    super.dispose();
  }

  // Validación: Solo letras y espacios
  final RegExp _regexSoloLetras = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$');

  void _ejecutarRegistro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nombres = _nombresController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final correo = _correoController.text.trim().toLowerCase();
    final clave = _claveController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Enviar registro al backend
      final resultado = await _authService.registrar(
        nombres: nombres,
        apellidos: apellidos,
        correo: correo,
        contrasena: clave,
      );

      // 2. Intentar inicio de sesión automático si aún no está iniciado
      if (!SessionManager().isLoggedIn) {
        try {
          await _authService.login(correo, clave);
        } catch (_) {
          // Si falla el autologin, se continúa con éxito del registro
        }
      }

      if (!mounted) return;

      // Diálogo de éxito idéntico a SweetAlert2 en React
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF20B2AA), size: 60),
          title: Text(
            '¡Bienvenido(a), $nombres!',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0047AB)),
            textAlign: TextAlign.center,
          ),
          content: Text(
            resultado['message'] ?? 'Tu cuenta ha sido creada con éxito como Cliente.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20B2AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true); // Regresa al Home o Login
              },
              child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ícono de Cabecera con Badge
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 38,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Título
                  const Text(
                    'Crear Cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0047AB),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtítulo
                  const Text(
                    'Únete a Tecnomatic MAV como cliente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Campo: Nombres
                  TextFormField(
                    controller: _nombresController,
                    decoration: _inputDecoration(
                      hint: 'Nombres',
                      icon: Icons.person_outline_rounded,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (val) {
                      final v = val?.trim() ?? '';
                      if (v.isEmpty) return 'Ingresa tus nombres';
                      if (!_regexSoloLetras.hasMatch(v)) {
                        return 'Solo se permiten letras y espacios';
                      }
                      if (v.length < 2) return 'Mínimo 2 letras';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo: Apellidos
                  TextFormField(
                    controller: _apellidosController,
                    decoration: _inputDecoration(
                      hint: 'Apellidos',
                      icon: Icons.badge_outlined,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (val) {
                      final v = val?.trim() ?? '';
                      if (v.isEmpty) return 'Ingresa tus apellidos';
                      if (!_regexSoloLetras.hasMatch(v)) {
                        return 'Solo se permiten letras y espacios';
                      }
                      if (v.length < 2) return 'Mínimo 2 letras';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo: Correo Electrónico
                  TextFormField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      hint: 'Correo electrónico',
                      icon: Icons.email_outlined,
                    ),
                    validator: (val) {
                      final v = val?.trim() ?? '';
                      if (v.isEmpty) return 'Ingresa tu correo';
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'Formato de correo inválido';
                      }
                      final parteUsuario = v.split('@')[0];
                      if (!RegExp(r'[a-zA-Z]').hasMatch(parteUsuario)) {
                        return 'El correo debe incluir letras (no solo números)';
                      }
                      if (parteUsuario.length < 3) {
                        return 'Mínimo 3 caracteres antes del @';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo: Contraseña
                  TextFormField(
                    controller: _claveController,
                    obscureText: !_mostrarClave,
                    decoration: _inputDecoration(
                      hint: 'Contraseña (mínimo 6 caracteres)',
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarClave ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF64748B),
                        ),
                        onPressed: () => setState(() => _mostrarClave = !_mostrarClave),
                      ),
                    ),
                    validator: (val) {
                      final v = val?.trim() ?? '';
                      if (v.isEmpty) return 'Ingresa una contraseña';
                      if (v.length < 6) return 'Debe tener al menos 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo: Confirmar Contraseña
                  TextFormField(
                    controller: _confirmarClaveController,
                    obscureText: !_mostrarConfirmar,
                    decoration: _inputDecoration(
                      hint: 'Confirmar contraseña',
                      icon: Icons.shield_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarConfirmar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF64748B),
                        ),
                        onPressed: () => setState(() => _mostrarConfirmar = !_mostrarConfirmar),
                      ),
                    ),
                    validator: (val) {
                      final v = val?.trim() ?? '';
                      if (v.isEmpty) return 'Confirma tu contraseña';
                      if (v != _claveController.text.trim()) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón Registrarse
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0047AB),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _ejecutarRegistro,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add_alt_1_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Registrarme como Cliente',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Enlace: ¿Ya tienes una cuenta? Inicia sesión aquí
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes una cuenta? ',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Inicia sesión aquí',
                          style: TextStyle(
                            color: Color(0xFF00A896),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),

                  const Text(
                    '© 2026 Tecnomatic MAV',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0047AB), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.8),
      ),
    );
  }
}
