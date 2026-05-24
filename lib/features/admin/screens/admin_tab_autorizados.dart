import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _autorizadosProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final sb = Supabase.instance.client;

  // 1. Cargar autorizaciones con entidad
  final data = await sb
      .from('usuarios_autorizados')
      .select('*, entidades(nombre)')
      .order('created_at', ascending: false);
  final list = List<Map<String, dynamic>>.from(data as List);

  // 2. Buscar emails que faltan en la tabla 'usuarios'
  final sinEmail = list
      .where((r) {
        final e = r['email'] as String?;
        return e == null || e.isEmpty;
      })
      .map((r) => r['usuario_id'] as String)
      .toSet()
      .toList();

  if (sinEmail.isEmpty) return list;

  final usersData = await sb
      .from('usuarios')
      .select('id, email')
      .inFilter('id', sinEmail);

  final emailMap = <String, String>{
    for (final u in usersData as List)
      if (u['id'] != null && u['email'] != null)
        u['id'] as String: u['email'] as String,
  };

  // 3. Fusionar
  return list.map((r) {
    final existingEmail = r['email'] as String?;
    if (existingEmail != null && existingEmail.isNotEmpty) return r;
    final resolved = emailMap[r['usuario_id'] as String? ?? ''];
    return resolved != null ? {...r, 'email': resolved} : r;
  }).toList();
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

final _usuariosProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('usuarios')
      .select('id, email')
      .neq('email', '')
      .order('email', ascending: true);
  return List<Map<String, dynamic>>.from(data as List)
      .where((u) => (u['email'] as String? ?? '').isNotEmpty)
      .toList();
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
    final rawEmail = widget.item['email'] as String?;
    final email = (rawEmail != null && rawEmail.isNotEmpty)
        ? rawEmail
        : '(sin email)';
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

// ─── Toggle button helper ─────────────────────────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppTheme.goldColor.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? AppTheme.goldColor : AppTheme.darkBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? AppTheme.goldColor : AppTheme.textMuted,
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
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
  String? _usuarioId;   // id del usuario existente seleccionado
  bool _modoNuevo = false; // false = elegir usuario existente, true = email nuevo
  bool _enviando  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _agregar() async {
    // Determinar email a usar
    String email;
    if (_modoNuevo) {
      email = _emailCtrl.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Introduce un email valido'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }
    } else {
      if (_usuarioId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona un usuario'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }
      final usuarios = ref.read(_usuariosProvider).value ?? [];
      final match = usuarios.where((u) => u['id'] == _usuarioId).toList();
      if (match.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Usuario no encontrado'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }
      email = match.first['email'] as String? ?? '';
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
          ? 'Invitacion enviada y acceso concedido'
          : 'Acceso concedido al usuario existente';

      _emailCtrl.clear();
      setState(() {
        _entidadId = null;
        _usuarioId = null;
      });
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
    final usuariosAsync  = ref.watch(_usuariosProvider);

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

          // ── Toggle modo ───────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: _ToggleBtn(
                label: 'Usuario existente',
                active: !_modoNuevo,
                onTap: () => setState(() {
                  _modoNuevo = false;
                  _emailCtrl.clear();
                }),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ToggleBtn(
                label: 'Email nuevo',
                active: _modoNuevo,
                onTap: () => setState(() {
                  _modoNuevo = true;
                  _usuarioId = null;
                }),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // ── Campos ────────────────────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Usuario existente O email nuevo
            Expanded(
              flex: 5,
              child: _modoNuevo
                  // Email libre
                  ? TextField(
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
                    )
                  // Dropdown usuarios existentes
                  : usuariosAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: LinearProgressIndicator(),
                      ),
                      error: (_, __) => const Text('Error al cargar usuarios',
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 12)),
                      data: (usuarios) => DropdownButtonFormField<String>(
                        value: _usuarioId,
                        isExpanded: true,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 13),
                        dropdownColor: AppTheme.darkCard,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        items: usuarios
                            .map((u) => DropdownMenuItem<String>(
                                  value: u['id'] as String,
                                  child: Text(
                                    u['email'] as String? ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _usuarioId = v),
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Entidad dropdown (siempre visible)
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
              _enviando ? 'Procesando...' : 'Añadir',
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
