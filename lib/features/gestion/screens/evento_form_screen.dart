import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pgh_app/core/providers/auth_provider.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Tipos de evento (labels que coinciden con la BD) ────────────────────────

const _tiposEvento = [
  'Conferencia',
  'Mesa redonda',
  'Congreso',
  'Networking',
  'Cultural',
  'Académico',
  'Empresarial',
  'Político',
  'Exposición',
  'Otro',
];

const _paises = [
  'Argentina', 'Bolivia', 'Chile', 'Colombia', 'Costa Rica', 'Cuba',
  'Ecuador', 'El Salvador', 'España', 'Guatemala', 'Honduras', 'México',
  'Nicaragua', 'Panamá', 'Paraguay', 'Perú', 'Puerto Rico',
  'República Dominicana', 'Uruguay', 'Venezuela',
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class EventoFormScreen extends ConsumerStatefulWidget {
  final String? eventoId;
  const EventoFormScreen({super.key, this.eventoId});

  @override
  ConsumerState<EventoFormScreen> createState() => _EventoFormScreenState();
}

class _EventoFormScreenState extends ConsumerState<EventoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Información básica
  final _nombreCtrl      = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _portadaUrlCtrl  = TextEditingController();
  String? _tipo;

  // Fecha y hora
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;

  // Lugar
  String? _pais = 'España';
  final _ciudadCtrl          = TextEditingController();
  final _venueNombreCtrl     = TextEditingController();
  bool _tienePresencial      = true;
  bool _tieneStreaming        = false;
  final _urlOnlineCtrl       = TextEditingController();

  // Acceso
  bool _esGratuito           = true;
  final _urlReservaCtrl      = TextEditingController();

  // Contacto
  final _emailContactoCtrl   = TextEditingController();
  final _enlaceWebCtrl       = TextEditingController();

  // Coorganizador
  final _coorgNombreCtrl     = TextEditingController();
  final _coorgWebCtrl        = TextEditingController();

  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _descripcionCtrl, _portadaUrlCtrl, _ciudadCtrl, _venueNombreCtrl,
      _urlOnlineCtrl, _urlReservaCtrl, _emailContactoCtrl, _enlaceWebCtrl,
      _coorgNombreCtrl, _coorgWebCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Helpers de fecha/hora ─────────────────────────────────────────────────

  Future<void> _pickFecha({required bool esInicio}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (esInicio ? _fechaInicio : _fechaFin) ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('es'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppTheme.goldColor,
            onPrimary: AppTheme.darkBg,
            surface: AppTheme.darkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = picked;
        if (_fechaFin != null && _fechaFin!.isBefore(picked)) {
          _fechaFin = null;
        }
      } else {
        _fechaFin = picked;
      }
    });
  }

  Future<void> _pickHora({required bool esInicio}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (esInicio ? _horaInicio : _horaFin) ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppTheme.goldColor,
            onPrimary: AppTheme.darkBg,
            surface: AppTheme.darkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => esInicio ? _horaInicio = picked : _horaFin = picked);
  }

  String _formatFecha(DateTime d) =>
      DateFormat('dd/MM/yyyy').format(d);

  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Guardar ───────────────────────────────────────────────────────────────

  Future<void> _guardar(String estado) async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null) {
      _snack('Selecciona la fecha de inicio');
      return;
    }
    if (!_tienePresencial && !_tieneStreaming) {
      _snack('Selecciona al menos una modalidad');
      return;
    }

    final org = await ref.read(organizadorProvider.future);
    if (org == null) {
      _snack('No se encontró el perfil de organizador');
      return;
    }

    setState(() => _guardando = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final payload = {
        'organizador_id':      org.id,
        'entidad_id':          org.entidadId,
        'nombre':              _nombreCtrl.text.trim(),
        'tipo':                _tipo,
        'descripcion':         _descripcionCtrl.text.trim().isEmpty
                                 ? null
                                 : _descripcionCtrl.text.trim(),
        'fecha_inicio':        DateFormat('yyyy-MM-dd').format(_fechaInicio!),
        'fecha_fin':           _fechaFin != null
                                 ? DateFormat('yyyy-MM-dd').format(_fechaFin!)
                                 : null,
        'hora_inicio':         _horaInicio != null
                                 ? _formatHora(_horaInicio!)
                                 : null,
        'hora_fin':            _horaFin != null
                                 ? _formatHora(_horaFin!)
                                 : null,
        'pais':                _pais,
        'ciudad':              _ciudadCtrl.text.trim(),
        'tiene_presencial':    _tienePresencial,
        'tiene_streaming':     _tieneStreaming,
        'url_online':          _tieneStreaming &&
                                 _urlOnlineCtrl.text.trim().isNotEmpty
                                 ? _urlOnlineCtrl.text.trim()
                                 : null,
        'venue_nombre_libre':  _venueNombreCtrl.text.trim().isEmpty
                                 ? null
                                 : _venueNombreCtrl.text.trim(),
        'es_gratuito':         _esGratuito,
        'url_reserva':         !_esGratuito &&
                                 _urlReservaCtrl.text.trim().isNotEmpty
                                 ? _urlReservaCtrl.text.trim()
                                 : null,
        'email_contacto':      _emailContactoCtrl.text.trim().isEmpty
                                 ? null
                                 : _emailContactoCtrl.text.trim(),
        'enlace_web':          _enlaceWebCtrl.text.trim().isEmpty
                                 ? null
                                 : _enlaceWebCtrl.text.trim(),
        'coorganizador_nombre': _coorgNombreCtrl.text.trim().isEmpty
                                 ? null
                                 : _coorgNombreCtrl.text.trim(),
        'coorganizador_web':   _coorgWebCtrl.text.trim().isEmpty
                                 ? null
                                 : _coorgWebCtrl.text.trim(),
        'portada_url':         _portadaUrlCtrl.text.trim().isEmpty
                                 ? null
                                 : _portadaUrlCtrl.text.trim(),
        'estado':              estado,
        'visitas':             0,
      };

      if (widget.eventoId == null) {
        await supabase.from('eventos').insert(payload);
      } else {
        payload.remove('organizador_id');
        payload.remove('entidad_id');
        payload.remove('visitas');
        await supabase.from('eventos').update(payload).eq('id', widget.eventoId!);
      }

      if (mounted) {
        _snack(
          estado == 'pendiente'
            ? 'Evento enviado para revisión ✓'
            : 'Borrador guardado ✓',
          isError: false,
        );
        context.pop();
      }
    } catch (e) {
      _snack('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _snack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : AppTheme.goldColor,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.eventoId != null;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar evento' : 'Nuevo evento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _seccion('Información básica', [
              _campo(
                controller: _nombreCtrl,
                label: 'Nombre del evento *',
                hint: 'Ej: Conferencia sobre historia hispana',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 12),
              _dropdownTipo(),
              const SizedBox(height: 12),
              _campo(
                controller: _descripcionCtrl,
                label: 'Descripción',
                hint: 'Describe brevemente el evento…',
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _campo(
                controller: _portadaUrlCtrl,
                label: 'URL imagen de portada',
                hint: 'https://...',
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
              ),
              if (_portadaUrlCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _portadaUrlCtrl.text.trim(),
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
            ]),

            _seccion('Fecha y horario', [
              Row(children: [
                Expanded(child: _fechaButton(
                  label: 'Fecha inicio *',
                  value: _fechaInicio != null ? _formatFecha(_fechaInicio!) : null,
                  onTap: () => _pickFecha(esInicio: true),
                )),
                const SizedBox(width: 10),
                Expanded(child: _fechaButton(
                  label: 'Fecha fin',
                  value: _fechaFin != null ? _formatFecha(_fechaFin!) : null,
                  onTap: _fechaInicio == null
                      ? null
                      : () => _pickFecha(esInicio: false),
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _fechaButton(
                  label: 'Hora inicio',
                  value: _horaInicio != null ? _formatHora(_horaInicio!) : null,
                  icon: Icons.access_time,
                  onTap: () => _pickHora(esInicio: true),
                )),
                const SizedBox(width: 10),
                Expanded(child: _fechaButton(
                  label: 'Hora fin',
                  value: _horaFin != null ? _formatHora(_horaFin!) : null,
                  icon: Icons.access_time,
                  onTap: () => _pickHora(esInicio: false),
                )),
              ]),
            ]),

            _seccion('Lugar', [
              _dropdownPais(),
              const SizedBox(height: 12),
              _campo(
                controller: _ciudadCtrl,
                label: 'Ciudad *',
                hint: 'Ej: Madrid',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'La ciudad es obligatoria'
                    : null,
              ),
              const SizedBox(height: 16),
              _labelTexto('Modalidad *'),
              const SizedBox(height: 8),
              _switchRow(
                label: 'Presencial',
                value: _tienePresencial,
                onChanged: (v) => setState(() => _tienePresencial = v),
              ),
              _switchRow(
                label: 'Online / Streaming',
                value: _tieneStreaming,
                onChanged: (v) => setState(() => _tieneStreaming = v),
              ),
              if (_tienePresencial) ...[
                const SizedBox(height: 12),
                _campo(
                  controller: _venueNombreCtrl,
                  label: 'Nombre del lugar',
                  hint: 'Ej: Teatro Real, Sala A…',
                ),
              ],
              if (_tieneStreaming) ...[
                const SizedBox(height: 12),
                _campo(
                  controller: _urlOnlineCtrl,
                  label: 'URL de la retransmisión',
                  hint: 'https://…',
                  keyboardType: TextInputType.url,
                ),
              ],
            ]),

            _seccion('Acceso', [
              _switchRow(
                label: 'Entrada gratuita',
                value: _esGratuito,
                onChanged: (v) => setState(() => _esGratuito = v),
              ),
              if (!_esGratuito) ...[
                const SizedBox(height: 12),
                _campo(
                  controller: _urlReservaCtrl,
                  label: 'URL de reserva / compra',
                  hint: 'https://…',
                  keyboardType: TextInputType.url,
                ),
              ],
            ]),

            _seccion('Contacto', [
              _campo(
                controller: _emailContactoCtrl,
                label: 'Email de contacto',
                hint: 'info@ejemplo.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _campo(
                controller: _enlaceWebCtrl,
                label: 'Página web del evento',
                hint: 'https://…',
                keyboardType: TextInputType.url,
              ),
            ]),

            _seccion('Coorganizador (opcional)', [
              _campo(
                controller: _coorgNombreCtrl,
                label: 'Nombre de la organización coorganizadora',
                hint: 'Ej: Fundación XYZ',
              ),
              const SizedBox(height: 12),
              _campo(
                controller: _coorgWebCtrl,
                label: 'Web del coorganizador',
                hint: 'https://…',
                keyboardType: TextInputType.url,
              ),
            ]),

            const SizedBox(height: 24),

            // Botón principal: enviar para revisión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando ? null : () => _guardar('pendiente'),
                child: _guardando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.darkBg))
                    : const Text('Enviar para revisión'),
              ),
            ),

            const SizedBox(height: 10),

            // Botón secundario: guardar como borrador
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _guardando ? null : () => _guardar('borrador'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.darkBorder),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Guardar como borrador'),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Widgets auxiliares ────────────────────────────────────────────────────

  Widget _seccion(String titulo, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 28),
      Text(titulo, style: const TextStyle(
        color: AppTheme.goldColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      )),
      const SizedBox(height: 4),
      const Divider(color: AppTheme.darkBorder, height: 1),
      const SizedBox(height: 14),
      ...children,
    ],
  );

  Widget _campo({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style: const TextStyle(color: AppTheme.textPrimary),
    decoration: InputDecoration(labelText: label, hintText: hint),
    validator: validator,
    onChanged: onChanged,
  );

  Widget _dropdownTipo() => DropdownButtonFormField<String>(
    initialValue: _tipo,
    decoration: const InputDecoration(labelText: 'Tipo de evento *'),
    dropdownColor: AppTheme.darkCard,
    style: const TextStyle(color: AppTheme.textPrimary),
    items: _tiposEvento.map((t) => DropdownMenuItem(
      value: t,
      child: Text(t),
    )).toList(),
    onChanged: (v) => setState(() => _tipo = v),
    validator: (v) => v == null ? 'Selecciona un tipo' : null,
  );

  Widget _dropdownPais() => DropdownButtonFormField<String>(
    initialValue: _pais,
    decoration: const InputDecoration(labelText: 'País *'),
    dropdownColor: AppTheme.darkCard,
    style: const TextStyle(color: AppTheme.textPrimary),
    isExpanded: true,
    items: _paises.map((p) => DropdownMenuItem(
      value: p,
      child: Text(p),
    )).toList(),
    onChanged: (v) => setState(() => _pais = v),
    validator: (v) => v == null ? 'Selecciona un país' : null,
  );

  Widget _fechaButton({
    required String label,
    required String? value,
    IconData icon = Icons.calendar_today,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(children: [
        Icon(icon, size: 16,
          color: onTap == null ? AppTheme.textMuted : AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              value ?? '—',
              style: TextStyle(
                color: value != null ? AppTheme.textPrimary : AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        )),
      ]),
    ),
  );

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Row(
    children: [
      Expanded(child: Text(label,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15))),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.goldColor,
      ),
    ],
  );

  Widget _labelTexto(String text) => Text(text, style: const TextStyle(
    color: AppTheme.textSecondary, fontSize: 12));
}
