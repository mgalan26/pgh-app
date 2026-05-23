import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final tabAutorizadosPendientesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('usuarios_autorizados')
      .select('*, entidades(nombre)')
      .eq('estado', 'pendiente')
      .order('created_at', ascending: true);
  return List<Map<String, dynamic>>.from(data as List);
});

final tabAutorizadosActivosProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('usuarios_autorizados')
      .select('*, entidades(nombre)')
      .eq('estado', 'activo')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Tab ──────────────────────────────────────────────────────────────────────

class AdminTabAutorizados extends ConsumerWidget {
  const AdminTabAutorizados({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: AppTheme.goldColor,
            indicatorWeight: 2,
            labelColor: AppTheme.goldColor,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'Activos'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ListaPendientes(),
                _ListaActivos(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lista de solicitudes pendientes ──────────────────────────────────────────

class _ListaPendientes extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tabAutorizadosPendientesProvider);

    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.goldColor)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.redAccent))),
      data: (solicitudes) {
        if (solicitudes.isEmpty) {
          return const Center(
            child: Text('No hay solicitudes pendientes',
                style: TextStyle(color: AppTheme.textMuted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: solicitudes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _SolicitudTile(
            solicitud: solicitudes[i],
            onRefresh: () {
              ref.invalidate(tabAutorizadosPendientesProvider);
              ref.invalidate(tabAutorizadosActivosProvider);
            },
          ),
        );
      },
    );
  }
}

// ─── Lista de autorizados activos ─────────────────────────────────────────────

class _ListaActivos extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tabAutorizadosActivosProvider);

    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.goldColor)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.redAccent))),
      data: (activos) {
        if (activos.isEmpty) {
          return const Center(
            child: Text('No hay usuarios autorizados activos',
                style: TextStyle(color: AppTheme.textMuted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: activos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _ActivoTile(
            activo: activos[i],
            onRefresh: () {
              ref.invalidate(tabAutorizadosActivosProvider);
            },
          ),
        );
      },
    );
  }
}

// ─── Tile de solicitud pendiente ──────────────────────────────────────────────

class _SolicitudTile extends StatefulWidget {
  final Map<String, dynamic> solicitud;
  final VoidCallback onRefresh;
  const _SolicitudTile({required this.solicitud, required this.onRefresh});

  @override
  State<_SolicitudTile> createState() => _SolicitudTileState();
}

class _SolicitudTileState extends State<_SolicitudTile> {
  bool _procesando = false;

  Future<void> _cambiarEstado(String nuevoEstado) async {
    setState(() => _procesando = true);
    try {
      await Supabase.instance.client
          .from('usuarios_autorizados')
          .update({'estado': nuevoEstado})
          .eq('id', widget.solicitud['id'] as String);
      if (mounted) widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email     = widget.solicitud['email'] as String? ?? '—';
    final entidad   = widget.solicitud['entidades'];
    final entNombre = entidad is Map ? entidad['nombre'] as String? ?? '—' : '—';
    final fechaRaw  = widget.solicitud['created_at'] as String? ?? '';
    final fecha     = fechaRaw.length >= 10 ? fechaRaw.substring(0, 10) : fechaRaw;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withAlpha(80)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.person_outline,
                color: AppTheme.textMuted, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(email,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
            Text(fecha,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.business_outlined,
                color: AppTheme.textMuted, size: 14),
            const SizedBox(width: 6),
            Text(entNombre,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          if (_procesando)
            const Center(
                child: SizedBox(height: 24, width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.goldColor)))
          else
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cambiarEstado('rechazado'),
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Rechazar',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _cambiarEstado('activo'),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Aprobar',
                      style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ]),
        ],
      ),
    );
  }
}

// ─── Tile de autorizado activo ────────────────────────────────────────────────

class _ActivoTile extends StatefulWidget {
  final Map<String, dynamic> activo;
  final VoidCallback onRefresh;
  const _ActivoTile({required this.activo, required this.onRefresh});

  @override
  State<_ActivoTile> createState() => _ActivoTileState();
}

class _ActivoTileState extends State<_ActivoTile> {
  bool _procesando = false;

  Future<void> _revocar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Revocar acceso',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          '¿Revocar el acceso de este usuario?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Revocar')),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _procesando = true);
    try {
      await Supabase.instance.client
          .from('usuarios_autorizados')
          .update({'estado': 'rechazado'})
          .eq('id', widget.activo['id'] as String);
      if (mounted) widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email     = widget.activo['email'] as String? ?? '—';
    final entidad   = widget.activo['entidades'];
    final entNombre = entidad is Map ? entidad['nombre'] as String? ?? '—' : '—';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF1A2A1A),
          radius: 18,
          child: Icon(Icons.check, color: Colors.green, size: 16),
        ),
        title: Text(email,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 13,
                fontWeight: FontWeight.w600)),
        subtitle: Row(children: [
          const Icon(Icons.business_outlined,
              color: AppTheme.textMuted, size: 12),
          const SizedBox(width: 4),
          Text(entNombre,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11)),
        ]),
        trailing: _procesando
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.goldColor))
            : IconButton(
                icon: const Icon(Icons.block_outlined,
                    color: Colors.redAccent, size: 18),
                tooltip: 'Revocar acceso',
                onPressed: _revocar,
              ),
      ),
    );
  }
}
