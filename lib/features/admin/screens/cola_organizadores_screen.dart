import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/env.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Provider de organizadores ────────────────────────────────────────────────

final organizadoresAdminProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('organizadores')
      .select('*, entidades(nombre, tipo, pais)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Pantalla principal ───────────────────────────────────────────────────────

class ColaOrganizadoresScreen extends ConsumerWidget {
  const ColaOrganizadoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(organizadoresAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Organizadores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note_outlined),
            tooltip: 'Cola de eventos',
            onPressed: () => context.go(AppRoutes.colaEventos),
          ),
          IconButton(
            icon: const Icon(Icons.record_voice_over_outlined),
            tooltip: 'Ponentes',
            onPressed: () => context.go(AppRoutes.ponentes),
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormAlta(context, ref),
        backgroundColor: AppTheme.goldColor,
        foregroundColor: AppTheme.darkBg,
        icon: const Icon(Icons.person_add),
        label: const Text('Nueva entidad'),
      ),
      body: orgAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.goldColor)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (orgs) => orgs.isEmpty
            ? const Center(
                child: Text('No hay organizadores registrados',
                    style: TextStyle(color: AppTheme.textMuted)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orgs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _TarjetaOrganizador(
                  org: orgs[i],
                  onCambioEstado: () => ref.invalidate(organizadoresAdminProvider),
                ),
              ),
      ),
    );
  }

  void _mostrarFormAlta(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FormAltaOrganizador(
        onCreado: () => ref.invalidate(organizadoresAdminProvider),
      ),
    );
  }
}

// ─── Tarjeta de organizador ───────────────────────────────────────────────────

class _TarjetaOrganizador extends StatelessWidget {
  final Map<String, dynamic> org;
  final VoidCallback onCambioEstado;
  const _TarjetaOrganizador(
      {required this.org, required this.onCambioEstado});

  Color _colorEstado(String estado) => switch (estado) {
        'aprobado'  => Colors.greenAccent,
        'pendiente' => AppTheme.goldColor,
        'rechazado' => Colors.redAccent,
        _           => AppTheme.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final entidad = org['entidades'] as Map<String, dynamic>?;
    final estado  = org['estado'] as String? ?? 'pendiente';
    final nombre  = '${org['nombre'] ?? ''} ${org['apellido'] ?? ''}'.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(nombre,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _colorEstado(estado).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _colorEstado(estado).withAlpha(80)),
                ),
                child: Text(estado,
                    style: TextStyle(
                        color: _colorEstado(estado), fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(org['email'] ?? '',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
            if (entidad != null) ...[
              const SizedBox(height: 4),
              Text(
                '${entidad['nombre'] ?? ''} · ${entidad['tipo'] ?? ''} · ${entidad['pais'] ?? ''}',
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
            if (estado == 'pendiente') ...[
              const SizedBox(height: 10),
              Row(children: [
                _BotonEstado(
                  label: 'Aprobar',
                  color: Colors.greenAccent,
                  orgId: org['id'] as String,
                  nuevoEstado: 'aprobado',
                  onDone: onCambioEstado,
                ),
                const SizedBox(width: 8),
                _BotonEstado(
                  label: 'Rechazar',
                  color: Colors.redAccent,
                  orgId: org['id'] as String,
                  nuevoEstado: 'rechazado',
                  onDone: onCambioEstado,
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _BotonEstado extends StatefulWidget {
  final String label;
  final Color color;
  final String orgId;
  final String nuevoEstado;
  final VoidCallback onDone;
  const _BotonEstado({
    required this.label, required this.color, required this.orgId,
    required this.nuevoEstado, required this.onDone,
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
          ? SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: widget.color))
          : Text(widget.label, style: const TextStyle(fontSize: 13)),
    );
  }

  Future<void> _cambiar() async {
    setState(() => _cargando = true);
    try {
      await Supabase.instance.client
          .from('organizadores')
          .update({'estado': widget.nuevoEstado})
          .eq('id', widget.orgId);
      widget.onDone();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}

// ─── Formulario de alta ───────────────────────────────────────────────────────

const _tiposEntidad = [
  'Asociación', 'Fundación', 'Empresa', 'Institución pública',
  'Universidad', 'Museo', 'Medio de comunicación', 'Otro',
];

const _paises = [
  'Argentina', 'Bolivia', 'Chile', 'Colombia', 'Costa Rica', 'Cuba',
  'Ecuador', 'El Salvador', 'España', 'Guatemala', 'Honduras', 'México',
  'Nicaragua', 'Panamá', 'Paraguay', 'Perú', 'Puerto Rico',
  'República Dominicana', 'Uruguay', 'Venezuela',
];

class _FormAltaOrganizador extends StatefulWidget {
  final VoidCallback onCreado;
  const _FormAltaOrganizador({required this.onCreado});

  @override
  State<_FormAltaOrganizador> createState() => _FormAltaOrganizadorState();
}

class _FormAltaOrganizadorState extends State<_FormAltaOrganizador> {
  final _formKey      = GlobalKey<FormState>();
  final _nombreCtrl   = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _entidadCtrl  = TextEditingController();

  String? _tipoEntidad;
  String? _pais = 'España';
  bool _obscure  = true;
  bool _enviando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose(); _apellidoCtrl.dispose();
    _emailCtrl.dispose();  _passCtrl.dispose();
    _entidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    try {
      // 1. Crear usuario en Supabase Auth via REST (sin afectar la sesión del admin)
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
        throw Exception(authData['msg'] ?? authData['message'] ?? 'Error al crear usuario');
      }

      final userId = authData['id'] as String?;
      if (userId == null) throw Exception('No se obtuvo el ID del usuario');

      final supabase = Supabase.instance.client;

      // 2. Insertar entidad
      final entidadRes = await supabase.from('entidades').insert({
        'nombre':     _entidadCtrl.text.trim(),
        'tipo':       _tipoEntidad,
        'pais':       _pais,
        'verificada': false,
        'activa':     true,
      }).select('id').single();

      // 3. Insertar organizador con estado aprobado
      await supabase.from('organizadores').insert({
        'id':         userId,
        'nombre':     _nombreCtrl.text.trim(),
        'apellido':   _apellidoCtrl.text.trim(),
        'email':      _emailCtrl.text.trim(),
        'entidad_id': entidadRes['id'],
        'rol':        'organizador',
        'estado':     'aprobado',
      });

      widget.onCreado();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Organizador creado correctamente ✓'),
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
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nueva entidad organizadora',
                style: TextStyle(
                  color: AppTheme.textPrimary, fontSize: 16,
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Contacto
              _label('Contacto'),
              Row(children: [
                Expanded(child: _campo(_nombreCtrl, 'Nombre *')),
                const SizedBox(width: 10),
                Expanded(child: _campo(_apellidoCtrl, 'Apellido *')),
              ]),
              const SizedBox(height: 10),
              _campo(_emailCtrl, 'Email *',
                  keyboard: TextInputType.emailAddress,
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

              const SizedBox(height: 16),
              _label('Entidad'),
              _campo(_entidadCtrl, 'Nombre de la organización *'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _tipoEntidad,
                decoration: const InputDecoration(labelText: 'Tipo *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: _tiposEntidad.map((t) =>
                  DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _tipoEntidad = v),
                validator: (v) => v == null ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _pais,
                decoration: const InputDecoration(labelText: 'País *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                isExpanded: true,
                items: _paises.map((p) =>
                  DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _pais = v),
                validator: (v) => v == null ? 'Obligatorio' : null,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _enviando ? null : _crear,
                child: _enviando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.darkBg))
                    : const Text('Crear organizador'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(
      color: AppTheme.goldColor, fontSize: 12,
      fontWeight: FontWeight.w600, letterSpacing: 0.8)),
  );

  Widget _campo(TextEditingController ctrl, String label, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: keyboard,
    style: const TextStyle(color: AppTheme.textPrimary),
    decoration: InputDecoration(labelText: label),
    validator: validator ?? (v) =>
        (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
  );
}
