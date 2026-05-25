import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/models/models.dart';
import 'package:pgh_app/core/providers/auth_provider.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

class AutorizadoScreen extends ConsumerWidget {
  const AutorizadoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitacionesAsync  = ref.watch(misInvitacionesProvider);
    final autorizacionesAsync = ref.watch(misAutorizacionesProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        title: const Text('Mi Panel',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go(AppRoutes.agenda);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Sección 1: Invitaciones pendientes ─────────────────────────────
          invitacionesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (invitaciones) {
              if (invitaciones.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invitaciones pendientes',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ...invitaciones.map((inv) => _InvitacionCard(
                        inv: inv,
                        onAceptar: () async {
                          await _cambiarEstado(inv.id, 'activo');
                          ref.invalidate(misInvitacionesProvider);
                          ref.invalidate(misAutorizacionesProvider);
                        },
                        onRechazar: () async {
                          await _cambiarEstado(inv.id, 'inactivo');
                          ref.invalidate(misInvitacionesProvider);
                        },
                      )),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // ── Sección 2: Mis entidades activas ───────────────────────────────
          const Text('Mis entidades',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          autorizacionesAsync.when(
            loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppTheme.goldColor),
                )),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: AppTheme.textMuted)),
            data: (lista) {
              if (lista.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('Aún no tienes entidades activas.',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 13)),
                  ),
                );
              }
              return Column(
                children: lista
                    .map((a) => _EntidadCard(autorizacion: a))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarEstado(String id, String estado) async {
    await Supabase.instance.client
        .from('usuarios_autorizados')
        .update({'estado': estado})
        .eq('id', id);
  }
}

// ─── Tarjeta invitación ───────────────────────────────────────────────────────

class _InvitacionCard extends StatefulWidget {
  final UsuarioAutorizado inv;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  const _InvitacionCard({
    required this.inv,
    required this.onAceptar,
    required this.onRechazar,
  });

  @override
  State<_InvitacionCard> createState() => _InvitacionCardState();
}

class _InvitacionCardState extends State<_InvitacionCard> {
  bool _loading = false;

  Future<void> _tap(VoidCallback fn) async {
    setState(() => _loading = true);
    fn();
    // La invalidación del provider recargará la lista
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.mail_outline, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(widget.inv.entidadNombre,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          const Text(
            'Te han invitado a gestionar los eventos de esta entidad.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.goldColor)))
          else
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _tap(widget.onAceptar),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Aceptar',
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _tap(widget.onRechazar),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Rechazar', style: TextStyle(fontSize: 13)),
                ),
              ),
            ]),
        ],
      ),
    );
  }
}

// ─── Tarjeta entidad activa ───────────────────────────────────────────────────

class _EntidadCard extends StatelessWidget {
  final UsuarioAutorizado autorizacion;
  const _EntidadCard({required this.autorizacion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(autorizacion.entidadNombre,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.agenda),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.darkBorder),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.list_alt_outlined, size: 16),
                label:
                    const Text('Ver eventos', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.go(
                  AppRoutes.adminCrearEvento,
                  extra: {'entidad_id': autorizacion.entidadId},
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nuevo evento',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
