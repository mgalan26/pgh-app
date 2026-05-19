import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/models/models.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final ponentesListaProvider =
    FutureProvider.autoDispose<List<Ponente>>((ref) async {
  final data = await Supabase.instance.client
      .from('ponentes')
      .select()
      .order('apellido', ascending: true);
  return (data as List).map((e) => Ponente.fromJson(e)).toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class PonentesScreen extends ConsumerWidget {
  const PonentesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ponentesListaProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        automaticallyImplyLeading: false,
        title: const Text('Ponentes'),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFC9A84C))),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (ponentes) {
          if (ponentes.isEmpty) {
            return const Center(
              child: Text('No hay ponentes registrados',
                  style: TextStyle(color: Color(0xFF555555))),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ponentes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _PonenteTile(ponente: ponentes[i]),
          );
        },
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _PonenteTile extends StatelessWidget {
  final Ponente ponente;
  const _PonenteTile({required this.ponente});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/ponentes/${ponente.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF1A1A1A),
              backgroundImage: ponente.fotoUrl != null
                  ? NetworkImage(ponente.fotoUrl!)
                  : null,
              child: ponente.fotoUrl == null
                  ? Text(
                      ponente.nombre[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFC9A84C),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ponente.nombreCompleto,
                    style: const TextStyle(
                      color: Color(0xFFF0E8D8),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (ponente.cargo != null) ...[
                    const SizedBox(height: 3),
                    Text(ponente.cargo!,
                        style: const TextStyle(
                            color: Color(0xFFC9A84C), fontSize: 12)),
                  ],
                  if (ponente.organizacion != null) ...[
                    const SizedBox(height: 2),
                    Text(ponente.organizacion!,
                        style: const TextStyle(
                            color: Color(0xFF666666), fontSize: 11)),
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
