import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/models/models.dart';
import 'package:pgh_app/core/providers/auth_provider.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final misEventosProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final data = await Supabase.instance.client
      .from('eventos')
      .select('id, nombre, fecha_inicio, fecha_fin, ciudad, pais, estado, tipo, tiene_presencial, tiene_streaming')
      .eq('organizador_id', userId)
      .order('fecha_inicio', ascending: false);

  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class MisEventosScreen extends ConsumerWidget {
  const MisEventosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync    = ref.watch(organizadorProvider);
    final eventosAsync = ref.watch(misEventosProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Mi Panel'),
        actions: [
          // Admin: acceso directo al panel
          orgAsync.when(
            data: (org) => org != null && org.email == 'mgalan26@gmail.com'
                ? IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    tooltip: 'Panel de administración',
                    onPressed: () => context.go(AppRoutes.colaOrganizadores),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.crearEvento);
          ref.invalidate(misEventosProvider);
        },
        backgroundColor: AppTheme.goldColor,
        foregroundColor: AppTheme.darkBg,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
      body: Column(
        children: [
          // Cabecera del organizador
          orgAsync.when(
            data: (org) => org != null ? _CabeceraOrganizador(org: org) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Lista de eventos
          Expanded(
            child: eventosAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.redAccent))),
              data: (eventos) {
                if (eventos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note_outlined,
                            size: 56, color: AppTheme.textMuted.withAlpha(80)),
                        const SizedBox(height: 16),
                        const Text('Todavía no tienes eventos',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 15)),
                        const SizedBox(height: 8),
                        const Text('Pulsa "Nuevo evento" para empezar',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: eventos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _TarjetaEvento(
                    evento: eventos[i],
                    onEdit: () async {
                      final id = eventos[i]['id'] as String;
                      await context.push('/gestion/eventos/$id/editar');
                      ref.invalidate(misEventosProvider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cabecera ─────────────────────────────────────────────────────────────────

class _CabeceraOrganizador extends StatelessWidget {
  final Organizador org;
  const _CabeceraOrganizador({required this.org});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(bottom: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.goldColor.withAlpha(30),
            child: Text(
              org.nombre.isNotEmpty ? org.nombre[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppTheme.goldColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(org.nombreCompleto,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                if (org.entidad != null)
                  Text(org.entidad!.nombre,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de evento ────────────────────────────────────────────────────────

class _TarjetaEvento extends StatelessWidget {
  final Map<String, dynamic> evento;
  final VoidCallback onEdit;
  const _TarjetaEvento({required this.evento, required this.onEdit});

  Color _colorEstado(String estado) => switch (estado) {
        'publicado'  => Colors.greenAccent,
        'pendiente'  => AppTheme.goldColor,
        'borrador'   => AppTheme.textMuted,
        'rechazado'  => Colors.redAccent,
        'cancelado'  => Colors.redAccent,
        _            => AppTheme.textMuted,
      };

  IconData _iconoEstado(String estado) => switch (estado) {
        'publicado'  => Icons.check_circle_outline,
        'pendiente'  => Icons.schedule_outlined,
        'borrador'   => Icons.edit_note_outlined,
        'rechazado'  => Icons.cancel_outlined,
        'cancelado'  => Icons.block_outlined,
        _            => Icons.help_outline,
      };

  String _modalidad(Map<String, dynamic> e) {
    final presencial = e['tiene_presencial'] as bool? ?? true;
    final streaming  = e['tiene_streaming']  as bool? ?? false;
    if (presencial && streaming) return 'Presencial + Online';
    if (streaming) return 'Online';
    return 'Presencial';
  }

  @override
  Widget build(BuildContext context) {
    final estado  = evento['estado'] as String? ?? 'borrador';
    final nombre  = evento['nombre'] as String? ?? '(sin título)';
    final ciudad  = evento['ciudad'] as String? ?? '';
    final pais    = evento['pais']   as String? ?? '';
    final color   = _colorEstado(estado);

    DateTime? fecha;
    if (evento['fecha_inicio'] != null) {
      try {
        fecha = DateTime.parse(evento['fecha_inicio'] as String);
      } catch (_) {}
    }
    final fechaStr = fecha != null
        ? DateFormat('d MMM yyyy', 'es').format(fecha)
        : '—';

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(nombre,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  // Badge de estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withAlpha(70)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconoEstado(estado), size: 11, color: color),
                        const SizedBox(width: 4),
                        Text(estado,
                            style: TextStyle(color: color, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(fechaStr,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                        [ciudad, pais].where((s) => s.isNotEmpty).join(', '),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.video_call_outlined,
                      size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(_modalidad(evento),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11)),
                  const Spacer(),
                  const Icon(Icons.edit_outlined,
                      size: 13, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  const Text('Editar',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
