import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/models/models.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final tabEventosProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('eventos')
      .select(
          'id, nombre, descripcion, portada_url, fecha_inicio, fecha_fin, hora_inicio, hora_fin, '
          'ciudad, pais, estado, tipo, tiene_presencial, tiene_streaming, '
          'url_online, es_gratuito, email_contacto, enlace_web, '
          'coorganizador_nombre, coorganizador_web, nota_moderacion, ponente_id, '
          'organizadores(nombre, apellido, entidades(nombre)), '
          'ponentes(id, nombre, apellido, cargo)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data as List);
});

final tabPonentesSelectProvider =
    FutureProvider.autoDispose<List<Ponente>>((ref) async {
  final data = await Supabase.instance.client
      .from('ponentes')
      .select()
      .order('apellido', ascending: true);
  return (data as List).map((e) => Ponente.fromJson(e)).toList();
});

final tabOrganizadoresSelectProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('organizadores')
      .select('id, nombre, apellido, entidades(nombre)')
      .eq('estado', 'aprobado')
      .order('apellido', ascending: true);
  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Constantes ───────────────────────────────────────────────────────────────

const _tiposEvento = [
  'Conferencia', 'Mesa redonda', 'Congreso', 'Networking',
  'Cultural', 'Académico', 'Empresarial', 'Político', 'Exposición', 'Otro',
];

const _estadosEvento = [
  'borrador', 'pendiente', 'publicado', 'rechazado', 'cancelado',
];

// ─── Tab principal ────────────────────────────────────────────────────────────

class AdminTabEventos extends ConsumerWidget {
  const AdminTabEventos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tabEventosProvider);

    return Stack(
      children: [
        async.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.goldColor)),
          error: (e, _) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: Colors.redAccent))),
          data: (eventos) {
            if (eventos.isEmpty) {
              return const Center(
                child: Text('No hay eventos',
                    style: TextStyle(color: AppTheme.textMuted)),
              );
            }
            final pendientes = eventos.where((e) => e['estado'] == 'pendiente').toList();
            final resto      = eventos.where((e) => e['estado'] != 'pendiente').toList();
            final todos      = [...pendientes, ...resto];

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: todos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EventoCard(
                evento: todos[i],
                onRefresh: () => ref.invalidate(tabEventosProvider),
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_eventos',
            onPressed: () => _abrirNuevoEvento(context, ref),
            backgroundColor: AppTheme.goldColor,
            foregroundColor: AppTheme.darkBg,
            icon: const Icon(Icons.event),
            label: const Text('Nuevo evento'),
          ),
        ),
      ],
    );
  }

  static Future<void> _abrirNuevoEvento(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EventoNuevoSheet(
          onCreado: () => ref.invalidate(tabEventosProvider)),
    );
  }
}

// ─── Tarjeta evento ───────────────────────────────────────────────────────────

class _EventoCard extends StatelessWidget {
  final Map<String, dynamic> evento;
  final VoidCallback onRefresh;
  const _EventoCard({required this.evento, required this.onRefresh});

  Color _colorEstado(String s) => switch (s) {
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

    final org     = evento['organizadores'] as Map<String, dynamic>?;
    final entidad = org?['entidades'] as Map<String, dynamic>?;
    final orgNombre = org != null
        ? '${org['nombre'] ?? ''} ${org['apellido'] ?? ''}'.trim()
        : '';

    DateTime? fecha;
    if (evento['fecha_inicio'] != null) {
      try { fecha = DateTime.parse(evento['fecha_inicio'] as String); }
      catch (_) {}
    }
    final fechaStr = fecha != null
        ? DateFormat('d MMM yyyy', 'es').format(fecha)
        : '—';

    final ponente = evento['ponentes'] as Map<String, dynamic>?;
    final ponenteStr = ponente != null
        ? '${ponente['nombre'] ?? ''} ${ponente['apellido'] ?? ''}'.trim()
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(nombre,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              _badge(estado, color),
            ]),
            const SizedBox(height: 4),
            Text('$fechaStr · $ciudad, $pais',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
            if (orgNombre.isNotEmpty || entidad != null) ...[
              const SizedBox(height: 2),
              Text(
                [orgNombre, entidad?['nombre'] as String?]
                    .where((s) => s != null && s.isNotEmpty)
                    .join(' · '),
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
            if (ponenteStr != null) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.person_outline,
                    color: AppTheme.textMuted, size: 12),
                const SizedBox(width: 3),
                Text(ponenteStr,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ]),
            ],
            if (evento['nota_moderacion'] != null &&
                (evento['nota_moderacion'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orangeAccent.withAlpha(60)),
                ),
                child: Text('Nota: ${evento['nota_moderacion']}',
                    style: const TextStyle(
                        color: Colors.orangeAccent, fontSize: 11)),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              // Editar
              _accion(
                label: 'Editar',
                icon: Icons.edit_outlined,
                color: AppTheme.goldColor,
                onTap: () async {
                  await _abrirEdicion(context);
                  onRefresh();
                },
              ),
              // Publicar (si no publicado)
              if (estado != 'publicado')
                _accion(
                  label: 'Publicar',
                  icon: Icons.check_circle_outline,
                  color: Colors.greenAccent,
                  onTap: () => _cambiarEstado('publicado', context),
                ),
              // Rechazar (si pendiente o publicado)
              if (estado == 'pendiente' || estado == 'publicado')
                _accion(
                  label: 'Rechazar',
                  icon: Icons.cancel_outlined,
                  color: Colors.redAccent,
                  onTap: () => _pedirNotaYRechazar(context),
                ),
              // Cancelar (si publicado)
              if (estado == 'publicado')
                _accion(
                  label: 'Cancelar',
                  icon: Icons.block_outlined,
                  color: Colors.orange,
                  onTap: () => _cambiarEstado('cancelado', context),
                ),
              // Eliminar
              _accion(
                label: 'Eliminar',
                icon: Icons.delete_outline,
                color: Colors.redAccent,
                onTap: () => _confirmarEliminar(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _badge(String estado, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withAlpha(70)),
    ),
    child: Text(estado, style: TextStyle(color: color, fontSize: 11)),
  );

  Widget _accion({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withAlpha(100)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      );

  Future<void> _cambiarEstado(String nuevoEstado, BuildContext context) async {
    await Supabase.instance.client
        .from('eventos')
        .update({'estado': nuevoEstado})
        .eq('id', evento['id'] as String);
    onRefresh();
  }

  Future<void> _pedirNotaYRechazar(BuildContext context) async {
    final ctrl = TextEditingController();
    final nota = await showDialog<String>(
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
              hintStyle: TextStyle(color: AppTheme.textMuted)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Rechazar')),
        ],
      ),
    );
    if (nota == null) return;
    final update = <String, dynamic>{'estado': 'rechazado'};
    if (nota.isNotEmpty) update['nota_moderacion'] = nota;
    await Supabase.instance.client
        .from('eventos')
        .update(update)
        .eq('id', evento['id'] as String);
    onRefresh();
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Eliminar evento',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '¿Eliminar "${evento['nombre']}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    await Supabase.instance.client
        .from('eventos')
        .delete()
        .eq('id', evento['id'] as String);
    onRefresh();
  }

  Future<void> _abrirEdicion(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EventoEditSheet(evento: evento),
    );
  }
}

// ─── Modal edición evento ─────────────────────────────────────────────────────

class _EventoEditSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> evento;
  const _EventoEditSheet({required this.evento});

  @override
  ConsumerState<_EventoEditSheet> createState() => _EventoEditSheetState();
}

class _EventoEditSheetState extends ConsumerState<_EventoEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl      = TextEditingController(text: widget.evento['nombre'] as String?);
  late final _descripcionCtrl = TextEditingController(text: widget.evento['descripcion'] as String?);
  late final _portadaCtrl     = TextEditingController(text: widget.evento['portada_url'] as String?);
  late final _ciudadCtrl      = TextEditingController(text: widget.evento['ciudad'] as String?);
  late final _notaCtrl        = TextEditingController(text: widget.evento['nota_moderacion'] as String?);
  late final _urlOnlineCtrl   = TextEditingController(text: widget.evento['url_online'] as String?);
  late final _emailCtrl       = TextEditingController(text: widget.evento['email_contacto'] as String?);
  late final _enlaceWebCtrl   = TextEditingController(text: widget.evento['enlace_web'] as String?);

  late String? _tipo       = widget.evento['tipo'] as String?;
  late String? _estado     = widget.evento['estado'] as String?;
  late String? _ponenteId  = widget.evento['ponente_id'] as String?;
  late bool _esGratuito    = widget.evento['es_gratuito'] as bool? ?? true;
  late bool _tienePresencial = widget.evento['tiene_presencial'] as bool? ?? true;
  late bool _tieneStreaming   = widget.evento['tiene_streaming'] as bool? ?? false;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _descripcionCtrl, _portadaCtrl, _ciudadCtrl, _notaCtrl,
      _urlOnlineCtrl, _emailCtrl, _enlaceWebCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await Supabase.instance.client.from('eventos').update({
        'nombre':           _nombreCtrl.text.trim(),
        'descripcion':      _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        'portada_url':      _portadaCtrl.text.trim().isEmpty ? null : _portadaCtrl.text.trim(),
        'ciudad':           _ciudadCtrl.text.trim(),
        'tipo':             _tipo,
        'estado':           _estado,
        'ponente_id':       _ponenteId,
        'es_gratuito':      _esGratuito,
        'tiene_presencial': _tienePresencial,
        'tiene_streaming':  _tieneStreaming,
        'url_online':       _tieneStreaming && _urlOnlineCtrl.text.trim().isNotEmpty
                              ? _urlOnlineCtrl.text.trim() : null,
        'email_contacto':   _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'enlace_web':       _enlaceWebCtrl.text.trim().isEmpty ? null : _enlaceWebCtrl.text.trim(),
        'nota_moderacion':  _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
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
    final asyncPonentes = ref.watch(tabPonentesSelectProvider);

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
              _tf(_nombreCtrl, 'Nombre *',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null),
              const SizedBox(height: 10),
              _tf(_descripcionCtrl, 'Descripción', maxLines: 3),
              const SizedBox(height: 10),
              _tf(_portadaCtrl, 'URL imagen de portada',
                  hint: 'https://...',
                  onChanged: (_) => setState(() {})),
              if (_portadaCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _portadaCtrl.text.trim(),
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withAlpha(80)),
                      ),
                      child: const Center(
                        child: Text('URL no válida o sin acceso',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
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
              _tf(_ciudadCtrl, 'Ciudad *',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _switchRow('Presencial', _tienePresencial,
                    (v) => setState(() => _tienePresencial = v))),
                const SizedBox(width: 12),
                Expanded(child: _switchRow('Streaming', _tieneStreaming,
                    (v) => setState(() => _tieneStreaming = v))),
              ]),
              if (_tieneStreaming) ...[
                const SizedBox(height: 10),
                _tf(_urlOnlineCtrl, 'URL streaming'),
              ],
              const SizedBox(height: 6),
              _switchRow('Entrada gratuita', _esGratuito,
                  (v) => setState(() => _esGratuito = v)),
              const SizedBox(height: 10),
              _tf(_emailCtrl, 'Email contacto'),
              const SizedBox(height: 10),
              _tf(_enlaceWebCtrl, 'Web del evento'),
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
              _tf(_notaCtrl, 'Nota de moderación', maxLines: 2),
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

  Widget _tf(TextEditingController ctrl, String label, {
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator,
        onChanged: onChanged,
      );

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) =>
      Row(children: [
        Expanded(child: Text(label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
        Switch(value: value, onChanged: onChanged,
            activeThumbColor: AppTheme.goldColor),
      ]);
}

// ─── Modal nuevo evento (admin) ───────────────────────────────────────────────

const _paisesEvento = [
  'Argentina', 'Bolivia', 'Chile', 'Colombia', 'Costa Rica', 'Cuba',
  'Ecuador', 'El Salvador', 'España', 'Guatemala', 'Honduras', 'México',
  'Nicaragua', 'Panamá', 'Paraguay', 'Perú', 'Puerto Rico',
  'República Dominicana', 'Uruguay', 'Venezuela',
];

class _EventoNuevoSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreado;
  const _EventoNuevoSheet({required this.onCreado});

  @override
  ConsumerState<_EventoNuevoSheet> createState() => _EventoNuevoSheetState();
}

class _EventoNuevoSheetState extends ConsumerState<_EventoNuevoSheet> {
  final _formKey        = GlobalKey<FormState>();
  final _nombreCtrl     = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ciudadCtrl     = TextEditingController();
  final _portadaCtrl    = TextEditingController();
  final _urlOnlineCtrl  = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _enlaceWebCtrl  = TextEditingController();

  String? _tipo;
  String? _pais = 'España';
  String? _estado = 'publicado';
  String? _ponenteId;
  String? _organizadorId;
  bool _esGratuito     = true;
  bool _tienePresencial = true;
  bool _tieneStreaming  = false;
  DateTime? _fechaInicio;
  TimeOfDay? _horaInicio;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose(); _descripcionCtrl.dispose();
    _ciudadCtrl.dispose(); _portadaCtrl.dispose();
    _urlOnlineCtrl.dispose(); _emailCtrl.dispose(); _enlaceWebCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.goldColor,
            surface: AppTheme.darkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaInicio = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.goldColor,
            surface: AppTheme.darkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _horaInicio = picked);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona una fecha'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() => _guardando = true);
    try {
      await Supabase.instance.client.from('eventos').insert({
        'nombre':           _nombreCtrl.text.trim(),
        'descripcion':      _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        'portada_url':      _portadaCtrl.text.trim().isEmpty ? null : _portadaCtrl.text.trim(),
        'ciudad':           _ciudadCtrl.text.trim(),
        'pais':             _pais,
        'tipo':             _tipo,
        'estado':           _estado,
        'fecha_inicio':     DateFormat('yyyy-MM-dd').format(_fechaInicio!),
        'hora_inicio':      _horaInicio != null
            ? '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}'
            : null,
        'ponente_id':       _ponenteId,
        'organizador_id':   _organizadorId,
        'es_gratuito':      _esGratuito,
        'tiene_presencial': _tienePresencial,
        'tiene_streaming':  _tieneStreaming,
        'url_online':       _tieneStreaming && _urlOnlineCtrl.text.trim().isNotEmpty
                              ? _urlOnlineCtrl.text.trim() : null,
        'email_contacto':   _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'enlace_web':       _enlaceWebCtrl.text.trim().isEmpty ? null : _enlaceWebCtrl.text.trim(),
      });
      widget.onCreado();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Evento creado ✓'),
          backgroundColor: AppTheme.goldColor,
        ));
      }
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
    final asyncPonentes = ref.watch(tabPonentesSelectProvider);
    final asyncOrgs     = ref.watch(tabOrganizadoresSelectProvider);

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
              const Text('Nuevo evento',
                style: TextStyle(color: AppTheme.goldColor, fontSize: 16,
                    fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _tf(_nombreCtrl, 'Nombre *',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null),
              const SizedBox(height: 10),
              _tf(_descripcionCtrl, 'Descripción', maxLines: 3),
              const SizedBox(height: 10),
              _tf(_portadaCtrl, 'URL imagen de portada', hint: 'https://...'),
              const SizedBox(height: 10),

              // Fecha y hora
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFecha,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _fechaInicio != null
                          ? AppTheme.goldColor : AppTheme.textMuted,
                      side: BorderSide(
                        color: _fechaInicio != null
                            ? AppTheme.goldColor.withAlpha(120)
                            : AppTheme.darkBorder),
                    ),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_fechaInicio != null
                        ? DateFormat('d MMM yyyy', 'es').format(_fechaInicio!)
                        : 'Fecha *'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickHora,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _horaInicio != null
                          ? AppTheme.goldColor : AppTheme.textMuted,
                      side: BorderSide(
                        color: _horaInicio != null
                            ? AppTheme.goldColor.withAlpha(120)
                            : AppTheme.darkBorder),
                    ),
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(_horaInicio != null
                        ? _horaInicio!.format(context)
                        : 'Hora'),
                  ),
                ),
              ]),
              const SizedBox(height: 10),

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

              _tf(_ciudadCtrl, 'Ciudad *',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _pais,
                decoration: const InputDecoration(labelText: 'País *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                isExpanded: true,
                items: _paisesEvento.map((p) =>
                    DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _pais = v),
                validator: (v) => v == null ? 'Selecciona un país' : null,
              ),
              const SizedBox(height: 10),

              // Organizador
              asyncOrgs.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (orgs) => DropdownButtonFormField<String>(
                  value: _organizadorId,
                  decoration: const InputDecoration(labelText: 'Organizador'),
                  dropdownColor: AppTheme.darkCard,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Sin asignar —')),
                    ...orgs.map((o) {
                      final entidad = (o['entidades'] as Map?)?['nombre'] as String?;
                      final nombre = '${o['nombre'] ?? ''} ${o['apellido'] ?? ''}'.trim();
                      return DropdownMenuItem(
                        value: o['id'] as String,
                        child: Text(entidad != null ? '$nombre · $entidad' : nombre),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _organizadorId = v),
                ),
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

              Row(children: [
                Expanded(child: _switchRow('Presencial', _tienePresencial,
                    (v) => setState(() => _tienePresencial = v))),
                const SizedBox(width: 12),
                Expanded(child: _switchRow('Streaming', _tieneStreaming,
                    (v) => setState(() => _tieneStreaming = v))),
              ]),
              if (_tieneStreaming) ...[
                const SizedBox(height: 10),
                _tf(_urlOnlineCtrl, 'URL streaming'),
              ],
              const SizedBox(height: 6),
              _switchRow('Entrada gratuita', _esGratuito,
                  (v) => setState(() => _esGratuito = v)),
              const SizedBox(height: 10),
              _tf(_emailCtrl, 'Email contacto'),
              const SizedBox(height: 10),
              _tf(_enlaceWebCtrl, 'Web del evento'),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(labelText: 'Estado'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: _estadosEvento.map((s) =>
                    DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _estado = v),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.darkBg))
                    : const Text('Crear evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController ctrl, String label, {
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator,
      );

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) =>
      Row(children: [
        Expanded(child: Text(label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
        Switch(value: value, onChanged: onChanged,
            activeThumbColor: AppTheme.goldColor),
      ]);
}
