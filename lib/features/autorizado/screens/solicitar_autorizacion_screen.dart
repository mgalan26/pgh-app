import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _entidadesPublicasProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('entidades')
      .select('id, nombre, tipo, pais, ciudad, logo_url')
      .eq('activa', true)
      .order('nombre', ascending: true);
  return List<Map<String, dynamic>>.from(data as List);
});

final _misSolicitudesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await Supabase.instance.client
      .from('usuarios_autorizados')
      .select('entidad_id, estado, entidades(nombre)')
      .eq('usuario_id', userId);
  return List<Map<String, dynamic>>.from(data as List);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class SolicitarAutorizacionScreen extends ConsumerStatefulWidget {
  const SolicitarAutorizacionScreen({super.key});

  @override
  ConsumerState<SolicitarAutorizacionScreen> createState() =>
      _SolicitarAutorizacionScreenState();
}

class _SolicitarAutorizacionScreenState
    extends ConsumerState<SolicitarAutorizacionScreen> {
  final _searchCtrl = TextEditingController();
  String _busqueda  = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _solicitar(String entidadId, String entidadNombre) async {
    final sb     = Supabase.instance.client;
    final user   = sb.auth.currentUser;
    if (user == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Solicitar acceso',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '¿Solicitar acceso para gestionar eventos de "$entidadNombre"?\n\n'
          'Un administrador revisará tu solicitud.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Solicitar')),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await sb.from('usuarios_autorizados').insert({
        'usuario_id': user.id,
        'email':      user.email,
        'entidad_id': entidadId,
        'estado':     'pendiente',
      });
      ref.invalidate(_misSolicitudesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada. Pendiente de aprobación.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('unique')
                  ? 'Ya tienes una solicitud para esta entidad'
                  : 'Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entidadesAsync    = ref.watch(_entidadesPublicasProvider);
    final solicitudesAsync  = ref.watch(_misSolicitudesProvider);

    final solicitudesMap = solicitudesAsync.valueOrNull != null
        ? {
            for (final s in solicitudesAsync.valueOrNull!)
              s['entidad_id'] as String: s['estado'] as String
          }
        : <String, String>{};

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        title: const Text('Solicitar acceso a entidad',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar entidad…',
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.textMuted, size: 20),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppTheme.textMuted, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 8),

          // Lista
          Expanded(
            child: entidadesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.redAccent))),
              data: (entidades) {
                final filtradas = _busqueda.isEmpty
                    ? entidades
                    : entidades
                        .where((e) =>
                            (e['nombre'] as String)
                                .toLowerCase()
                                .contains(_busqueda) ||
                            (e['pais'] as String? ?? '')
                                .toLowerCase()
                                .contains(_busqueda))
                        .toList();

                if (filtradas.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron entidades',
                        style: TextStyle(color: AppTheme.textMuted)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtradas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e       = filtradas[i];
                    final id      = e['id'] as String;
                    final nombre  = e['nombre'] as String? ?? '';
                    final tipo    = e['tipo'] as String? ?? '';
                    final pais    = e['pais'] as String? ?? '';
                    final ciudad  = e['ciudad'] as String? ?? '';
                    final logoUrl = e['logo_url'] as String?;
                    final estado  = solicitudesMap[id];

                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        leading: logoUrl != null && logoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(logoUrl,
                                    width: 40, height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _logoPlaceholder(nombre)),
                              )
                            : _logoPlaceholder(nombre),
                        title: Text(nombre,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        subtitle: Text(
                          [tipo, ciudad, pais]
                              .where((s) => s.isNotEmpty)
                              .join(' · '),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                        trailing: _buildAccionBtn(
                            id, nombre, estado),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionBtn(
      String entidadId, String nombre, String? estado) {
    if (estado == 'activo') {
      return const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle, color: Colors.green, size: 16),
        SizedBox(width: 4),
        Text('Activo',
            style: TextStyle(color: Colors.green, fontSize: 12)),
      ]);
    }
    if (estado == 'pendiente') {
      return const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.hourglass_bottom_outlined,
            color: Colors.orange, size: 16),
        SizedBox(width: 4),
        Text('Pendiente',
            style: TextStyle(color: Colors.orange, fontSize: 12)),
      ]);
    }
    if (estado == 'rechazado') {
      return OutlinedButton(
        onPressed: () => _solicitar(entidadId, nombre),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Volver a solicitar',
            style: TextStyle(fontSize: 11)),
      );
    }
    // Sin solicitud previa
    return OutlinedButton(
      onPressed: () => _solicitar(entidadId, nombre),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.goldColor,
        side: const BorderSide(color: AppTheme.goldColor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Solicitar', style: TextStyle(fontSize: 12)),
    );
  }

  Widget _logoPlaceholder(String nombre) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
      color: AppTheme.goldColor.withAlpha(30),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Center(
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: const TextStyle(
            color: AppTheme.goldColor, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
