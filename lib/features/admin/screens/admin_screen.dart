import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';
import 'admin_tab_eventos.dart';
import 'admin_tab_ponentes.dart';
import 'admin_tab_entidades.dart';
import 'admin_tab_autorizados.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Builder(builder: (context) {
        final tabController = DefaultTabController.of(context);
        return AnimatedBuilder(
          animation: tabController,
          builder: (context, _) {
            final tab = tabController.index;

            // Botón "+" que cambia según el tab activo (tab 3 tiene su propio form)
            String? label;
            VoidCallback? onTap;
            if (tab == 0) {
              label = 'Nuevo evento';
              onTap = () => context.go(AppRoutes.crearEvento);
            } else if (tab == 1) {
              label = 'Nuevo ponente';
              onTap = () => AdminTabPonentes.abrirForm(context, ref, ponente: null);
            } else if (tab == 2) {
              label = 'Nueva entidad';
              onTap = () => AdminTabEntidades.abrirAltaOrganizador(context, ref);
            }

            return Scaffold(
              backgroundColor: AppTheme.darkBg,
              appBar: AppBar(
                backgroundColor: AppTheme.darkBg,
                elevation: 0,
                title: Row(children: [
                  Container(
                    width: 28, height: 28,
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
                          fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Panel Admin',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                ]),
                actions: [
                  if (label != null)
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(label, style: const TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.goldColor),
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
                    tooltip: 'Cerrar sesión',
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                  ),
                ],
                bottom: const TabBar(
                  indicatorColor: AppTheme.goldColor,
                  indicatorWeight: 2,
                  labelColor: AppTheme.goldColor,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(icon: Icon(Icons.event_note_outlined, size: 20), text: 'Eventos'),
                    Tab(icon: Icon(Icons.record_voice_over_outlined, size: 20), text: 'Ponentes'),
                    Tab(icon: Icon(Icons.business_outlined, size: 20), text: 'Entidades'),
                    Tab(icon: Icon(Icons.verified_user_outlined, size: 20), text: 'Accesos'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  AdminTabEventos(),
                  AdminTabPonentes(),
                  AdminTabEntidades(),
                  AdminTabAutorizados(),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
