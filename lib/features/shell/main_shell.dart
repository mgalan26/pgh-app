import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/providers/auth_provider.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location  = GoRouterState.of(context).matchedLocation;
    final authAsync = ref.watch(authStateProvider);
    final orgAsync  = ref.watch(organizadorProvider);

    final isLoggedIn = authAsync.value?.session != null;
    final email      = authAsync.value?.session?.user.email?.toLowerCase() ?? '';
    final isAdmin    = email == 'mgalan26@gmail.com';
    final org        = orgAsync.valueOrNull;
    final isOrg      = org != null && org.isAprobado && !isAdmin;

    // Tab activo según la ruta
    int currentTab;
    if (location.startsWith('/entidades')) {
      currentTab = 1;
    } else if (location.startsWith('/ponentes')) {
      currentTab = 2;
    } else if (location.startsWith('/gestion')) {
      currentTab = 4;
    } else if (location.startsWith('/admin')) {
      currentTab = 5;
    } else {
      currentTab = 0; // agenda + detalle de eventos
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                // 0 · Agenda
                _Tab(
                  icon: Icons.event_note_outlined,
                  label: 'Agenda',
                  isCurrent: currentTab == 0,
                  isEnabled: true,
                  onTap: () => context.go(AppRoutes.agenda),
                ),
                // 1 · Entidades (público)
                _Tab(
                  icon: Icons.business_outlined,
                  label: 'Entidades',
                  isCurrent: currentTab == 1,
                  isEnabled: true,
                  onTap: () => context.go(AppRoutes.entidades),
                ),
                // 2 · Ponentes (público)
                _Tab(
                  icon: Icons.record_voice_over_outlined,
                  label: 'Ponentes',
                  isCurrent: currentTab == 2,
                  isEnabled: true,
                  onTap: () => context.go(AppRoutes.ponentes),
                ),
                // 3 · Acceder / Cuenta
                _Tab(
                  icon: isLoggedIn ? Icons.person : Icons.login,
                  label: isLoggedIn ? 'Cuenta' : 'Acceder',
                  isCurrent: false,
                  isEnabled: true,
                  onTap: () {
                    if (isLoggedIn) {
                      _showCuenta(context, ref, email, org?.nombreCompleto);
                    } else {
                      context.push(AppRoutes.login);
                    }
                  },
                ),
                // 4 · Mi Entidad (solo organizer aprobado)
                _Tab(
                  icon: Icons.dashboard_outlined,
                  label: 'Mi Panel',
                  isCurrent: currentTab == 4,
                  isEnabled: isOrg,
                  onTap: isOrg ? () => context.go(AppRoutes.misEventos) : null,
                ),
                // 5 · Admin (solo mgalan26)
                _Tab(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin',
                  isCurrent: currentTab == 5,
                  isEnabled: isAdmin,
                  onTap: isAdmin ? () => context.go(AppRoutes.admin) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCuenta(
    BuildContext context,
    WidgetRef ref,
    String email,
    String? nombre,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.goldColor.withAlpha(40),
              child: Text(
                (nombre?.isNotEmpty == true ? nombre![0] : email[0])
                    .toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.goldColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (nombre != null)
              Text(nombre,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            Text(email,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.agenda);
                  await Supabase.instance.client.auth.signOut();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Item del tab ─────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCurrent;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _Tab({
    required this.icon,
    required this.label,
    required this.isCurrent,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (isCurrent) {
      color = AppTheme.goldColor;
    } else if (isEnabled) {
      color = const Color(0xFF888888);
    } else {
      color = const Color(0xFF2E2E2E);
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: isCurrent
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
