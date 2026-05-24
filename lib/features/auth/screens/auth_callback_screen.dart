import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

/// Pantalla de callback OAuth/invite.
///
/// Supabase redirige aquí tras la verificación del token, añadiendo los
/// parámetros en el fragmento de la URL:
///   https://agenda.appgh.net/auth/callback#access_token=…&type=invite
///
/// El SDK de supabase_flutter detecta y procesa el fragmento automáticamente
/// durante la inicialización. Esta pantalla espera el evento SIGNED_IN y
/// redirige al destino apropiado según el tipo de operación.
class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();
    _processCallback();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _processCallback() {
    // Leer el 'type' del fragmento ANTES de que el SDK o el router lo borre.
    final uri      = Uri.base;
    final fragment = uri.fragment;
    final params   = fragment.isNotEmpty
        ? Uri.splitQueryString(fragment)
        : uri.queryParameters;
    final type = params['type'];

    // Si el SDK ya procesó el hash durante Supabase.initialize(), la sesión
    // ya está disponible en currentSession.
    if (Supabase.instance.client.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _redirect(type);
      });
      return;
    }

    // Si todavía no hay sesión, esperar el evento SIGNED_IN del SDK.
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        _redirect(type);
      }
    });
  }

  void _redirect(String? type) {
    // Invitación o recuperación de contraseña → pantalla de establecer clave.
    // Cualquier otro flujo (magic link, etc.) → agenda.
    if (type == 'invite' || type == 'recovery') {
      context.go(AppRoutes.setPassword);
    } else {
      context.go(AppRoutes.agenda);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.goldColor),
            SizedBox(height: 16),
            Text(
              'Verificando acceso...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
