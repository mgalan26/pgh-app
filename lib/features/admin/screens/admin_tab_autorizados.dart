import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _autorizadosProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('usuarios_autorizados')
      .select('*, entidades(nombre)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data as List);
});

final _entidadesAccesoProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('entidades')
      .select('id, nombre')
      .eq('activa', true)
      .order('nombre', ascending: true);
  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Tab ──────────────────────────────────────────────────────────────────────

class AdminTabAutorizados extends ConsumerWidget {
  const AdminTabAutorizados({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_autorizadosProvider);

    return Column(
      children: [
        // ── Sección 1: lista de autorizaciones ────────────────────────────
        Expanded(
          child: async.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor)),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.redAccent))),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_outlined,
                          color: AppTheme.textMuted, size: 40),
                      SizedBox(height: 10),
                      Text('No hay accesos registrados',
                          style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) => _AutorizadoTile(
                  item: items[i],
                  onRevoked: () => ref.invalidate(_autorizadosProvider),
                ),
              );
            },
          ),
        ),

        // ── Sección 2: formulario añadir acceso ───────────────────────────
        const Divider(height: 1, color: AppTheme.darkBorder),
        _FormAnadirAcceso(onAdded: () => ref.invalidate(_autorizadosProvider)),
      ],
    );
  }
}

// ─── Tile de autorización ─────────────────────────────────────────────────────

class _AutorizadoTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRevoked;
  const _AutorizadoTile({required this.item, required this.onRevoked});

  @override
  State<_AutorizadoTile> createState() => _AutorizadoTileState();
}

class _AutorizadoTileState extends State<_AutorizadoTile> {
  bool _revoking = false;

  Color _colorEstado(String s) => switch (s) {
        'activo'    => Colors.greenAccent,
        'pendiente' => AppTheme.goldColor,
        'rechazado' => Colors.redAccent,
        _           => AppTheme.textMuted,
      };

  Future<void> _revocar() async {
    final email = widget.item['email'] as String? ?? 'este usuario';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Revocar acceso',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '¿Eliminar el acceso de $email?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Revocar')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _revoking = true);
    try {
      await Supabase.instance.client
          .from('usuarios_autorizados')
          .delete()
          .eq('id', widget.item['id'] as String);
      widget.onRevoked();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _revoking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email   = widget.item['email'] as String?
        ?? widget.item['usuario_id'] as String?
        ?? '—';
    final entidad = widget.item['entidades'] as Map<String, dynamic>?;
    final entNom  = entidad?['nombre'] as String? ?? '—';
    final estado  = widget.item['estado'] as String? ?? 'pendiente';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final color   = _colorEstado(estado);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.goldColor.withAlpha(40),
          child: Text(initial,
              style: const TextStyle(
                  color: AppTheme.goldColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),

        // Email + entidad
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.business_outlined,
                    color: AppTheme.textMuted, size: 11),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(entNom,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Estado chip
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
        const SizedBox(width: 4),

        // Revocar
        _revoking
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.redAccent))
            : IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.redAccent, size: 19),
                tooltip: 'Revocar acceso',
                onPressed: _revocar,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
      ]),
    );
  }
}

// ─── Formulario añadir acceso ─────────────────────────────────────────────────

class _FormAnadirAcceso extends ConsumerStatefulWidget {
  final VoidCallback onAdded;
  const _FormAnadirAcceso({required this.onAdded});

  @override
  ConsumerState<_FormAnadirAcceso> createState() => _FormAnadirAccesoState();
}

class _FormAnadirAccesoState extends ConsumerState<_FormAnadirAcceso> {
  final _emailCtrl = TextEditingController();
  String? _entidadId;
  bool _enviando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _agregar() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Introduce un email válido'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    if (_entidadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona una entidad'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _enviando = true);
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'invite-user',
        body: {'email': email, 'entidad_id': _entidadId},
      );
      if (res.data?['ok'] != true) {
        throw Exception(res.data?['error'] ?? 'Error desconocido');
      }

      final invited = res.data?['invited'] as bool? ?? false;
      final msg = invited
          ? 'Invitación enviada y acceso concedido'
          : 'Acceso concedido al usuario existente';

      _emailCtrl.clear();
      setState(() => _entidadId = null);
      widget.onAdded();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entidadesAsync = ref.watch(_entidadesAccesoProvider);

    return Container(
      color: AppTheme.darkCard,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Añadir acceso',
              style: TextStyle(
                  color: AppTheme.goldColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Email
            Expanded(
              flex: 5,
              child: TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Entidad dropdown
            Expanded(
              flex: 5,
              child: entidadesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: LinearProgressIndicator(),
                ),
                error: (_, __) => const Text('Error',
                    style: TextStyle(
                        color: Colors.redAccent, fontSize: 12)),
                data: (entidades) => DropdownButtonFormField<String>(
                  value: _entidadId,
                  isExpanded: true,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13),
                  dropdownColor: AppTheme.darkCard,
                  decoration: const InputDecoration(
                    labelText: 'Entidad',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: entidades
                      .map((e) => DropdownMenuItem<String>(
                            value: e['id'] as String,
                            child: Text(
                              e['nombre'] as String? ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _entidadId = v),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _enviando ? null : _agregar,
            icon: _enviando
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.darkBg))
                : const Icon(Icons.add_circle_outline, size: 16),
            label: Text(
              _enviando ? 'Procesando…' : 'Añadir',
              style: const TextStyle(fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
