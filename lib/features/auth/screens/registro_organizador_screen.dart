import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

const _tiposEntidad = [
  'Asociación',
  'Fundación',
  'Empresa',
  'Institución pública',
  'Universidad',
  'Museo',
  'Medio de comunicación',
  'Otro',
];

const _paises = [
  'Argentina', 'Bolivia', 'Chile', 'Colombia', 'Costa Rica', 'Cuba',
  'Ecuador', 'El Salvador', 'España', 'Guatemala', 'Honduras', 'México',
  'Nicaragua', 'Panamá', 'Paraguay', 'Perú', 'Puerto Rico',
  'República Dominicana', 'Uruguay', 'Venezuela',
];

class RegistroOrganizadorScreen extends ConsumerStatefulWidget {
  const RegistroOrganizadorScreen({super.key});

  @override
  ConsumerState<RegistroOrganizadorScreen> createState() =>
      _RegistroOrganizadorScreenState();
}

class _RegistroOrganizadorScreenState
    extends ConsumerState<RegistroOrganizadorScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nombreCtrl    = TextEditingController();
  final _apellidoCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _entidadCtrl   = TextEditingController();

  String? _tipoEntidad;
  String? _pais = 'España';
  bool _obscure  = true;
  bool _enviando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _entidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    final supabase = Supabase.instance.client;

    try {
      // 1. Crear usuario en Supabase Auth
      final res = await supabase.auth.signUp(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final user = res.user;
      if (user == null) throw Exception('No se pudo crear el usuario');

      // 2. Insertar entidad
      final entidadRes = await supabase.from('entidades').insert({
        'nombre':     _entidadCtrl.text.trim(),
        'tipo':       _tipoEntidad,
        'pais':       _pais,
        'verificada': false,
        'activa':     true,
      }).select('id').single();

      final entidadId = entidadRes['id'] as String;

      // 3. Insertar organizador (id = auth user id)
      await supabase.from('organizadores').insert({
        'id':         user.id,
        'nombre':     _nombreCtrl.text.trim(),
        'apellido':   _apellidoCtrl.text.trim(),
        'email':      _emailCtrl.text.trim(),
        'entidad_id': entidadId,
        'rol':        'organizador',
        'estado':     'pendiente',
      });

      if (mounted) context.go(AppRoutes.esperaAprobacion);
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Solicitar acceso')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Logo / cabecera
            const SizedBox(height: 8),
            const Text(
              'Datos de contacto',
              style: TextStyle(
                color: AppTheme.goldColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const Divider(color: AppTheme.darkBorder, height: 20),
            const SizedBox(height: 4),

            Row(children: [
              Expanded(child: _campo(
                ctrl: _nombreCtrl,
                label: 'Nombre *',
                validator: _req,
              )),
              const SizedBox(width: 12),
              Expanded(child: _campo(
                ctrl: _apellidoCtrl,
                label: 'Apellido *',
                validator: _req,
              )),
            ]),
            const SizedBox(height: 12),
            _campo(
              ctrl: _emailCtrl,
              label: 'Email *',
              keyboard: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                if (!v.contains('@')) return 'Email no válido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Contraseña *',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo obligatorio';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),

            const SizedBox(height: 28),
            const Text(
              'Datos de la entidad',
              style: TextStyle(
                color: AppTheme.goldColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const Divider(color: AppTheme.darkBorder, height: 20),
            const SizedBox(height: 4),

            _campo(
              ctrl: _entidadCtrl,
              label: 'Nombre de la organización *',
              validator: _req,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tipoEntidad,
              decoration: const InputDecoration(labelText: 'Tipo de organización *'),
              dropdownColor: AppTheme.darkCard,
              style: const TextStyle(color: AppTheme.textPrimary),
              items: _tiposEntidad.map((t) =>
                DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _tipoEntidad = v),
              validator: (v) => v == null ? 'Selecciona un tipo' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _pais,
              decoration: const InputDecoration(labelText: 'País *'),
              dropdownColor: AppTheme.darkCard,
              style: const TextStyle(color: AppTheme.textPrimary),
              isExpanded: true,
              items: _paises.map((p) =>
                DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _pais = v),
              validator: (v) => v == null ? 'Selecciona un país' : null,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : _registrar,
                child: _enviando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.darkBg))
                    : const Text('Solicitar acceso'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text(
                  '¿Ya tienes cuenta? Inicia sesión',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: keyboard,
    style: const TextStyle(color: AppTheme.textPrimary),
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;
}
