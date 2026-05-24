import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/models/models.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final eventosAdminProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('eventos')
      .select(
          'id, nombre, descripcion, fecha_inicio, fecha_fin, hora_inicio, hora_fin, '
          'ciudad, pais, estado, tipo, tiene_presencial, tiene_streaming, '
          'url_online, venue_nombre_libre, es_gratuito, url_reserva, '
          'email_contacto, enlace_web, coorganizador_nombre, coorganizador_web, '
          'nota_moderacion, ponente_id, '
          'entidades(nombre), '
          'ponentes(id, nombre, apellido, cargo)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data as List);
});

final ponentesAdminProvider =
    FutureProvider.autoDispose<List<Ponente>>((ref) async {
  final data = await Supabase.instance.client
      .from('ponentes')
      .select()
      .order('apellido', ascending: true);
  return (data as List).map((e) => Ponente.fromJson(e)).toList();
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
          onPressed: () => context.go(AppRoutes.admin),
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

class _TarjetaEventoAdmin extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = evento['estado'] as String? ?? 'borrador';
    final nombre = evento['nombre'] as String? ?? '(sin título)';
    final ciudad = evento['ciudad'] as String? ?? '';
    final pais   = evento['pais']   as String? ?? '';
    final color  = _colorEstado(estado);

    final entidadNombre = (evento['entidades'] as Map<String, dynamic>?)?['nombre'] as String? ?? '';

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
            if (entidadNombre.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                entidadNombre,
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

            // Ponente asignado
            if (evento['ponentes'] != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person_outline,
                  color: AppTheme.textMuted, size: 12),
                const SizedBox(width: 4),
                Text(
                  () {
                    final p = evento['ponentes'] as Map<String, dynamic>;
                    final n = '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'.trim();
                    final c = p['cargo'] as String?;
                    return c != null ? '$n · $c' : n;
                  }(),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ]),
            ],

            const SizedBox(height: 10),
            Row(children: [
              // Botón editar siempre visible
              OutlinedButton.icon(
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppTheme.darkCard,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => _AdminEventoEditSheet(
                      evento: evento,
                      ref: ref,
                    ),
                  );
                  onCambioEstado();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.goldColor,
                  side: BorderSide(color: AppTheme.goldColor.withAlpha(100)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Editar', style: TextStyle(fontSize: 13)),
              ),
              if (estado == 'pendiente') ...[
                const SizedBox(width: 8),
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
              ],
            ]),
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

// ─── Modal de edición de evento (admin) ───────────────────────────────────────

const _tiposEvento = [
  'Conferencia', 'Mesa redonda', 'Congreso', 'Networking',
  'Cultural', 'Académico', 'Empresarial', 'Político', 'Exposición', 'Otro',
];

const _estadosEvento = [
  'borrador', 'pendiente', 'publicado', 'rechazado', 'cancelado',
];

class _AdminEventoEditSheet extends StatefulWidget {
  final Map<String, dynamic> evento;
  final WidgetRef ref;
  const _AdminEventoEditSheet({required this.evento, required this.ref});

  @override
  State<_AdminEventoEditSheet> createState() => _AdminEventoEditSheetState();
}

class _AdminEventoEditSheetState extends State<_AdminEventoEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl      = TextEditingController(text: widget.evento['nombre'] as String?);
  late final _descripcionCtrl = TextEditingController(text: widget.evento['descripcion'] as String?);
  late final _ciudadCtrl      = TextEditingController(text: widget.evento['ciudad'] as String?);
  late final _notaCtrl        = TextEditingController(text: widget.evento['nota_moderacion'] as String?);
  late final _urlOnlineCtrl   = TextEditingController(text: widget.evento['url_online'] as String?);
  late final _emailCtrl       = TextEditingController(text: widget.evento['email_contacto'] as String?);
  late final _enlaceWebCtrl   = TextEditingController(text: widget.evento['enlace_web'] as String?);

  late String? _tipo    = widget.evento['tipo'] as String?;
  late String? _estado  = widget.evento['estado'] as String?;
  late String? _ponenteId = widget.evento['ponente_id'] as String?;
  late bool _esGratuito = widget.evento['es_gratuito'] as bool? ?? true;
  late bool _tienePresencial = widget.evento['tiene_presencial'] as bool? ?? true;
  late bool _tieneStreaming  = widget.evento['tiene_streaming'] as bool? ?? false;

  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _descripcionCtrl, _ciudadCtrl, _notaCtrl,
      _urlOnlineCtrl, _emailCtrl, _enlaceWebCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await Supabase.instance.client.from('eventos').update({
        'nombre':          _nombreCtrl.text.trim(),
        'descripcion':     _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        'ciudad':          _ciudadCtrl.text.trim(),
        'tipo':            _tipo,
        'estado':          _estado,
        'ponente_id':      _ponenteId,
        'es_gratuito':     _esGratuito,
        'tiene_presencial': _tienePresencial,
        'tiene_streaming': _tieneStreaming,
        'url_online':      _tieneStreaming && _urlOnlineCtrl.text.trim().isNotEmpty
                             ? _urlOnlineCtrl.text.trim() : null,
        'email_contacto':  _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'enlace_web':      _enlaceWebCtrl.text.trim().isEmpty ? null : _enlaceWebCtrl.text.trim(),
        'nota_moderacion': _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
      }).eq('id', widget.evento['id'] as String);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncPonentes = widget.ref.watch(ponentesAdminProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Editar evento',
                style: TextStyle(color: AppTheme.goldColor, fontSize: 16,
                    fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Nombre
              TextFormField(
                controller: _nombreCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 10),

              // Descripción
              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 10),

              // Tipo
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: _tiposEvento.map((t) =>
                  DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _tipo = v),
                validator: (v) => v == null ? 'Selecciona un tipo' : null,
              ),
              const SizedBox(height: 10),

              // Ciudad
              TextFormField(
                controller: _ciudadCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Ciudad *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 10),

              // Modalidad
              Row(children: [
                Expanded(child: _switchRow('Presencial', _tienePresencial,
                  (v) => setState(() => _tienePresencial = v))),
                const SizedBox(width: 12),
                Expanded(child: _switchRow('Streaming', _tieneStreaming,
                  (v) => setState(() => _tieneStreaming = v))),
              ]),
              if (_tieneStreaming) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _urlOnlineCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'URL streaming'),
                ),
              ],
              const SizedBox(height: 10),

              // Gratuito
              _switchRow('Entrada gratuita', _esGratuito,
                (v) => setState(() => _esGratuito = v)),
              const SizedBox(height: 10),

              // Email y web
              TextFormField(
                controller: _emailCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Email contacto'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _enlaceWebCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Web del evento'),
              ),
              const SizedBox(height: 10),

              // Ponente
              asyncPonentes.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (ponentes) => DropdownButtonFormField<String>(
                  value: _ponenteId,
                  decoration: const InputDecoration(labelText: 'Ponente principal'),
                  dropdownColor: AppTheme.darkCard,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Sin ponente —')),
                    ...ponentes.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.nombreCompleto}${p.cargo != null ? " · ${p.cargo}" : ""}'),
                    )),
                  ],
                  onChanged: (v) => setState(() => _ponenteId = v),
                ),
              ),
              const SizedBox(height: 10),

              // Estado
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(labelText: 'Estado'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: _estadosEvento.map((s) =>
                  DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _estado = v),
              ),
              const SizedBox(height: 10),

              // Nota moderación
              TextFormField(
                controller: _notaCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Nota de moderación'),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.darkBg))
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) =>
    Row(children: [
      Expanded(child: Text(label,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
      Switch(value: value, onChanged: onChanged,
        activeThumbColor: AppTheme.goldColor),
    ]);
}
