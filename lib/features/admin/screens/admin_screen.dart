import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';
import 'admin_tab_eventos.dart';
import 'admin_tab_ponentes.dart';
import 'admin_tab_entidades.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Builder(builder: (context) {
        final tabController = DefaultTabController.of(context);
        return AnimatedBuilder(
          animation: tabController,
          builder: (context, _) {
            final tab = tabController.index;
            return Scaffold(
              backgroundColor: AppTheme.darkBg,
              floatingActionButton: switch (tab) {
                0 => FloatingActionButton.extended(
                    heroTag: 'fab_eventos',
                    onPressed: () => AdminTabEventos.abrirNuevoEvento(context, ref),
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: AppTheme.darkBg,
                    icon: const Icon(Icons.event),
                    label: const Text('Nuevo evento'),
                  ),
                1 => FloatingActionButton.extended(
                    heroTag: 'fab_ponentes',
                    onPressed: () => AdminTabPonentes.abrirForm(context, ref, ponente: null),
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: AppTheme.darkBg,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Nuevo ponente'),
                  ),
                2 => FloatingActionButton.extended(
                    heroTag: 'fab_entidades',
                    onPressed: () => AdminTabEntidades.abrirAltaOrganizador(context, ref),
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: AppTheme.darkBg,
                    icon: const Icon(Icons.business),
                    label: const Text('Nueva entidad'),
                  ),
                _ => null,
              },
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
            ],
          ),
        ),
              body: const TabBarView(
                children: [
                  AdminTabEventos(),
                  AdminTabPonentes(),
                  AdminTabEntidades(),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
