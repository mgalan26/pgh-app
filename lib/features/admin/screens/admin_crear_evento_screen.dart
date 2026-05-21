import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Constantes ───────────────────────────────────────────────────────────────

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

// ─── Screen ───────────────────────────────────────────────────────────────────

class AdminCrearEventoScreen extends ConsumerStatefulWidget {
  const AdminCrearEventoScreen({super.key});

  @override
  ConsumerState<AdminCrearEventoScreen> createState() =>
      _AdminCrearEventoScreenState();
}

class _AdminCrearEventoScreenState
    extends ConsumerState<AdminCrearEventoScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _nombreCtrl       = TextEditingController();
  final _descripcionCtrl  = TextEditingController();
  final _ciudadCtrl       = TextEditingController();
  final _direccionCtrl    = TextEditingController();
  final _urlOnlineCtrl    = TextEditingController();
  final _urlReservaCtrl   = TextEditingController();
  final _enlaceWebCtrl    = TextEditingController();

  String?    _pais          = 'España';
  String?    _tipo;
  String?    _entidadId;
  String?    _ponenteId;
  DateTime?  _fechaInicio;
  TimeOfDay? _horaInicio;
  bool _tienePresencial = true;
  bool _tieneStreaming  = false;
  bool _esGratuito      = true;
  bool _guardando       = false;

  List<Map<String, dynamic>>? _entidades;
  List<Map<String, dynamic>>? _ponentes;

  // ── Ciclo de vida ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _ciudadCtrl.dispose();
    _direccionCtrl.dispose();
    _urlOnlineCtrl.dispose();
    _urlReservaCtrl.dispose();
    _enlaceWebCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final sb = Supabase.instance.client;
    final results = await Future.wait([
      sb.from('entidades')
          .select('id, nombre')
          .eq('activa', true)
          .order('nombre', ascending: true),
      sb.from('ponentes')
          .select('id, nombre, apellido, cargo')
          .order('apellido', ascending: true),
    ]);
    if (mounted) {
      setState(() {
        _entidades = List<Map<String, dynamic>>.from(results[0] as List);
        _ponentes  = List<Map<String, dynamic>>.from(results[1] as List);
      });
    }
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

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

  // ── Guardar ──────────────────────────────────────────────────────────────

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona una fecha de inicio'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() => _guardando = true);
    try {
      await Supabase.instance.client.from('eventos').insert({
        'nombre':           _nombreCtrl.text.trim(),
        'descripcion':      _descripcionCtrl.text.trim().isEmpty
                              ? null : _descripcionCtrl.text.trim(),
        'ciudad':           _ciudadCtrl.text.trim(),
        'pais':             _pais,
        'tipo':             _tipo,
        'estado':           'publicado',
        'fecha_inicio':     DateFormat('yyyy-MM-dd').format(_fechaInicio!),
        'hora_inicio':      _horaInicio != null
            ? '${_horaInicio!.hour.toString().padLeft(2, '0')}:'
              '${_horaInicio!.minute.toString().padLeft(2, '0')}'
            : null,
        'tiene_presencial': _tienePresencial,
        'venue_nombre_libre': _tienePresencial && _direccionCtrl.text.trim().isNotEmpty
                              ? _direccionCtrl.text.trim() : null,
        'tiene_streaming':  _tieneStreaming,
        'url_online':       _tieneStreaming && _urlOnlineCtrl.text.trim().isNotEmpty
                              ? _urlOnlineCtrl.text.trim() : null,
        'es_gratuito':      _esGratuito,
        'url_reserva':      !_esGratuito && _urlReservaCtrl.text.trim().isNotEmpty
                              ? _urlReservaCtrl.text.trim() : null,
        'enlace_web':       _enlaceWebCtrl.text.trim().isEmpty
                              ? null : _enlaceWebCtrl.text.trim(),
        'entidad_id':       _entidadId,
        'ponente_id':       _ponenteId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Evento creado ✓'),
          backgroundColor: AppTheme.goldColor,
        ));
        context.go(AppRoutes.agenda);
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go(AppRoutes.agenda),
        ),
        title: const Text(
          'Nuevo evento',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── Nombre ─────────────────────────────────────────────
                _tf(_nombreCtrl, 'Nombre del evento *',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Obligatorio' : null),
                const SizedBox(height: 12),

                // ── Descripción ────────────────────────────────────────
                _tf(_descripcionCtrl, 'Descripción', maxLines: 4),
                const SizedBox(height: 12),

                // ── País ───────────────────────────────────────────────
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
                const SizedBox(height: 12),

                // ── Ciudad ─────────────────────────────────────────────
                _tf(_ciudadCtrl, 'Ciudad *',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Obligatorio' : null),
                const SizedBox(height: 12),

                // ── Fecha y hora ───────────────────────────────────────
                _seccion('Fecha y hora'),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_fechaInicio != null
                          ? DateFormat('d MMM yyyy', 'es').format(_fechaInicio!)
                          : 'Fecha inicio *'),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(_horaInicio != null
                          ? _horaInicio!.format(context)
                          : 'Hora inicio'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                // ── Tipo ───────────────────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _tipo,
                  decoration: const InputDecoration(labelText: 'Tipo de evento *'),
                  dropdownColor: AppTheme.darkCard,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: _tiposEvento.map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _tipo = v),
                  validator: (v) => v == null ? 'Selecciona un tipo' : null,
                ),
                const SizedBox(height: 12),

                // ── Modalidad ──────────────────────────────────────────
                _seccion('Modalidad'),
                _checkRow('Presencial', _tienePresencial,
                    (v) => setState(() => _tienePresencial = v)),
                if (_tienePresencial) ...[
                  const SizedBox(height: 8),
                  _tf(_direccionCtrl, 'Dirección del evento',
                      hint: 'Calle, número, sala...'),
                ],
                _checkRow('Streaming / Online', _tieneStreaming,
                    (v) => setState(() => _tieneStreaming = v)),
                if (_tieneStreaming) ...[
                  const SizedBox(height: 8),
                  _tf(_urlOnlineCtrl, 'URL online / streaming',
                      hint: 'https://...'),
                ],
                const SizedBox(height: 12),

                // ── Precio ─────────────────────────────────────────────
                _seccion('Precio'),
                _checkRow('Entrada gratuita', _esGratuito,
                    (v) => setState(() => _esGratuito = v)),
                if (!_esGratuito) ...[
                  const SizedBox(height: 8),
                  _tf(_urlReservaCtrl, 'URL de reserva / compra de entradas',
                      hint: 'https://...'),
                ],
                const SizedBox(height: 12),

                // ── Enlace web ─────────────────────────────────────────
                _tf(_enlaceWebCtrl, 'Enlace web del evento',
                    hint: 'https://...'),
                const SizedBox(height: 12),

                // ── Entidad organizadora ───────────────────────────────
                _seccion('Entidad organizadora'),
                if (_entidades == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _entidadId,
                    decoration: const InputDecoration(
                        labelText: 'Entidad organizadora *'),
                    dropdownColor: AppTheme.darkCard,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                          value: null,
                          child: Text('— Selecciona una entidad —')),
                      ..._entidades!.map((e) => DropdownMenuItem(
                            value: e['id'] as String,
                            child: Text(e['nombre'] as String? ?? ''),
                          )),
                    ],
                    onChanged: (v) => setState(() => _entidadId = v),
                    validator: (v) =>
                        v == null ? 'Selecciona una entidad' : null,
                  ),
                const SizedBox(height: 12),

                // ── Ponente principal ──────────────────────────────────
                _seccion('Ponente principal'),
                if (_ponentes == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _ponenteId,
                    decoration: const InputDecoration(
                        labelText: 'Ponente principal'),
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
                                      ? ' · ${p['cargo']}' : ''),
                            ),
                          )),
                    ],
                    onChanged: (v) => setState(() => _ponenteId = v),
                  ),
                const SizedBox(height: 28),

                // ── Botón crear ────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.darkBg))
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    _guardando ? 'Guardando...' : 'Crear evento',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          titulo,
          style: const TextStyle(
            color: AppTheme.goldColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _tf(
    TextEditingController ctrl,
    String label, {
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

  Widget _checkRow(String label, bool value, ValueChanged<bool> onChanged) =>
      CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        title: Text(label,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 14)),
        activeColor: AppTheme.goldColor,
        checkColor: AppTheme.darkBg,
        contentPadding: EdgeInsets.zero,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
      );
}
