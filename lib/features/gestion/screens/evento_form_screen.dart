import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/env.dart';
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

  // Admin
  bool _isAdmin = false;
  String? _entidadIdSeleccionada;
  List<Map<String, dynamic>> _entidades = [];

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

  bool _guardando   = false;
  bool _analizando  = false;

  // Drag-and-drop / paste
  bool _draggingOver = false;
  int  _dragCounter  = 0;
  StreamSubscription<html.Event>?      _pasteSub;
  StreamSubscription<html.MouseEvent>? _dragEnterSub;
  StreamSubscription<html.MouseEvent>? _dragLeaveSub;
  StreamSubscription<html.MouseEvent>? _dragOverSub;
  StreamSubscription<html.MouseEvent>? _dropSub;

  @override
  void initState() {
    super.initState();
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    _isAdmin = email == 'mgalan26@gmail.com';
    if (_isAdmin) _cargarEntidades();

    // Listeners web: paste y drag-and-drop
    _pasteSub     = html.document.onPaste.listen(_onPaste);
    _dragEnterSub = html.window.onDragEnter.listen(_onDragEnter);
    _dragLeaveSub = html.window.onDragLeave.listen(_onDragLeave);
    _dragOverSub  = html.window.onDragOver.listen((e) => e.preventDefault());
    _dropSub      = html.window.onDrop.listen(_onDrop);
  }

  Future<void> _cargarEntidades() async {
    final data = await Supabase.instance.client
        .from('entidades')
        .select('id, nombre')
        .eq('activa', true)
        .order('nombre');
    setState(() {
      _entidades = List<Map<String, dynamic>>.from(data as List);
    });
  }

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _descripcionCtrl, _portadaUrlCtrl, _ciudadCtrl, _venueNombreCtrl,
      _urlOnlineCtrl, _urlReservaCtrl, _emailContactoCtrl, _enlaceWebCtrl,
      _coorgNombreCtrl, _coorgWebCtrl,
    ]) { c.dispose(); }
    _pasteSub?.cancel();
    _dragEnterSub?.cancel();
    _dragLeaveSub?.cancel();
    _dragOverSub?.cancel();
    _dropSub?.cancel();
    super.dispose();
  }

  // ── Handlers web: paste y drag-and-drop ───────────────────────────────────

  void _onPaste(html.Event rawEvent) {
    final event = rawEvent as html.ClipboardEvent;
    final items = event.clipboardData?.items;
    if (items == null) return;
    for (int i = 0; i < (items.length ?? 0); i++) {
      final item = items[i];
      if (item != null && (item.type?.startsWith('image/') ?? false)) {
        final file = item.getAsFile();
        if (file != null) {
          event.preventDefault();
          _procesarBlobWeb(file, item.type ?? 'image/jpeg');
          return;
        }
      }
    }
  }

  void _onDragEnter(html.MouseEvent event) {
    _dragCounter++;
    if (mounted && _dragCounter == 1) setState(() => _draggingOver = true);
  }

  void _onDragLeave(html.MouseEvent event) {
    if (_dragCounter > 0) _dragCounter--;
    if (mounted && _dragCounter == 0) setState(() => _draggingOver = false);
  }

  void _onDrop(html.MouseEvent event) {
    event.preventDefault();
    _dragCounter = 0;
    if (mounted) setState(() => _draggingOver = false);
    final files = event.dataTransfer?.files;
    if (files == null || files.isEmpty) return;
    final file = files[0];
    if (file.type.startsWith('image/')) {
      _procesarBlobWeb(file, file.type);
    }
  }

  Future<void> _procesarBlobWeb(html.Blob blob, String mediaType) async {
    if (_analizando) return;
    setState(() => _analizando = true);
    try {
      final reader = html.FileReader();
      reader.readAsDataUrl(blob);
      await reader.onLoad.first;
      final dataUrl = reader.result as String;
      final base64Image = dataUrl.split(',').last;
      await _llamarClaudeConBase64(base64Image, mediaType: mediaType);
    } catch (e) {
      if (mounted) _snack('Error al procesar la imagen: $e');
    } finally {
      if (mounted) setState(() => _analizando = false);
    }
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

  // ── Rellenar desde imagen ─────────────────────────────────────────────────

  Future<void> _rellenarDesdeImagen() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.goldColor),
              title: const Text('Galería',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppTheme.goldColor),
              title: const Text('Cámara',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _analizando = true);
    try {
      final bytes = await picked.readAsBytes();
      await _llamarClaudeConBase64(base64Encode(bytes));
    } catch (e) {
      if (mounted) _snack('Error al analizar la imagen: $e');
    } finally {
      if (mounted) setState(() => _analizando = false);
    }
  }

  Future<void> _llamarClaudeConBase64(
    String base64Image, {
    String mediaType = 'image/jpeg',
  }) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': Env.anthropicApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-opus-4-5',
        'max_tokens': 1024,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mediaType,
                  'data': base64Image,
                },
              },
              {
                'type': 'text',
                'text': '''Extrae los datos de este evento y devuelve SOLO un JSON válido sin markdown con estos campos:
{
  "nombre": "nombre del evento",
  "descripcion": "descripción si existe",
  "tipo": "Conferencia|Mesa redonda|Congreso|Networking|Cultural|Académico|Empresarial|Político|Exposición|Otro",
  "fecha_inicio": "YYYY-MM-DD",
  "hora_inicio": "HH:mm",
  "pais": "país",
  "ciudad": "ciudad",
  "venue_nombre": "nombre del lugar",
  "es_gratuito": true,
  "enlace_web": "url si existe",
  "ponente_nombre": "nombre completo del ponente principal si existe"
}
Si algún campo no está en la imagen ponlo como null.'''
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error de API: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (body['content'] as List).first as Map<String, dynamic>;
    final text = content['text'] as String;

    final jsonStr = text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    setState(() {
      if (data['nombre'] != null) {
        _nombreCtrl.text = data['nombre'] as String;
      }
      if (data['descripcion'] != null) {
        _descripcionCtrl.text = data['descripcion'] as String;
      }
      if (data['tipo'] != null && _tiposEvento.contains(data['tipo'])) {
        _tipo = data['tipo'] as String;
      }
      if (data['fecha_inicio'] != null) {
        try {
          _fechaInicio = DateTime.parse(data['fecha_inicio'] as String);
        } catch (_) {}
      }
      if (data['hora_inicio'] != null) {
        try {
          final parts = (data['hora_inicio'] as String).split(':');
          _horaInicio = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        } catch (_) {}
      }
      if (data['pais'] != null && _paises.contains(data['pais'])) {
        _pais = data['pais'] as String;
      }
      if (data['ciudad'] != null) {
        _ciudadCtrl.text = data['ciudad'] as String;
      }
      if (data['venue_nombre'] != null) {
        _venueNombreCtrl.text = data['venue_nombre'] as String;
      }
      if (data['es_gratuito'] != null) {
        _esGratuito = data['es_gratuito'] as bool;
      }
      if (data['enlace_web'] != null) {
        _enlaceWebCtrl.text = data['enlace_web'] as String;
      }
    });

    if (mounted) {
      _snack('Campos rellenados desde la imagen ✓', isError: false);
    }
  }

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
    if (_isAdmin && _entidadIdSeleccionada == null) {
      _snack('Selecciona una entidad');
      return;
    }

    final org = _isAdmin ? null : await ref.read(organizadorProvider.future);
    if (!_isAdmin && org == null) {
      _snack('No se encontró el perfil de organizador');
      return;
    }

    final estadoFinal = _isAdmin ? 'publicado' : estado;

    setState(() => _guardando = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final payload = {
        'organizador_id':      _isAdmin ? null : org!.id,
        'entidad_id':          _isAdmin ? _entidadIdSeleccionada : org!.entidadId,
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
        'estado':              estadoFinal,
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
          estadoFinal == 'publicado'
            ? 'Evento publicado ✓'
            : estadoFinal == 'pendiente'
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

            // ── Botón rellenar desde imagen ─────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _analizando ? null : _rellenarDesdeImagen,
                icon: _analizando
                    ? const SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.goldColor))
                    : const Icon(Icons.camera_alt_outlined,
                        color: AppTheme.goldColor, size: 18),
                label: Text(
                  _analizando ? 'Analizando imagen…' : 'Rellenar desde imagen',
                  style: const TextStyle(color: AppTheme.goldColor),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.goldColor,
                  side: const BorderSide(color: AppTheme.goldColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Zona drag-and-drop / Ctrl+V ─────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: _draggingOver
                    ? AppTheme.goldColor.withAlpha(18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _draggingOver
                      ? AppTheme.goldColor
                      : AppTheme.darkBorder,
                  width: _draggingOver ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _draggingOver
                        ? Icons.file_download_outlined
                        : Icons.upload_file_outlined,
                    color: _draggingOver
                        ? AppTheme.goldColor
                        : AppTheme.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _draggingOver
                        ? 'Suelta la imagen aquí'
                        : 'Arrastra una imagen aquí  ·  Ctrl+V para pegar',
                    style: TextStyle(
                      color: _draggingOver
                          ? AppTheme.goldColor
                          : AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            if (_isAdmin)
              _seccion('Entidad organizadora', [
                _entidades.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(
                              color: AppTheme.goldColor, strokeWidth: 2),
                        ))
                    : DropdownButtonFormField<String>(
                        value: _entidadIdSeleccionada,
                        decoration: const InputDecoration(
                            labelText: 'Entidad *'),
                        dropdownColor: AppTheme.darkCard,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        isExpanded: true,
                        items: _entidades.map((e) => DropdownMenuItem(
                          value: e['id'] as String,
                          child: Text(e['nombre'] as String),
                        )).toList(),
                        onChanged: (v) =>
                            setState(() => _entidadIdSeleccionada = v),
                        validator: (v) =>
                            v == null ? 'Selecciona una entidad' : null,
                      ),
              ]),

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

            // Botón principal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando ? null : () => _guardar('pendiente'),
                child: _guardando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.darkBg))
                    : Text(_isAdmin ? 'Publicar evento' : 'Enviar para revisión'),
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
