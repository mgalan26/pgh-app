import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pgh_app/core/providers/auth_provider.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

class ShellScreen extends ConsumerWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session    = ref.watch(sessionProvider);
    final isLoggedIn = session != null;
    final email      = session?.user.email ?? '';
    final isAdmin    = email == 'mgalan26@gmail.com';

    // ── Definir items según estado ──────────────────────────────────────
    final List<_TabItem> tabs = [
      const _TabItem(
        label: 'Agenda',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        route: AppRoutes.agenda,
      ),
      if (isAdmin) ...[
        const _TabItem(
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          route: AppRoutes.admin,
        ),
      ] else if (isLoggedIn) ...[
        const _TabItem(
          label: 'Mi Panel',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          route: AppRoutes.autorizado,
        ),
      ] else ...[
        const _TabItem(
          label: 'Acceder',
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          route: AppRoutes.login,
        ),
      ],
    ];

    // ── Índice activo ───────────────────────────────────────────────────
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i].route == AppRoutes.agenda) {
        if (location == '/') currentIndex = i;
      } else if (location.startsWith(tabs[i].route)) {
        currentIndex = i;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.darkBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: AppTheme.darkBg,
          selectedItemColor: AppTheme.goldColor,
          unselectedItemColor: AppTheme.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => context.go(tabs[i].route),
          items: tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    activeIcon: Icon(t.activeIcon),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
