import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _accesosProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('usuarios_autorizados')
      .select('*, entidades(nombre)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data as List);
});

final _entidadesActivasProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('entidades')
      .select('id, nombre')
      .eq('activa', true)
      .order('nombre', ascending: true);
  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Pantalla ─────────────────────────────────────────────────────────────────

class AdminTabAccesos extends ConsumerStatefulWidget {
  const AdminTabAccesos({super.key});

  @override
  ConsumerState<AdminTabAccesos> createState() => _AdminTabAccesosState();
}

class _AdminTabAccesosState extends ConsumerState<AdminTabAccesos> {
  final _emailCtrl    = TextEditingController();
  String? _entidadId;
  bool _guardando     = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Cambiar estado ─────────────────────────────────────────────────────────
  Future<void> _cambiarEstado(String id, String nuevoEstado) async {
    try {
      await Supabase.instance.client
          .from('usuarios_autorizados')
          .update({'estado': nuevoEstado})
          .eq('id', id);
      ref.invalidate(_accesosProvider);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  // ── Enviar invitación via Edge Function ────────────────────────────────────
  Future<void> _enviarInvitacion(String email, String entidadNombre) async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'enviar-invitacion',
        body: {'email': email, 'entidad_nombre': entidadNombre},
      );
      if (res.data?['error'] != null) throw Exception(res.data['error']);
      if (mounted) _snack('Invitación enviada', error: false);
    } catch (e) {
      if (mounted) _snack('Error al enviar: $e');
    }
  }

  // ── Añadir usuario ─────────────────────────────────────────────────────────
  Future<void> _anadir() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || _entidadId == null) {
      _snack('Completa email y entidad');
      return;
    }
    if (!email.contains('@')) {
      _snack('Email no válido');
      return;
    }

    setState(() => _guardando = true);
    try {
      // Buscar o crear usuario en tabla usuarios
      final existingAuth = await Supabase.instance.client
          .from('usuarios')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      String userId;
      if (existingAuth != null) {
        userId = existingAuth['id'] as String;
      } else {
        // Insertar usuario vacío (se completará cuando acceda)
        final inserted = await Supabase.instance.client
            .from('usuarios')
            .insert({
              'email':                 email,
              'nombre':                '',
              'apellido':              '',
              'activo':                true,
              'email_verificado':      false,
              'acepta_comunicaciones': false,
            })
            .select('id')
            .single();
        userId = inserted['id'] as String;
      }

      // Verificar si ya existe relación
      final existing = await Supabase.instance.client
          .from('usuarios_autorizados')
          .select('id')
          .eq('usuario_id', userId)
          .eq('entidad_id', _entidadId!)
          .maybeSingle();

      if (existing != null) {
        _snack('Este usuario ya tiene acceso a esa entidad');
        return;
      }

      await Supabase.instance.client
          .from('usuarios_autorizados')
          .insert({
            'usuario_id': userId,
            'entidad_id': _entidadId,
            'email':      email,
            'estado':     'inactivo',
          });

      _emailCtrl.clear();
      setState(() => _entidadId = null);
      ref.invalidate(_accesosProvider);
      if (mounted) _snack('Usuario añadido', error: false);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _snack(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : AppTheme.goldColor,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final accesosAsync   = ref.watch(_accesosProvider);
    final entidadesAsync = ref.watch(_entidadesActivasProvider);

    return Column(
      children: [
        // ── Lista ────────────────────────────────────────────────────────────
        Expanded(
          child: accesosAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor)),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppTheme.textMuted))),
            data: (list) {
              if (list.isEmpty) {
                return const Center(
                  child: Text('Sin registros',
                      style: TextStyle(color: AppTheme.textMuted)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _AccesoCard(
                  item:               list[i],
                  onCambiarEstado:    _cambiarEstado,
                  onEnviarInvitacion: _enviarInvitacion,
                ),
              );
            },
          ),
        ),

        // ── Formulario ───────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            border: Border(top: BorderSide(color: AppTheme.darkBorder)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: entidadesAsync.when(
            loading: () => const SizedBox(
                height: 40,
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.goldColor, strokeWidth: 2))),
            error: (e, _) => Text('Error cargando entidades: $e',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            data: (entidades) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Email
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _emailCtrl,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle:
                          TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Entidad
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _entidadId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Entidad',
                      labelStyle:
                          TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    items: entidades
                        .map((e) => DropdownMenuItem<String>(
                              value: e['id'] as String,
                              child: Text(e['nombre'] as String,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _entidadId = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _anadir,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.darkBg))
                        : const Text('Añadir', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tarjeta de acceso ────────────────────────────────────────────────────────

class _AccesoCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Future<void> Function(String id, String estado) onCambiarEstado;
  final Future<void> Function(String email, String entidadNombre) onEnviarInvitacion;

  const _AccesoCard({
    required this.item,
    required this.onCambiarEstado,
    required this.onEnviarInvitacion,
  });

  @override
  Widget build(BuildContext context) {
    final id            = item['id'] as String;
    final email         = item['email'] as String? ?? '—';
    final estado        = item['estado'] as String? ?? 'inactivo';
    final entidadNombre =
        (item['entidades'] as Map<String, dynamic>?)?['nombre'] as String? ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13)),
                const SizedBox(height: 2),
                Text(entidadNombre,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Chip estado
          _EstadoChip(estado: estado),
          const SizedBox(width: 8),
          // Botones
          _BotonesEstado(
            id:                 id,
            estado:             estado,
            email:              email,
            entidadNombre:      entidadNombre,
            onCambiarEstado:    onCambiarEstado,
            onEnviarInvitacion: onEnviarInvitacion,
          ),
        ],
      ),
    );
  }
}

// ─── Chip de estado ───────────────────────────────────────────────────────────

class _EstadoChip extends StatelessWidget {
  final String estado;
  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (estado) {
      case 'activo':
        color = Colors.green;
        break;
      case 'invitado':
        color = Colors.amber;
        break;
      case 'solicitado':
        color = Colors.blue;
        break;
      default: // inactivo
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(estado,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Botones de acción ────────────────────────────────────────────────────────

class _BotonesEstado extends StatefulWidget {
  final String id;
  final String estado;
  final String email;
  final String entidadNombre;
  final Future<void> Function(String id, String estado) onCambiarEstado;
  final Future<void> Function(String email, String entidadNombre) onEnviarInvitacion;

  const _BotonesEstado({
    required this.id,
    required this.estado,
    required this.email,
    required this.entidadNombre,
    required this.onCambiarEstado,
    required this.onEnviarInvitacion,
  });

  @override
  State<_BotonesEstado> createState() => _BotonesEstadoState();
}

class _BotonesEstadoState extends State<_BotonesEstado> {
  bool _loading = false;

  Future<void> _tap(String nuevoEstado) async {
    setState(() => _loading = true);
    await widget.onCambiarEstado(widget.id, nuevoEstado);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
          width: 20,
          height: 20,
          child:
              CircularProgressIndicator(strokeWidth: 2, color: AppTheme.goldColor));
    }

    switch (widget.estado) {
      case 'inactivo':
        return _btn('Invitar', Colors.amber, () async {
          await _tap('invitado');
          await widget.onEnviarInvitacion(widget.email, widget.entidadNombre);
        });

      case 'invitado':
        return _btn('Reenviar', Colors.amber, () async {
          setState(() => _loading = true);
          await widget.onEnviarInvitacion(widget.email, widget.entidadNombre);
          if (mounted) setState(() => _loading = false);
        });

      case 'solicitado':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _btn('Aprobar', Colors.green, () => _tap('activo')),
            const SizedBox(width: 6),
            _btn('Rechazar', Colors.red, () => _tap('inactivo')),
          ],
        );

      case 'activo':
        return _btn('Revocar', Colors.red, () => _tap('inactivo'));

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
