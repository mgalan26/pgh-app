import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final eventosAdminProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('eventos')
      .select(
          'id, nombre, fecha_inicio, ciudad, pais, estado, tipo, '
          'tiene_presencial, tiene_streaming, nota_moderacion, '
          'organizadores(nombre, apellido, email, entidades(nombre))')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class ColaEventosScreen extends ConsumerWidget {
  const ColaEventosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventosAsync = ref.watch(eventosAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Eventos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.colaOrganizadores),
        ),
        actions: [
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
      body: eventosAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.goldColor)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (eventos) {
          if (eventos.isEmpty) {
            return const Center(
              child: Text('No hay eventos registrados',
                  style: TextStyle(color: AppTheme.textMuted)),
            );
          }

          // Separar pendientes primero
          final pendientes = eventos.where((e) => e['estado'] == 'pendiente').toList();
          final resto      = eventos.where((e) => e['estado'] != 'pendiente').toList();
          final todos      = [...pendientes, ...resto];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _TarjetaEventoAdmin(
              evento: todos[i],
              onCambioEstado: () => ref.invalidate(eventosAdminProvider),
            ),
          );
        },
      ),
    );
  }
}

// ─── Tarjeta ──────────────────────────────────────────────────────────────────

class _TarjetaEventoAdmin extends StatelessWidget {
  final Map<String, dynamic> evento;
  final VoidCallback onCambioEstado;
  const _TarjetaEventoAdmin(
      {required this.evento, required this.onCambioEstado});

  Color _colorEstado(String estado) => switch (estado) {
        'publicado'  => Colors.greenAccent,
        'pendiente'  => AppTheme.goldColor,
        'borrador'   => AppTheme.textMuted,
        'rechazado'  => Colors.redAccent,
        'cancelado'  => Colors.redAccent,
        _            => AppTheme.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final estado = evento['estado'] as String? ?? 'borrador';
    final nombre = evento['nombre'] as String? ?? '(sin título)';
    final ciudad = evento['ciudad'] as String? ?? '';
    final pais   = evento['pais']   as String? ?? '';
    final color  = _colorEstado(estado);

    final org      = evento['organizadores'] as Map<String, dynamic>?;
    final entidad  = org?['entidades'] as Map<String, dynamic>?;
    final orgNombre = org != null
        ? '${org['nombre'] ?? ''} ${org['apellido'] ?? ''}'.trim()
        : '';
    final entidadNombre = entidad?['nombre'] as String? ?? '';

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
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withAlpha(70)),
                  ),
                  child:
                      Text(estado, style: TextStyle(color: color, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$fechaStr · $ciudad, $pais',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
            if (orgNombre.isNotEmpty || entidadNombre.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                [orgNombre, entidadNombre]
                    .where((s) => s.isNotEmpty)
                    .join(' · '),
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12),
              ),
            ],

            // Nota de moderación previa
            if (evento['nota_moderacion'] != null &&
                (evento['nota_moderacion'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.orangeAccent.withAlpha(60)),
                ),
                child: Text(
                  'Nota: ${evento['nota_moderacion']}',
                  style: const TextStyle(
                      color: Colors.orangeAccent, fontSize: 11),
                ),
              ),
            ],

            if (estado == 'pendiente') ...[
              const SizedBox(height: 10),
              Row(children: [
                _BotonEstado(
                  label: 'Publicar',
                  color: Colors.greenAccent,
                  eventoId: evento['id'] as String,
                  nuevoEstado: 'publicado',
                  onDone: onCambioEstado,
                ),
                const SizedBox(width: 8),
                _BotonEstado(
                  label: 'Rechazar',
                  color: Colors.redAccent,
                  eventoId: evento['id'] as String,
                  nuevoEstado: 'rechazado',
                  onDone: onCambioEstado,
                  solicitarNota: true,
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Botón de cambio de estado ────────────────────────────────────────────────

class _BotonEstado extends StatefulWidget {
  final String label;
  final Color color;
  final String eventoId;
  final String nuevoEstado;
  final VoidCallback onDone;
  final bool solicitarNota;

  const _BotonEstado({
    required this.label,
    required this.color,
    required this.eventoId,
    required this.nuevoEstado,
    required this.onDone,
    this.solicitarNota = false,
  });

  @override
  State<_BotonEstado> createState() => _BotonEstadoState();
}

class _BotonEstadoState extends State<_BotonEstado> {
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _cargando ? null : _cambiar,
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.color,
        side: BorderSide(color: widget.color.withAlpha(100)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _cargando
          ? SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: widget.color))
          : Text(widget.label, style: const TextStyle(fontSize: 13)),
    );
  }

  Future<void> _cambiar() async {
    String? nota;

    if (widget.solicitarNota && context.mounted) {
      nota = await _pedirNota(context);
      if (nota == null) return; // cancelado
    }

    setState(() => _cargando = true);
    try {
      final update = <String, dynamic>{'estado': widget.nuevoEstado};
      if (nota != null && nota.isNotEmpty) {
        update['nota_moderacion'] = nota;
      }
      await Supabase.instance.client
          .from('eventos')
          .update(update)
          .eq('id', widget.eventoId);
      widget.onDone();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<String?> _pedirNota(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Motivo del rechazo',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Escribe el motivo (opcional)',
            hintStyle: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Rechazar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
