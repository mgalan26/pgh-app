import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pgh_app/core/providers/auth_provider.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _eventosAutorizadoProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, entidadId) async {
  final data = await Supabase.instance.client
      .from('eventos')
      .select('id, nombre, fecha_inicio, tipo, estado, ciudad, pais')
      .eq('entidad_id', entidadId)
      .order('fecha_inicio', ascending: false);
  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class AutorizadoScreen extends ConsumerWidget {
  const AutorizadoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autorizadosAsync = ref.watch(usuarioAutorizadoProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        title: const Text('Mi Panel',
            style: TextStyle(color: AppTheme.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.solicitarAutorizacion),
            icon: const Icon(Icons.add_business_outlined, size: 16),
            label: const Text('Solicitar acceso', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: AppTheme.goldColor),
          ),
        ],
      ),
      body: autorizadosAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.goldColor)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (autorizados) {
          if (autorizados.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business_outlined,
                        color: AppTheme.textMuted, size: 48),
                    const SizedBox(height: 16),
                    const Text('No tienes entidades autorizadas',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text(
                      'Solicita acceso a una entidad para gestionar sus eventos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.solicitarAutorizacion),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Solicitar acceso'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: autorizados.length,
            itemBuilder: (ctx, i) {
              final aut      = autorizados[i];
              final entidad  = aut.entidad;
              final entidadId = aut.entidadId;
              final nombre   = entidad?.nombre ?? entidadId;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera de entidad
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10)),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business_outlined,
                            color: AppTheme.goldColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(nombre,
                              style: const TextStyle(
                                  color: AppTheme.goldColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ),
                        TextButton.icon(
                          onPressed: () => _crearEvento(context, entidadId),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Nuevo',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                              foregroundColor: AppTheme.goldColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ),
                      ],
                    ),
                  ),

                  // Eventos de la entidad
                  _EventosEntidad(entidadId: entidadId),

                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _crearEvento(BuildContext context, String entidadId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EventoForm(entidadId: entidadId),
    );
  }
}

// ─── Lista de eventos de una entidad ──────────────────────────────────────────

class _EventosEntidad extends ConsumerWidget {
  final String entidadId;
  const _EventosEntidad({required this.entidadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventosAsync = ref.watch(_eventosAutorizadoProvider(entidadId));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          left: BorderSide(color: AppTheme.darkBorder),
          right: BorderSide(color: AppTheme.darkBorder),
          bottom: BorderSide(
              color: AppTheme.darkBorder,
              width: 0.5),
        ),
      ),
      child: eventosAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
              child: SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.goldColor))),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Error: $e',
              style: const TextStyle(
                  color: Colors.redAccent, fontSize: 12)),
        ),
        data: (eventos) {
          if (eventos.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay eventos para esta entidad',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 12)),
            );
          }
          return Column(
            children: eventos.map((e) => _EventoTile(
              evento: e,
              onEditar: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.darkCard,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16))),
                  builder: (_) => _EventoForm(
                    entidadId: entidadId,
                    eventoId: e['id'] as String,
                    eventoData: e,
                  ),
                ).then((_) => ref.invalidate(
                    _eventosAutorizadoProvider(entidadId)));
              },
            )).toList(),
          );
        },
      ),
    );
  }
}

// ─── Tile de evento ───────────────────────────────────────────────────────────

class _EventoTile extends StatelessWidget {
  final Map<String, dynamic> evento;
  final VoidCallback onEditar;
  const _EventoTile({required this.evento, required this.onEditar});

  @override
  Widget build(BuildContext context) {
    final nombre = evento['nombre'] as String? ?? '';
    final fecha  = evento['fecha_inicio'] as String?;
    final estado = evento['estado'] as String? ?? '';
    final ciudad = evento['ciudad'] as String? ?? '';

    String fechaStr = '';
    if (fecha != null) {
      try {
        fechaStr = DateFormat('dd MMM yyyy', 'es').format(DateTime.parse(fecha));
      } catch (_) {}
    }

    final Color estadoColor;
    switch (estado) {
      case 'publicado':  estadoColor = Colors.green; break;
      case 'pendiente':  estadoColor = Colors.orange; break;
      case 'rechazado':  estadoColor = Colors.redAccent; break;
      case 'borrador':   estadoColor = AppTheme.textMuted; break;
      default:           estadoColor = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  if (fechaStr.isNotEmpty) ...[
                    Text(fechaStr,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                    const Text(' · ',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                  ],
                  if (ciudad.isNotEmpty)
                    Text(ciudad,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: estadoColor.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: estadoColor.withAlpha(80)),
            ),
            child: Text(estado,
                style: TextStyle(
                    color: estadoColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.goldColor, size: 18),
            onPressed: onEditar,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ─── Formulario crear / editar evento ─────────────────────────────────────────

class _EventoForm extends ConsumerStatefulWidget {
  final String entidadId;
  final String? eventoId;
  final Map<String, dynamic>? eventoData;

  const _EventoForm({
    required this.entidadId,
    this.eventoId,
    this.eventoData,
  });

  @override
  ConsumerState<_EventoForm> createState() => _EventoFormState();
}

class _EventoFormState extends ConsumerState<_EventoForm> {
  final _formKey         = GlobalKey<FormState>();
  final _nombreCtrl      = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ciudadCtrl      = TextEditingController();
  final _venueCtrl       = TextEditingController();
  final _urlOnlineCtrl   = TextEditingController();
  final _urlReservaCtrl  = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _webCtrl         = TextEditingController();

  String  _pais          = 'España';
  String  _tipo          = 'Conferencia';
  bool    _presencial    = true;
  bool    _streaming     = false;
  bool    _gratuito      = true;
  DateTime _fechaInicio  = DateTime.now().add(const Duration(days: 7));
  bool    _guardando     = false;

  static const _tipos = [
    'Conferencia', 'Mesa redonda', 'Congreso', 'Networking',
    'Cultural', 'Académico', 'Empresarial', 'Político', 'Exposición', 'Otro',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.eventoData;
    if (d != null) {
      _nombreCtrl.text       = d['nombre'] as String? ?? '';
      _descripcionCtrl.text  = d['descripcion'] as String? ?? '';
      _ciudadCtrl.text       = d['ciudad'] as String? ?? '';
      _venueCtrl.text        = d['venue_nombre_libre'] as String? ?? '';
      _urlOnlineCtrl.text    = d['url_online'] as String? ?? '';
      _urlReservaCtrl.text   = d['url_reserva'] as String? ?? '';
      _emailCtrl.text        = d['email_contacto'] as String? ?? '';
      _webCtrl.text          = d['enlace_web'] as String? ?? '';
      _pais      = d['pais'] as String? ?? 'España';
      _tipo      = d['tipo'] as String? ?? 'Conferencia';
      _presencial= d['tiene_presencial'] as bool? ?? true;
      _streaming = d['tiene_streaming'] as bool? ?? false;
      _gratuito  = d['es_gratuito'] as bool? ?? true;
      final fi = d['fecha_inicio'] as String?;
      if (fi != null) _fechaInicio = DateTime.parse(fi);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _descripcionCtrl, _ciudadCtrl, _venueCtrl,
      _urlOnlineCtrl, _urlReservaCtrl, _emailCtrl, _webCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.goldColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaInicio = picked);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final sb = Supabase.instance.client;

      final payload = {
        'nombre':            _nombreCtrl.text.trim(),
        'descripcion':       _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        'entidad_id':        widget.entidadId,
        'pais':              _pais,
        'ciudad':            _ciudadCtrl.text.trim(),
        'tipo':              _tipo,
        'tiene_presencial':  _presencial,
        'tiene_streaming':   _streaming,
        'es_gratuito':       _gratuito,
        'fecha_inicio':      _fechaInicio.toIso8601String().split('T')[0],
        'venue_nombre_libre': _venueCtrl.text.trim().isEmpty ? null : _venueCtrl.text.trim(),
        'url_online':        _urlOnlineCtrl.text.trim().isEmpty ? null : _urlOnlineCtrl.text.trim(),
        'url_reserva':       _urlReservaCtrl.text.trim().isEmpty ? null : _urlReservaCtrl.text.trim(),
        'email_contacto':    _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'enlace_web':        _webCtrl.text.trim().isEmpty ? null : _webCtrl.text.trim(),
        'estado':            'pendiente',
      };

      if (widget.eventoId == null) {
        await sb.from('eventos').insert(payload);
      } else {
        // Al editar, si estaba publicado vuelve a pendiente (ya está en payload)
        await sb.from('eventos').update(payload).eq('id', widget.eventoId!);
      }

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
    final isEdit   = widget.eventoId != null;
    final fechaStr = DateFormat('dd/MM/yyyy', 'es').format(_fechaInicio);

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
              Text(
                isEdit ? 'Editar evento' : 'Nuevo evento',
                style: const TextStyle(
                    color: AppTheme.goldColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (isEdit)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: Colors.orange.withAlpha(80)),
                  ),
                  child: const Text(
                    'Al guardar, el evento pasará a estado "pendiente" para revisión.',
                    style: TextStyle(
                        color: Colors.orange, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 14),
              _tf(_nombreCtrl, 'Nombre del evento *',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obligatorio' : null),
              const SizedBox(height: 10),
              _tf(_descripcionCtrl, 'Descripción', maxLines: 3),
              const SizedBox(height: 10),
              // Fecha
              GestureDetector(
                onTap: _seleccionarFecha,
                child: AbsorbPointer(
                  child: TextFormField(
                    initialValue: fechaStr,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Fecha de inicio *',
                      suffixIcon: Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppTheme.textMuted),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _tf(_ciudadCtrl, 'Ciudad *',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obligatorio' : null)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    dropdownColor: AppTheme.darkCard,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    isExpanded: true,
                    items: _tipos.map((t) =>
                        DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _tipo = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _tf(_venueCtrl, 'Nombre del venue'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: SwitchListTile(
                    value: _presencial,
                    onChanged: (v) => setState(() => _presencial = v),
                    title: const Text('Presencial',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.goldColor,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    value: _streaming,
                    onChanged: (v) => setState(() => _streaming = v),
                    title: const Text('Streaming',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.goldColor,
                    dense: true,
                  ),
                ),
              ]),
              if (_streaming) ...[
                const SizedBox(height: 8),
                _tf(_urlOnlineCtrl, 'URL streaming',
                    hint: 'https://...'),
              ],
              const SizedBox(height: 10),
              SwitchListTile(
                value: _gratuito,
                onChanged: (v) => setState(() => _gratuito = v),
                title: const Text('Gratuito',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.goldColor,
                dense: true,
              ),
              if (!_gratuito) ...[
                const SizedBox(height: 8),
                _tf(_urlReservaCtrl, 'URL de reserva / tickets',
                    hint: 'https://...'),
              ],
              const SizedBox(height: 10),
              _tf(_emailCtrl, 'Email de contacto',
                  hint: 'contacto@entidad.com'),
              const SizedBox(height: 10),
              _tf(_webCtrl, 'Web del evento', hint: 'https://...'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.darkBg))
                    : Text(isEdit ? 'Guardar (→ pendiente)' : 'Crear evento'),
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
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator,
      );
}
