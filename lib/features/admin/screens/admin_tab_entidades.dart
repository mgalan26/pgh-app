import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/env.dart';
import 'package:pgh_app/core/theme.dart';
import 'package:pgh_app/core/widgets/logo_upload_button.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final tabEntidadesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('entidades')
      .select('*, logo_url, organizadores(id, nombre, apellido, email, estado, rol)')
      .order('nombre', ascending: true);
  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Constantes ───────────────────────────────────────────────────────────────

const _tiposEntidad = [
  'Asociación', 'Fundación', 'Empresa', 'Institución pública',
  'Universidad', 'Museo', 'Medio de comunicación', 'Otro',
];

const _paisesEntidad = [
  'Argentina', 'Bolivia', 'Chile', 'Colombia', 'Costa Rica', 'Cuba',
  'Ecuador', 'El Salvador', 'España', 'Guatemala', 'Honduras', 'México',
  'Nicaragua', 'Panamá', 'Paraguay', 'Perú', 'Puerto Rico',
  'República Dominicana', 'Uruguay', 'Venezuela',
];

// ─── Tab ──────────────────────────────────────────────────────────────────────

class AdminTabEntidades extends ConsumerWidget {
  const AdminTabEntidades({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tabEntidadesProvider);

    return Stack(
      children: [
        async.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.goldColor)),
          error: (e, _) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: Colors.redAccent))),
          data: (entidades) {
            if (entidades.isEmpty) {
              return const Center(
                child: Text('No hay entidades registradas',
                    style: TextStyle(color: AppTheme.textMuted)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: entidades.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EntidadCard(
                entidad: entidades[i],
                onRefresh: () => ref.invalidate(tabEntidadesProvider),
                ref: ref,
              ),
            );
          },
        ),
      ],
    );
  }

  static Future<void> abrirAltaOrganizador(
      BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FormAltaOrganizador(
          onCreado: () => ref.invalidate(tabEntidadesProvider)),
    );
  }
}

// ─── Tarjeta entidad expandible ───────────────────────────────────────────────

class _EntidadCard extends StatefulWidget {
  final Map<String, dynamic> entidad;
  final VoidCallback onRefresh;
  final WidgetRef ref;
  const _EntidadCard(
      {required this.entidad, required this.onRefresh, required this.ref});

  @override
  State<_EntidadCard> createState() => _EntidadCardState();
}

class _EntidadCardState extends State<_EntidadCard> {
  bool _expandida = false;

  @override
  Widget build(BuildContext context) {
    final nombre     = widget.entidad['nombre'] as String? ?? '(sin nombre)';
    final tipo       = widget.entidad['tipo']   as String? ?? '';
    final pais       = widget.entidad['pais']   as String? ?? '';
    final verificada = widget.entidad['verificada'] as bool? ?? false;
    final orgs       = (widget.entidad['organizadores'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [];

    final pendientes = orgs.where((o) => o['estado'] == 'pendiente').length;

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandida = !_expandida),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(nombre,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600))),
                    if (verificada)
                      const Icon(Icons.verified,
                          color: AppTheme.goldColor, size: 16),
                    const SizedBox(width: 4),
                    if (pendientes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.goldColor.withAlpha(80)),
                        ),
                        child: Text('$pendientes pendiente${pendientes > 1 ? "s" : ""}',
                            style: const TextStyle(
                                color: AppTheme.goldColor, fontSize: 10)),
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
                    [tipo, pais].where((s) => s.isNotEmpty).join(' · '),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _accion('Editar', Icons.edit_outlined, AppTheme.goldColor,
                        () => _abrirEdicion(context)),
                    _accion('Eliminar', Icons.delete_outline, Colors.redAccent,
                        () => _confirmarEliminar()),
                  ]),
                ],
              ),
            ),
          ),

          // Organizadores expandidos
          if (_expandida) ...[
            const Divider(color: AppTheme.darkBorder, height: 1),
            if (orgs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Sin organizadores',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
              )
            else
              ...orgs.map((org) => _OrgTile(
                  org: org,
                  onRefresh: widget.onRefresh)),
            // Añadir organizador a entidad existente
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: OutlinedButton.icon(
                onPressed: () => _abrirAltaOrgEnEntidad(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.darkBorder),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.person_add_outlined, size: 14),
                label: const Text('Añadir organizador',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _accion(String label, IconData icon, Color color, VoidCallback onTap) =>
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

  Future<void> _abrirEdicion(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EntidadEditSheet(entidad: widget.entidad),
    );
    widget.onRefresh();
  }

  Future<void> _confirmarEliminar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Eliminar entidad',
            style: TextStyle(color: Color(0xFFF0E8D8))),
        content: const Text('¿Seguro que quieres eliminar esta entidad?',
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
          .from('entidades')
          .delete()
          .eq('id', widget.entidad['id'] as String);
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

  Future<void> _abrirAltaOrgEnEntidad(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FormAltaOrganizadorEnEntidad(
        entidadId: widget.entidad['id'] as String,
        entidadNombre: widget.entidad['nombre'] as String? ?? '',
        onCreado: widget.onRefresh,
      ),
    );
  }
}

// ─── Tile de organizador ──────────────────────────────────────────────────────

class _OrgTile extends StatefulWidget {
  final Map<String, dynamic> org;
  final VoidCallback onRefresh;
  const _OrgTile({required this.org, required this.onRefresh});

  @override
  State<_OrgTile> createState() => _OrgTileState();
}

class _OrgTileState extends State<_OrgTile> {
  bool _cargando = false;

  Color _colorEstado(String s) => switch (s) {
        'aprobado'    => Colors.greenAccent,
        'pendiente'   => AppTheme.goldColor,
        'rechazado'   => Colors.redAccent,
        'suspendido'  => Colors.orange,
        _             => AppTheme.textMuted,
      };

  Future<void> _cambiarEstado(String nuevoEstado) async {
    setState(() => _cargando = true);
    try {
      await Supabase.instance.client
          .from('organizadores')
          .update({'estado': nuevoEstado})
          .eq('id', widget.org['id'] as String);
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = widget.org['estado'] as String? ?? 'pendiente';
    final nombre = '${widget.org['nombre'] ?? ''} ${widget.org['apellido'] ?? ''}'.trim();
    final email  = widget.org['email'] as String? ?? '';
    final color  = _colorEstado(estado);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text(email,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(70)),
              ),
              child: Text(estado,
                  style: TextStyle(color: color, fontSize: 10)),
            ),
          ]),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(),
            )
          else ...[
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (estado != 'aprobado')
                _btn('Aprobar', Colors.greenAccent,
                    () => _cambiarEstado('aprobado')),
              if (estado == 'aprobado')
                _btn('Suspender', Colors.orange,
                    () => _cambiarEstado('suspendido')),
              if (estado != 'rechazado')
                _btn('Rechazar', Colors.redAccent,
                    () => _cambiarEstado('rechazado')),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) =>
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withAlpha(100)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      );
}

// ─── Modal editar entidad ─────────────────────────────────────────────────────

class _EntidadEditSheet extends StatefulWidget {
  final Map<String, dynamic> entidad;
  const _EntidadEditSheet({required this.entidad});

  @override
  State<_EntidadEditSheet> createState() => _EntidadEditSheetState();
}

class _EntidadEditSheetState extends State<_EntidadEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl      = TextEditingController(text: widget.entidad['nombre'] as String?);
  late final _descripcionCtrl = TextEditingController(text: widget.entidad['descripcion'] as String?);
  late final _ciudadCtrl      = TextEditingController(text: widget.entidad['ciudad'] as String?);
  late final _webCtrl         = TextEditingController(text: widget.entidad['web'] as String?);
  late final _emailCtrl       = TextEditingController(text: widget.entidad['email_publico'] as String?);
  late String? _tipo     = widget.entidad['tipo'] as String?;
  late String? _pais     = widget.entidad['pais'] as String?;
  late bool _verificada  = widget.entidad['verificada'] as bool? ?? false;
  late bool _activa      = widget.entidad['activa'] as bool? ?? true;
  late String? _logoUrl  = widget.entidad['logo_url'] as String?;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _descripcionCtrl, _ciudadCtrl, _webCtrl, _emailCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await Supabase.instance.client.from('entidades').update({
        'nombre':       _nombreCtrl.text.trim(),
        'descripcion':  _empty(_descripcionCtrl),
        'tipo':         _tipo,
        'pais':         _pais,
        'ciudad':       _empty(_ciudadCtrl),
        'web':          _empty(_webCtrl),
        'email_publico': _empty(_emailCtrl),
        'logo_url':     _logoUrl,
        'verificada':   _verificada,
        'activa':       _activa,
      }).eq('id', widget.entidad['id'] as String);
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
              const Text('Editar entidad',
                style: TextStyle(color: AppTheme.goldColor, fontSize: 16,
                    fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(children: [
                LogoUploadButton(
                  currentUrl: _logoUrl,
                  storagePath: 'entidades/${widget.entidad['id']}',
                  size: 80,
                  onUploaded: (url) => setState(() => _logoUrl = url),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('Logotipo de la entidad.\nPulsa para subir imagen.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5)),
                ),
              ]),
              const SizedBox(height: 16),
              _tf(_nombreCtrl, 'Nombre *',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Obligatorio' : null),
              const SizedBox(height: 10),
              _tf(_descripcionCtrl, 'Descripción', maxLines: 3),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: _tiposEntidad.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _tipo = v),
                validator: (v) => v == null ? 'Selecciona un tipo' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _pais,
                decoration: const InputDecoration(labelText: 'País *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                isExpanded: true,
                items: _paisesEntidad.map((p) =>
                    DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _pais = v),
                validator: (v) => v == null ? 'Selecciona un país' : null,
              ),
              const SizedBox(height: 10),
              _tf(_ciudadCtrl, 'Ciudad'),
              const SizedBox(height: 10),
              _tf(_webCtrl, 'Web', hint: 'https://...'),
              const SizedBox(height: 10),
              _tf(_emailCtrl, 'Email público'),
              const SizedBox(height: 10),
              _switchRow('Verificada', _verificada,
                  (v) => setState(() => _verificada = v)),
              _switchRow('Activa', _activa,
                  (v) => setState(() => _activa = v)),
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

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) =>
      Row(children: [
        Expanded(child: Text(label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
        Switch(value: value, onChanged: onChanged,
            activeThumbColor: AppTheme.goldColor),
      ]);
}

// ─── Modal nueva entidad ──────────────────────────────────────────────────────

class _FormAltaOrganizador extends StatefulWidget {
  final VoidCallback onCreado;
  const _FormAltaOrganizador({required this.onCreado});

  @override
  State<_FormAltaOrganizador> createState() => _FormAltaOrganizadorState();
}

class _FormAltaOrganizadorState extends State<_FormAltaOrganizador> {
  final _formKey       = GlobalKey<FormState>();
  final _nombreCtrl    = TextEditingController();
  final _descripCtrl   = TextEditingController();
  final _ciudadCtrl    = TextEditingController();
  final _webCtrl       = TextEditingController();
  final _telefonoCtrl  = TextEditingController();
  String? _tipoEntidad;
  String? _pais = 'España';
  bool _enviando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripCtrl.dispose();
    _ciudadCtrl.dispose();
    _webCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await Supabase.instance.client.from('entidades').insert({
        'nombre':      _nombreCtrl.text.trim(),
        'descripcion': _descripCtrl.text.trim().isEmpty ? null : _descripCtrl.text.trim(),
        'tipo':        _tipoEntidad,
        'pais':        _pais,
        'ciudad':      _ciudadCtrl.text.trim().isEmpty ? null : _ciudadCtrl.text.trim(),
        'web':         _webCtrl.text.trim().isEmpty ? null : _webCtrl.text.trim(),
        'telefono':    _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
        'verificada':  false,
        'activa':      true,
      });

      widget.onCreado();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Entidad creada ✓'),
          backgroundColor: AppTheme.goldColor,
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nueva entidad',
                  style: TextStyle(
                      color: AppTheme.goldColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _tf(_nombreCtrl, 'Nombre *',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obligatorio' : null),
              const SizedBox(height: 10),
              _tf(_descripCtrl, 'Descripción', maxLines: 3),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _tipoEntidad,
                decoration: const InputDecoration(labelText: 'Tipo *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: _tiposEntidad
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoEntidad = v),
                validator: (v) => v == null ? 'Selecciona un tipo' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _pais,
                decoration: const InputDecoration(labelText: 'País *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                isExpanded: true,
                items: _paisesEntidad
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _pais = v),
                validator: (v) => v == null ? 'Selecciona un país' : null,
              ),
              const SizedBox(height: 10),
              _tf(_ciudadCtrl, 'Ciudad'),
              const SizedBox(height: 10),
              _tf(_webCtrl, 'Web', hint: 'https://...'),
              const SizedBox(height: 10),
              _tf(_telefonoCtrl, 'Teléfono',
                  keyboard: TextInputType.phone),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _enviando ? null : _crear,
                child: _enviando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.darkBg))
                    : const Text('Crear entidad'),
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
    String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator,
      );
}

// ─── Modal añadir org a entidad existente ─────────────────────────────────────

class _FormAltaOrganizadorEnEntidad extends StatefulWidget {
  final String entidadId;
  final String entidadNombre;
  final VoidCallback onCreado;
  const _FormAltaOrganizadorEnEntidad({
    required this.entidadId,
    required this.entidadNombre,
    required this.onCreado,
  });

  @override
  State<_FormAltaOrganizadorEnEntidad> createState() =>
      _FormAltaOrganizadorEnEntidadState();
}

class _FormAltaOrganizadorEnEntidadState
    extends State<_FormAltaOrganizadorEnEntidad> {
  final _formKey      = GlobalKey<FormState>();
  final _nombreCtrl   = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _obscure  = true;
  bool _enviando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose(); _apellidoCtrl.dispose();
    _emailCtrl.dispose();  _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final authRes = await http.post(
        Uri.parse('${Env.supabaseUrl}/auth/v1/signup'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': Env.supabaseAnonKey,
        },
        body: jsonEncode({
          'email':    _emailCtrl.text.trim(),
          'password': _passCtrl.text,
        }),
      );
      final authData = jsonDecode(authRes.body) as Map<String, dynamic>;
      if (authRes.statusCode != 200) {
        throw Exception(authData['msg'] ?? authData['message'] ?? 'Error');
      }
      final userId = authData['id'] as String?;
      if (userId == null) throw Exception('No se obtuvo ID de usuario');

      await Supabase.instance.client.from('organizadores').insert({
        'id':         userId,
        'nombre':     _nombreCtrl.text.trim(),
        'apellido':   _apellidoCtrl.text.trim(),
        'email':      _emailCtrl.text.trim(),
        'entidad_id': widget.entidadId,
        'rol':        'organizador',
        'estado':     'aprobado',
      });

      widget.onCreado();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Organizador añadido ✓'),
          backgroundColor: AppTheme.goldColor,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Añadir organizador a ${widget.entidadNombre}',
                style: const TextStyle(color: AppTheme.goldColor, fontSize: 16,
                    fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _tf(_nombreCtrl, 'Nombre *')),
                const SizedBox(width: 10),
                Expanded(child: _tf(_apellidoCtrl, 'Apellido *')),
              ]),
              const SizedBox(height: 10),
              _tf(_emailCtrl, 'Email *', keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obligatorio';
                    if (!v.contains('@')) return 'Email no válido';
                    return null;
                  }),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Contraseña temporal *',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                      color: AppTheme.textMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obligatorio';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _enviando ? null : _crear,
                child: _enviando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.darkBg))
                    : const Text('Añadir organizador'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController ctrl, String label, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label),
        validator: validator ??
            (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
      );
}
