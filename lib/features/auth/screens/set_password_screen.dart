import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/providers/auth_provider.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1  = true;
  bool _obscure2  = true;
  bool _guardando = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final sb = Supabase.instance.client;

      // 1. Actualizar contraseña en Supabase Auth
      final res = await sb.auth.updateUser(
        UserAttributes(password: _passCtrl.text),
      );
      if (res.user == null) throw Exception('No se pudo guardar la contraseña');

      final user = res.user!;

      // 2. Crear perfil en la tabla usuarios si todavía no existe
      final existing = await sb
          .from('usuarios')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        final meta = user.userMetadata ?? {};
        await sb.from('usuarios').insert({
          'id':                    user.id,
          'email':                 user.email ?? '',
          'nombre':                meta['nombre'] as String?
                                   ?? meta['name'] as String? ?? '',
          'apellido':              meta['apellido'] as String? ?? '',
          'activo':                true,
          'email_verificado':      user.emailConfirmedAt != null,
          'acepta_comunicaciones': false,
        });
      }

      if (!mounted) return;

      // 3. Redirigir según acceso
      final autorizados = await ref.read(usuarioAutorizadoProvider.future);
      if (!mounted) return;

      if (autorizados.isNotEmpty) {
        context.go(AppRoutes.autorizado);
      } else {
        context.go(AppRoutes.agenda);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 56, height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFC9A84C), Color(0xFF8B6914)]),
                        ),
                        child: const Center(
                          child: Text('P',
                            style: TextStyle(
                              color: Color(0xFF0D0D0D),
                              fontWeight: FontWeight.bold,
                              fontSize: 24)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Text('Configura tu contrasena',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),

                    if (user?.email != null) ...[
                      Text(user!.email!,
                        style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 13)),
                      const SizedBox(height: 10),
                    ],

                    const Text(
                      'Elige una contrasena para acceder a tu cuenta en el futuro desde cualquier dispositivo.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5)),
                    const SizedBox(height: 28),

                    // Contraseña
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure1,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Contrasena',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure1
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textMuted, size: 18),
                          onPressed: () =>
                              setState(() => _obscure1 = !_obscure1),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obligatorio';
                        if (v.length < 8) return 'Minimo 8 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirmar
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscure2,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Confirmar contrasena',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure2
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textMuted, size: 18),
                          onPressed: () =>
                              setState(() => _obscure2 = !_obscure2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obligatorio';
                        if (v != _passCtrl.text) {
                          return 'Las contrasenyas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _guardando
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.darkBg))
                          : const Text('Guardar contrasena',
                              style: TextStyle(fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
