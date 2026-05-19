import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/providers/auth_provider.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

enum LoginContexto { entidad, admin }

class LoginScreen extends ConsumerStatefulWidget {
  final LoginContexto contexto;
  const LoginScreen({super.key, required this.contexto});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _cargando   = false;
  bool _googleCargando = false;

  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        _rutarTrasLogin(data.session?.user.email ?? '');
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _rutarTrasLogin(String email) async {
    if (!mounted) return;
    final emailLower = email.toLowerCase();
    final esAdmin = emailLower == 'mgalan26@gmail.com';

    // Si es admin y vino por la opción admin → panel admin
    if (esAdmin && widget.contexto == LoginContexto.admin) {
      context.go(AppRoutes.colaOrganizadores);
      return;
    }

    // Si es admin pero vino por entidad → error
    if (esAdmin && widget.contexto == LoginContexto.entidad) {
      _snack('Usa la opción "Soy administrador" para acceder');
      await Supabase.instance.client.auth.signOut();
      return;
    }

    // Si vino por admin pero no es admin → error
    if (widget.contexto == LoginContexto.admin && !esAdmin) {
      _snack('No tienes permisos de administrador');
      await Supabase.instance.client.auth.signOut();
      return;
    }

    // Flujo entidad
    final org = await ref.read(organizadorProvider.future);
    if (!mounted) return;

    if (org == null) {
      _snack('Tu email no está registrado como organizador');
      await Supabase.instance.client.auth.signOut();
      return;
    }

    switch (org.estado.name) {
      case 'pendiente':
        context.go(AppRoutes.esperaAprobacion);
      case 'aprobado':
        context.go(AppRoutes.misEventos);
      default:
        _snack('Tu cuenta ha sido ${org.estado.name}. Contacta con el administrador.');
        await Supabase.instance.client.auth.signOut();
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      await _rutarTrasLogin(res.user?.email ?? '');
    } on AuthException catch (e) {
      _snack(e.message == 'Invalid login credentials'
          ? 'Email o contraseña incorrectos'
          : e.message);
    } catch (_) {
      _snack('Error inesperado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _googleCargando = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
      );
    } catch (e) {
      _snack('Error al conectar con Google');
    } finally {
      if (mounted) setState(() => _googleCargando = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.contexto == LoginContexto.admin
        ? 'Acceso administrador'
        : 'Acceso para entidades';

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => context.go(AppRoutes.home),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('PGH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.goldColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        )),
                    const SizedBox(height: 4),
                    Text(titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          letterSpacing: 1,
                        )),
                    const SizedBox(height: 40),

                    OutlinedButton.icon(
                      onPressed: _googleCargando ? null : _loginGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.darkBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _googleCargando
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.textPrimary))
                          : Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 18, height: 18,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.login, size: 18),
                            ),
                      label: const Text('Continuar con Google'),
                    ),

                    const SizedBox(height: 20),
                    Row(children: [
                      const Expanded(child: Divider(color: AppTheme.darkBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ),
                      const Expanded(child: Divider(color: AppTheme.darkBorder)),
                    ]),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                        if (!v.contains('@')) return 'Email no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: _cargando ? null : _login,
                      child: _cargando
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.darkBg))
                          : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 20),
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
