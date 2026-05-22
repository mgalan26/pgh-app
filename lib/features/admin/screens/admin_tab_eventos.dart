import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final tabEventosProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('eventos')
      .select(
          'id, nombre, descripcion, fecha_inicio, hora_inicio, '
          'ciudad, pais, estado, tipo, ponente_id, organizador_id, '
          'nota_moderacion, entidad_id, '
          'tiene_presencial, tiene_streaming, url_online, '
          'venue_nombre_libre, es_gratuito, url_reserva, '
          'portada_url, email_contacto, enlace_web, '
          'coorganizador_nombre, coorganizador_web, '
          'organizadores(nombre, apellido, entidades(nombre)), '
          'ponentes(id, nombre, apellido, cargo)')
      .order('fecha_inicio', ascending: false);
  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Constantes ───────────────────────────────────────────────────────────────

const _estadosEvento = [
  'borrador', 'pendiente', 'publicado', 'rechazado', 'cancelado',
];

const _tiposEvento = [
  'Conferencia', 'Mesa redonda', 'Congreso', 'Networking',
  'Cultural', 'Académico', 'Empresarial', 'Político', 'Exposición', 'Otro',
];

const _paisesEvento = [
  'Argentina', 'Bolivia', 'Chile', 'Colombia', 'Costa Rica', 'Cuba',
  'Ecuador', 'El Salvador', 'España', 'Guatemala', 'Honduras', 'México',
  'Nicaragua', 'Panamá', 'Paraguay', 'Perú', 'Puerto Rico',
  'República Dominicana', 'Uruguay', 'Venezuela',
];

// ─── Tab ──────────────────────────────────────────────────────────────────────

class AdminTabEventos extends ConsumerWidget {
  const AdminTabEventos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tabEventosProvider);

    return async.when(
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
        // Pendientes al principio
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
    );
  }

  static Future<void> abrirNuevoEvento(
      BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FormNuevoEvento(
          onCreado: () => ref.invalidate(tabEventosProvider)),
    );
  }
}

// ─── Tarjeta evento expandible ────────────────────────────────────────────────

class _EventoCard extends StatefulWidget {
  final Map<String, dynamic> evento;
  final VoidCallback onRefresh;
  const _EventoCard({required this.evento, required this.onRefresh});

  @override
  State<_EventoCard> createState() => _EventoCardState();
}

class _EventoCardState extends State<_EventoCard> {
  bool _expandida = false;

  Color _colorEstado(String s) => switch (s) {
        'publicado' => Colors.greenAccent,
        'pendiente' => AppTheme.goldColor,
        'borrador'  => AppTheme.textMuted,
        'rechazado' => Colors.redAccent,
        'cancelado' => Colors.redAccent,
        _           => AppTheme.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final nombre = widget.evento['nombre'] as String? ?? '(sin título)';
    final estado = widget.evento['estado'] as String? ?? 'borrador';
    final ciudad = widget.evento['ciudad'] as String? ?? '';
    final pais   = widget.evento['pais']   as String? ?? '';
    final color  = _colorEstado(estado);

    final org     = widget.evento['organizadores'] as Map<String, dynamic>?;
    final entidad = org?['entidades'] as Map<String, dynamic>?;
    final ponente = widget.evento['ponentes']     as Map<String, dynamic>?;

    final nota = widget.evento['nota_moderacion'] as String?;

    DateTime? fecha;
    if (widget.evento['fecha_inicio'] != null) {
      try { fecha = DateTime.parse(widget.evento['fecha_inicio'] as String); }
      catch (_) {}
    }
    final fechaStr = fecha != null
        ? DateFormat('d MMM yyyy', 'es').format(fecha)
        : '—';

    return Card(
      child: Column(
        children: [
          // ── Cabecera (siempre visible) ──────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expandida = !_expandida),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(nombre,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withAlpha(70)),
                      ),
                      child: Text(estado,
                          style: TextStyle(color: color, fontSize: 10)),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expandida
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    [fechaStr, ciudad, pais]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  if (nota != null && nota.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.orangeAccent.withAlpha(60)),
                      ),
                      child: Text('Nota: $nota',
                          style: const TextStyle(
                              color: Colors.orangeAccent, fontSize: 11)),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _accion('Editar', Icons.edit_outlined, AppTheme.goldColor,
                        () => _abrirEdicion(context)),
                    if (estado != 'publicado')
                      _accion('Publicar', Icons.check_circle_outline,
                          Colors.greenAccent,
                          () => _cambiarEstado('publicado')),
                    if (estado == 'pendiente' || estado == 'publicado')
                      _accion('Rechazar', Icons.cancel_outlined,
                          Colors.redAccent,
                          () => _pedirNotaYRechazar(context)),
                    _accion('Eliminar', Icons.delete_outline, Colors.redAccent,
                        () => _confirmarEliminar()),
                  ]),
                ],
              ),
            ),
          ),

          // ── Sección expandida ───────────────────────────────────────────────
          if (_expandida) ...[
            const Divider(color: AppTheme.darkBorder, height: 1),
            if (org == null && ponente == null)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Sin organizador ni ponente asignados',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (org != null)
                      _infoRow(
                        Icons.business_outlined,
                        [
                          '${org['nombre'] ?? ''} ${org['apellido'] ?? ''}'
                              .trim(),
                          entidad?['nombre'] as String?,
                        ]
                            .where((s) => s != null && s.isNotEmpty)
                            .join(' · '),
                      ),
                    if (org != null && ponente != null)
                      const SizedBox(height: 6),
                    if (ponente != null)
                      _infoRow(
                        Icons.person_outline,
                        [
                          '${ponente['nombre'] ?? ''} ${ponente['apellido'] ?? ''}'
                              .trim(),
                          ponente['cargo'] as String?,
                        ]
                            .where((s) => s != null && s.isNotEmpty)
                            .join(' · '),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
        Icon(icon, color: AppTheme.textMuted, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ),
      ]);

  Widget _accion(
          String label, IconData icon, Color color, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withAlpha(100)),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      );

  Future<void> _abrirEdicion(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EventoEditSheet(evento: widget.evento),
    );
    widget.onRefresh();
  }

  Future<void> _confirmarEliminar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Eliminar evento',
            style: TextStyle(color: Color(0xFFF0E8D8))),
        content: const Text('¿Seguro que quieres eliminar este evento?',
            style: TextStyle(color: Color(0xFF888888))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    try {
      await Supabase.instance.client
          .from('eventos')
          .delete()
          .eq('id', widget.evento['id'] as String);
      if (mounted) widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    await Supabase.instance.client
        .from('eventos')
        .update({'estado': nuevoEstado})
        .eq('id', widget.evento['id'] as String);
    widget.onRefresh();
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
              style:
                  TextButton.styleFrom(foregroundColor: Colors.redAccent),
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
        .eq('id', widget.evento['id'] as String);
    widget.onRefresh();
  }
}

// ─── Modal editar evento ──────────────────────────────────────────────────────

class _EventoEditSheet extends StatefulWidget {
  final Map<String, dynamic> evento;
  const _EventoEditSheet({required this.evento});

  @override
  State<_EventoEditSheet> createState() => _EventoEditSheetState();
}

class _EventoEditSheetState extends State<_EventoEditSheet> {
  final _formKey             = GlobalKey<FormState>();
  late final _nombreCtrl      = TextEditingController(
      text: widget.evento['nombre'] as String?);
  late final _descripcionCtrl = TextEditingController(
      text: widget.evento['descripcion'] as String?);
  late final _ciudadCtrl      = TextEditingController(
      text: widget.evento['ciudad'] as String?);
  late final _emailCtrl       = TextEditingController(
      text: widget.evento['email_contacto'] as String?);
  late final _enlaceWebCtrl   = TextEditingController(
      text: widget.evento['enlace_web'] as String?);
  late final _notaCtrl        = TextEditingController(
      text: widget.evento['nota_moderacion'] as String?);
  late final _venueNombreCtrl = TextEditingController(
      text: widget.evento['venue_nombre_libre'] as String?);
  late final _urlOnlineCtrl   = TextEditingController(
      text: widget.evento['url_online'] as String?);
  late final _urlReservaCtrl  = TextEditingController(
      text: widget.evento['url_reserva'] as String?);
  late final _portadaUrlCtrl  = TextEditingController(
      text: widget.evento['portada_url'] as String?);
  late final _coorgNombreCtrl = TextEditingController(
      text: widget.evento['coorganizador_nombre'] as String?);
  late final _coorgWebCtrl    = TextEditingController(
      text: widget.evento['coorganizador_web'] as String?);

  late String? _tipo       = widget.evento['tipo']   as String?;
  late String? _estado     = widget.evento['estado'] as String?;
  late String? _pais       = widget.evento['pais']   as String?;
  late String? _ponenteId  = widget.evento['ponente_id'] as String?;
  late String? _entidadId  = widget.evento['entidad_id'] as String?;
  late bool _tienePresencial = (widget.evento['tiene_presencial'] as bool?) ?? true;
  late bool _tieneStreaming  = (widget.evento['tiene_streaming']  as bool?) ?? false;
  late bool _esGratuito      = (widget.evento['es_gratuito']      as bool?) ?? true;

  late DateTime? _fechaInicio = () {
    try {
      return widget.evento['fecha_inicio'] != null
          ? DateTime.parse(widget.evento['fecha_inicio'] as String)
          : null;
    } catch (_) {
      return null;
    }
  }();
  bool _guardando       = false;
  bool _subiendoPortada = false;

  List<Map<String, dynamic>>? _ponentes;
  List<Map<String, dynamic>>? _entidades;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final sb = Supabase.instance.client;
    final results = await Future.wait([
      sb.from('ponentes')
          .select('id, nombre, apellido, cargo')
          .order('apellido', ascending: true),
      sb.from('entidades')
          .select('id, nombre')
          .eq('activa', true)
          .order('nombre', ascending: true),
    ]);
    if (mounted) {
      setState(() {
        _ponentes  = List<Map<String, dynamic>>.from(results[0] as List);
        _entidades = List<Map<String, dynamic>>.from(results[1] as List);
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _descripcionCtrl, _ciudadCtrl,
      _emailCtrl, _enlaceWebCtrl, _notaCtrl,
      _venueNombreCtrl, _urlOnlineCtrl, _urlReservaCtrl,
      _portadaUrlCtrl, _coorgNombreCtrl, _coorgWebCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now().add(const Duration(days: 7)),
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

  Future<void> _subirImagenPortada() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _subiendoPortada = true);
    try {
      final bytes = await picked.readAsBytes();
      final path = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('Portadas')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      final url = Supabase.instance.client.storage
          .from('Portadas')
          .getPublicUrl(path);
      if (mounted) setState(() => _portadaUrlCtrl.text = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al subir imagen: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _subiendoPortada = false);
    }
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
      await Supabase.instance.client.from('eventos').update({
        'nombre':              _nombreCtrl.text.trim(),
        'descripcion':         _empty(_descripcionCtrl),
        'ciudad':              _ciudadCtrl.text.trim(),
        'pais':                _pais,
        'tipo':                _tipo,
        'estado':              _estado,
        'fecha_inicio':        DateFormat('yyyy-MM-dd').format(_fechaInicio!),
        'ponente_id':          _ponenteId,
        'entidad_id':          _entidadId,
        'tiene_presencial':    _tienePresencial,
        'tiene_streaming':     _tieneStreaming,
        'url_online':          _empty(_urlOnlineCtrl),
        'venue_nombre_libre':  _empty(_venueNombreCtrl),
        'es_gratuito':         _esGratuito,
        'url_reserva':         _empty(_urlReservaCtrl),
        'portada_url':         _empty(_portadaUrlCtrl),
        'email_contacto':      _empty(_emailCtrl),
        'enlace_web':          _empty(_enlaceWebCtrl),
        'coorganizador_nombre': _empty(_coorgNombreCtrl),
        'coorganizador_web':   _empty(_coorgWebCtrl),
        'nota_moderacion':     _empty(_notaCtrl),
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

  String? _empty(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(
                      color: AppTheme.goldColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Nombre
              _tf(_nombreCtrl, 'Nombre *',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Obligatorio'
                      : null),
              const SizedBox(height: 10),

              // Descripción
              _tf(_descripcionCtrl, 'Descripción', maxLines: 3),
              const SizedBox(height: 10),

              // Fecha
              OutlinedButton.icon(
                onPressed: _pickFecha,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _fechaInicio != null
                      ? AppTheme.goldColor
                      : AppTheme.textMuted,
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
              const SizedBox(height: 10),

              // Tipo
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: _tiposEvento
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v),
                validator: (v) => v == null ? 'Selecciona un tipo' : null,
              ),
              const SizedBox(height: 10),

              // Ciudad
              _tf(_ciudadCtrl, 'Ciudad *',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Obligatorio'
                      : null),
              const SizedBox(height: 10),

              // País
              DropdownButtonFormField<String>(
                value: _pais,
                decoration: const InputDecoration(labelText: 'País *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                isExpanded: true,
                items: _paisesEvento
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _pais = v),
                validator: (v) => v == null ? 'Selecciona un país' : null,
              ),
              const SizedBox(height: 10),

              // Venue
              _tf(_venueNombreCtrl, 'Nombre del venue'),
              const SizedBox(height: 10),

              // Presencial / Streaming
              _switchRow(
                label: 'Presencial',
                value: _tienePresencial,
                onChanged: (v) => setState(() => _tienePresencial = v),
              ),
              _switchRow(
                label: 'Con streaming',
                value: _tieneStreaming,
                onChanged: (v) => setState(() => _tieneStreaming = v),
              ),
              if (_tieneStreaming) ...[
                const SizedBox(height: 6),
                _tf(_urlOnlineCtrl, 'URL streaming / acceso online'),
              ],
              const SizedBox(height: 10),

              // Gratuito / URL reserva
              _switchRow(
                label: 'Gratuito',
                value: _esGratuito,
                onChanged: (v) => setState(() => _esGratuito = v),
              ),
              if (!_esGratuito) ...[
                const SizedBox(height: 6),
                _tf(_urlReservaCtrl, 'URL de reserva / compra de entradas'),
              ],
              const SizedBox(height: 10),

              // Portada URL
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _tf(_portadaUrlCtrl, 'URL imagen de portada')),
                  const SizedBox(width: 8),
                  _subiendoPortada
                      ? const SizedBox(
                          width: 44, height: 44,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.goldColor),
                          ))
                      : OutlinedButton.icon(
                          onPressed: _subirImagenPortada,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.goldColor,
                            side: BorderSide(
                                color: AppTheme.goldColor.withAlpha(120)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 13),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.upload_outlined, size: 16),
                          label: const Text('Subir imagen',
                              style: TextStyle(fontSize: 12)),
                        ),
                ],
              ),
              const SizedBox(height: 10),

              // Entidad organizadora
              if (_entidades == null)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  value: _entidadId,
                  decoration: const InputDecoration(labelText: 'Entidad organizadora'),
                  dropdownColor: AppTheme.darkCard,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('— Sin asignar —')),
                    ..._entidades!.map((e) => DropdownMenuItem(
                          value: e['id'] as String,
                          child: Text(e['nombre'] as String? ?? ''),
                        )),
                  ],
                  onChanged: (v) => setState(() => _entidadId = v),
                ),
              const SizedBox(height: 10),

              // Ponente
              if (_ponentes == null)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  value: _ponenteId,
                  decoration:
                      const InputDecoration(labelText: 'Ponente principal'),
                  dropdownColor: AppTheme.darkCard,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('— Sin ponente —')),
                    ..._ponentes!.map((p) => DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text(
                            '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'
                                    .trim() +
                                (p['cargo'] != null
                                    ? ' · ${p['cargo']}'
                                    : ''),
                          ),
                        )),
                  ],
                  onChanged: (v) => setState(() => _ponenteId = v),
                ),
              const SizedBox(height: 10),

              // Estado
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(labelText: 'Estado'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: _estadosEvento
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _estado = v),
              ),
              const SizedBox(height: 10),

              // Contacto / web
              _tf(_emailCtrl, 'Email de contacto'),
              const SizedBox(height: 10),
              _tf(_enlaceWebCtrl, 'Web del evento'),
              const SizedBox(height: 10),

              // Coorganizador
              _tf(_coorgNombreCtrl, 'Coorganizador — nombre'),
              const SizedBox(height: 10),
              _tf(_coorgWebCtrl, 'Coorganizador — web'),
              const SizedBox(height: 10),

              // Nota moderación
              _tf(_notaCtrl, 'Nota de moderación', maxLines: 2),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
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

  Widget _tf(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label),
        validator: validator,
      );

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.goldColor,
          ),
        ],
      );
}

// ─── Modal nuevo evento ───────────────────────────────────────────────────────

class _FormNuevoEvento extends StatefulWidget {
  final VoidCallback onCreado;
  const _FormNuevoEvento({required this.onCreado});

  @override
  State<_FormNuevoEvento> createState() => _FormNuevoEventoState();
}

class _FormNuevoEventoState extends State<_FormNuevoEvento> {
  final _formKey         = GlobalKey<FormState>();
  final _nombreCtrl      = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ciudadCtrl      = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _enlaceWebCtrl   = TextEditingController();

  String? _tipo;
  String? _pais          = 'España';
  String? _estado        = 'publicado';
  String? _ponenteId;
  String? _organizadorId;
  DateTime? _fechaInicio;
  TimeOfDay? _horaInicio;
  bool _guardando = false;

  // Carga dinámica
  List<Map<String, dynamic>>? _ponentes;
  List<Map<String, dynamic>>? _organizadores;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final sb = Supabase.instance.client;
    final results = await Future.wait([
      sb
          .from('ponentes')
          .select('id, nombre, apellido, cargo')
          .order('apellido', ascending: true),
      sb
          .from('organizadores')
          .select('id, nombre, apellido, entidades(nombre)')
          .eq('estado', 'aprobado')
          .order('apellido', ascending: true),
    ]);
    if (mounted) {
      setState(() {
        _ponentes      = List<Map<String, dynamic>>.from(results[0] as List);
        _organizadores = List<Map<String, dynamic>>.from(results[1] as List);
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _ciudadCtrl.dispose();
    _emailCtrl.dispose();
    _enlaceWebCtrl.dispose();
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
        'descripcion':      _descripcionCtrl.text.trim().isEmpty
                              ? null
                              : _descripcionCtrl.text.trim(),
        'ciudad':           _ciudadCtrl.text.trim(),
        'pais':             _pais,
        'tipo':             _tipo,
        'estado':           _estado,
        'fecha_inicio':     DateFormat('yyyy-MM-dd').format(_fechaInicio!),
        'hora_inicio':      _horaInicio != null
            ? '${_horaInicio!.hour.toString().padLeft(2, '0')}:'
              '${_horaInicio!.minute.toString().padLeft(2, '0')}'
            : null,
        'ponente_id':       _ponenteId,
        'organizador_id':   _organizadorId,
        'email_contacto':   _emailCtrl.text.trim().isEmpty
                              ? null
                              : _emailCtrl.text.trim(),
        'enlace_web':       _enlaceWebCtrl.text.trim().isEmpty
                              ? null
                              : _enlaceWebCtrl.text.trim(),
        'tiene_presencial': true,
        'tiene_streaming':  false,
        'es_gratuito':      true,
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nuevo evento',
                  style: TextStyle(
                      color: AppTheme.goldColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _tf(_nombreCtrl, 'Nombre *',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Obligatorio'
                      : null),
              const SizedBox(height: 10),
              _tf(_descripcionCtrl, 'Descripción', maxLines: 3),
              const SizedBox(height: 10),
              // Fecha y hora
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFecha,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _fechaInicio != null
                          ? AppTheme.goldColor
                          : AppTheme.textMuted,
                      side: BorderSide(
                          color: _fechaInicio != null
                              ? AppTheme.goldColor.withAlpha(120)
                              : AppTheme.darkBorder),
                    ),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_fechaInicio != null
                        ? DateFormat('d MMM yyyy', 'es')
                            .format(_fechaInicio!)
                        : 'Fecha *'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickHora,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _horaInicio != null
                          ? AppTheme.goldColor
                          : AppTheme.textMuted,
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
                items: _tiposEvento
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v),
                validator: (v) => v == null ? 'Selecciona un tipo' : null,
              ),
              const SizedBox(height: 10),
              _tf(_ciudadCtrl, 'Ciudad *',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Obligatorio'
                      : null),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _pais,
                decoration: const InputDecoration(labelText: 'País *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                isExpanded: true,
                items: _paisesEvento
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _pais = v),
                validator: (v) => v == null ? 'Selecciona un país' : null,
              ),
              const SizedBox(height: 10),
              // Organizador (carga dinámica)
              if (_organizadores == null)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  value: _organizadorId,
                  decoration:
                      const InputDecoration(labelText: 'Organizador'),
                  dropdownColor: AppTheme.darkCard,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('— Sin asignar —')),
                    ..._organizadores!.map((o) {
                      final entidadNombre =
                          (o['entidades'] as Map?)?['nombre'] as String?;
                      final nombre =
                          '${o['nombre'] ?? ''} ${o['apellido'] ?? ''}'
                              .trim();
                      return DropdownMenuItem(
                        value: o['id'] as String,
                        child: Text(entidadNombre != null
                            ? '$nombre · $entidadNombre'
                            : nombre),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _organizadorId = v),
                ),
              const SizedBox(height: 10),
              // Ponente (carga dinámica)
              if (_ponentes == null)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  value: _ponenteId,
                  decoration:
                      const InputDecoration(labelText: 'Ponente principal'),
                  dropdownColor: AppTheme.darkCard,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('— Sin ponente —')),
                    ..._ponentes!.map((p) => DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text(
                            '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'
                                    .trim() +
                                (p['cargo'] != null
                                    ? ' · ${p['cargo']}'
                                    : ''),
                          ),
                        )),
                  ],
                  onChanged: (v) => setState(() => _ponenteId = v),
                ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(labelText: 'Estado'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: _estadosEvento
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _estado = v),
              ),
              const SizedBox(height: 10),
              _tf(_emailCtrl, 'Email contacto'),
              const SizedBox(height: 10),
              _tf(_enlaceWebCtrl, 'Web del evento'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.darkBg))
                    : const Text('Crear evento'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label),
        validator: validator,
      );
}
