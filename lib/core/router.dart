import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pgh_app/core/providers/auth_provider.dart';
import 'package:pgh_app/features/agenda/screens/agenda_screen.dart';
import 'package:pgh_app/features/agenda/screens/entidades_screen.dart';
import 'package:pgh_app/features/agenda/screens/ponentes_screen.dart';
import 'package:pgh_app/features/agenda/screens/evento_detalle_screen.dart';
import 'package:pgh_app/features/agenda/screens/ponente_detalle_screen.dart';
import 'package:pgh_app/features/agenda/screens/entidad_detalle_screen.dart';
import 'package:pgh_app/features/auth/screens/login_screen.dart';
import 'package:pgh_app/features/auth/screens/registro_usuario_screen.dart';
import 'package:pgh_app/features/auth/screens/auth_callback_screen.dart';
import 'package:pgh_app/features/auth/screens/set_password_screen.dart';
import 'package:pgh_app/features/admin/screens/admin_screen.dart';
import 'package:pgh_app/features/admin/screens/cola_eventos_screen.dart';
import 'package:pgh_app/features/admin/screens/ponentes_screen.dart' as admin_ponentes;
import 'package:pgh_app/features/gestion/screens/evento_form_screen.dart';
import 'package:pgh_app/features/cuenta/cuenta_screen.dart';
import 'package:pgh_app/features/autorizado/screens/autorizado_screen.dart';
import 'package:pgh_app/features/autorizado/screens/solicitar_autorizacion_screen.dart';
import 'package:pgh_app/features/shell/main_shell.dart';

class AppRoutes {
  static const agenda              = '/agenda';
  static const entidades           = '/entidades';
  static const ponentes            = '/ponentes';
  static const eventoDetalle       = '/eventos/:id';
  static const ponenteDetalle      = '/ponentes/:id';
  static const entidadDetalle      = '/entidades/:id';
  static const login               = '/login';
  static const loginEntidad        = '/login/entidad';
  static const loginAdmin          = '/login/admin';
  static const registroUsuario     = '/registro/usuario';
  static const admin               = '/admin';
  static const colaEventos         = '/admin/eventos';
  static const adminPonentes       = '/admin/ponentes';
  static const adminCrearEvento    = '/admin/crear-evento';
  static const cuenta              = '/cuenta';
  static const autorizado          = '/autorizado';
  static const solicitarAutorizacion = '/solicitar-autorizacion';
  static const setPassword           = '/set-password';
  static const authCallback          = '/auth/callback';
  // kept for ponente profile (future use)
  static const miPerfil            = '/gestion/perfil';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.agenda,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/') return AppRoutes.agenda;
      final isLoggedIn = authState.value?.session != null;
      if (loc == AppRoutes.cuenta && !isLoggedIn) {
        return AppRoutes.login;
      }
      if ((loc == AppRoutes.admin || loc.startsWith('/admin/')) && !isLoggedIn) {
        return AppRoutes.login;
      }
      if (loc == AppRoutes.autorizado && !isLoggedIn) {
        return AppRoutes.login;
      }
      if (loc == AppRoutes.solicitarAutorizacion && !isLoggedIn) {
        return AppRoutes.login;
      }
      if (loc == AppRoutes.setPassword && !isLoggedIn) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      // ── Sin shell (sin bottom nav) ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(contexto: LoginContexto.entidad),
      ),
      GoRoute(
        path: AppRoutes.loginEntidad,
        builder: (_, __) => const LoginScreen(contexto: LoginContexto.entidad),
      ),
      GoRoute(
        path: AppRoutes.loginAdmin,
        builder: (_, __) => const LoginScreen(contexto: LoginContexto.admin),
      ),
      GoRoute(
        path: AppRoutes.registroUsuario,
        builder: (_, __) => const RegistroUsuarioScreen(),
      ),
      GoRoute(
        path: AppRoutes.setPassword,
        builder: (_, __) => const SetPasswordScreen(),
      ),
      // Callback de invitación / recuperación de contraseña.
      // Sin guard: llega sin sesión activa y el token está en el hash de la URL.
      GoRoute(
        path: AppRoutes.authCallback,
        builder: (_, __) => const AuthCallbackScreen(),
      ),

      // ── Shell con bottom nav ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Públicas
          GoRoute(
            path: AppRoutes.agenda,
            builder: (_, __) => const AgendaScreen(),
          ),
          GoRoute(
            path: AppRoutes.entidades,
            builder: (_, __) => const EntidadesScreen(),
          ),
          GoRoute(
            path: AppRoutes.ponentes,
            builder: (_, __) => const PonentesScreen(),
          ),
          GoRoute(
            path: AppRoutes.eventoDetalle,
            builder: (_, s) => EventoDetalleScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.ponenteDetalle,
            builder: (_, s) => PonenteDetalleScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.entidadDetalle,
            builder: (_, s) => EntidadDetalleScreen(id: s.pathParameters['id']!),
          ),
          // Admin
          GoRoute(
            path: AppRoutes.admin,
            builder: (_, __) => const AdminScreen(),
          ),
          GoRoute(
            path: AppRoutes.colaEventos,
            builder: (_, __) => const ColaEventosScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminPonentes,
            builder: (_, __) => const admin_ponentes.PonentesScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminCrearEvento,
            builder: (_, __) => const EventoFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.cuenta,
            builder: (_, __) => const CuentaScreen(),
          ),
          GoRoute(
            path: AppRoutes.autorizado,
            builder: (_, __) => const AutorizadoScreen(),
          ),
          GoRoute(
            path: AppRoutes.solicitarAutorizacion,
            builder: (_, __) => const SolicitarAutorizacionScreen(),
          ),
        ],
      ),
    ],
  );
});
