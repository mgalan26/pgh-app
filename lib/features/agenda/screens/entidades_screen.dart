import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/models/models.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final entidadesListaProvider =
    FutureProvider.autoDispose<List<Entidad>>((ref) async {
  final data = await Supabase.instance.client
      .from('entidades')
      .select()
      .eq('activa', true)
      .order('nombre', ascending: true);
  return (data as List).map((e) => Entidad.fromJson(e)).toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class EntidadesScreen extends ConsumerWidget {
  const EntidadesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(entidadesListaProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        automaticallyImplyLeading: false,
        title: const Text('Entidades'),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFC9A84C))),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (entidades) {
          if (entidades.isEmpty) {
            return const Center(
              child: Text('No hay entidades registradas',
                  style: TextStyle(color: Color(0xFF555555))),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entidades.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _EntidadTile(entidad: entidades[i]),
          );
        },
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _EntidadTile extends StatelessWidget {
  final Entidad entidad;
  const _EntidadTile({required this.entidad});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/entidades/${entidad.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: entidad.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        entidad.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.redAccent,
                            size: 22),
                      ),
                    )
                  : const Icon(Icons.business,
                      color: Color(0xFF444444), size: 22),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        entidad.nombre,
                        style: const TextStyle(
                          color: Color(0xFFF0E8D8),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (entidad.verificada)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.verified,
                            color: Color(0xFFC9A84C), size: 14),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Text(entidad.tipo,
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 12)),
                  if (entidad.ciudad != null || entidad.pais.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [entidad.ciudad, entidad.pais]
                          .where((s) => s != null && s.isNotEmpty)
                          .join(', '),
                      style: const TextStyle(
                          color: Color(0xFF555555), fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF333333), size: 18),
          ],
        ),
      ),
    );
  }
}
