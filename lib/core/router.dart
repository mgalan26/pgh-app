import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pgh_app/core/providers/auth_provider.dart';
import 'package:pgh_app/features/agenda/screens/agenda_screen.dart';
import 'package:pgh_app/features/agenda/screens/evento_detalle_screen.dart';
import 'package:pgh_app/features/agenda/screens/ponente_detalle_screen.dart';
import 'package:pgh_app/features/agenda/screens/entidad_detalle_screen.dart';
import 'package:pgh_app/features/auth/screens/login_screen.dart';
import 'package:pgh_app/features/auth/screens/registro_usuario_screen.dart';
import 'package:pgh_app/features/auth/screens/registro_organizador_screen.dart';
import 'package:pgh_app/features/auth/screens/espera_aprobacion_screen.dart';
import 'package:pgh_app/features/gestion/screens/mis_eventos_screen.dart';
import 'package:pgh_app/features/gestion/screens/evento_form_screen.dart';
import 'package:pgh_app/features/gestion/screens/mi_entidad_screen.dart';
import 'package:pgh_app/features/gestion/screens/mi_perfil_screen.dart';
import 'package:pgh_app/features/admin/screens/cola_organizadores_screen.dart';
import 'package:pgh_app/features/admin/screens/cola_eventos_screen.dart';
import 'package:pgh_app/shared/screens/shell_screen.dart';

class AppRoutes {
  static const agenda              = '/';
  static const eventoDetalle       = '/eventos/:id';
  static const ponenteDetalle      = '/ponentes/:id';
  static const entidadDetalle      = '/entidades/:id';
  static const login               = '/login';
  static const registroUsuario     = '/registro/usuario';
  static const registroOrganizador = '/registro/organizador';
  static const esperaAprobacion    = '/espera-aprobacion';
  static const misEventos          = '/gestion/eventos';
  static const crearEvento         = '/gestion/eventos/nuevo';
  static const editarEvento        = '/gestion/eventos/:id/editar';
  static const miEntidad           = '/gestion/entidad';
  static const miPerfil            = '/gestion/perfil';
  static const colaOrganizadores   = '/admin/organizadores';
  static const colaEventos         = '/admin/eventos';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.agenda,
    redirect: (context, state) {
      final isLoggedIn = authState.value?.session != null;
      if (state.matchedLocation.startsWith('/gestion') && !isLoggedIn) {
        return AppRoutes.login;
      }
      if (state.matchedLocation.startsWith('/admin') && !isLoggedIn) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.agenda,
            builder: (context, state) => const AgendaScreen(),
          ),
          GoRoute(
            path: AppRoutes.eventoDetalle,
            builder: (context, state) => EventoDetalleScreen(
              id: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.ponenteDetalle,
            builder: (context, state) => PonenteDetalleScreen(
              id: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.entidadDetalle,
            builder: (context, state) => EntidadDetalleScreen(
              id: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: AppRoutes.registroUsuario,
            builder: (context, state) => const RegistroUsuarioScreen(),
          ),
          GoRoute(
            path: AppRoutes.registroOrganizador,
            builder: (context, state) => const RegistroOrganizadorScreen(),
          ),
          GoRoute(
            path: AppRoutes.esperaAprobacion,
            builder: (context, state) => const EsperaAprobacionScreen(),
          ),
          GoRoute(
            path: AppRoutes.misEventos,
            builder: (context, state) => const MisEventosScreen(),
          ),
          GoRoute(
            path: AppRoutes.crearEvento,
            builder: (context, state) => const EventoFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.editarEvento,
            builder: (context, state) => EventoFormScreen(
              eventoId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: AppRoutes.miEntidad,
            builder: (context, state) => const MiEntidadScreen(),
          ),
          GoRoute(
            path: AppRoutes.miPerfil,
            builder: (context, state) => const MiPerfilScreen(),
          ),
          GoRoute(
            path: AppRoutes.colaOrganizadores,
            builder: (context, state) => const ColaOrganizadoresScreen(),
          ),
          GoRoute(
            path: AppRoutes.colaEventos,
            builder: (context, state) => const ColaEventosScreen(),
          ),
        ],
      ),
    ],
  );
});
