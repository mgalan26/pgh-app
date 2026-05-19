import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pgh_app/core/models/models.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final ponenteDetalleProvider =
    FutureProvider.autoDispose.family<Ponente?, String>((ref, id) async {
  final data = await Supabase.instance.client
      .from('ponentes')
      .select()
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return Ponente.fromJson(data);
});

final ponenteEventosProvider =
    FutureProvider.autoDispose.family<List<Evento>, String>((ref, ponenteId) async {
  final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final data = await Supabase.instance.client
      .from('eventos')
      .select('*, entidades(nombre, verificada, logo_url)')
      .eq('ponente_id', ponenteId)
      .eq('estado', 'publicado')
      .gte('fecha_inicio', hoy)
      .order('fecha_inicio', ascending: true);

  return (data as List).map((e) {
    final entidad = e['entidades'] as Map<String, dynamic>?;
    return Evento.fromJson({
      ...e,
      'entidad_nombre':     entidad?['nombre'],
      'entidad_logo_url':   entidad?['logo_url'],
      'entidad_verificada': entidad?['verificada'] ?? false,
    });
  }).toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class PonenteDetalleScreen extends ConsumerWidget {
  final String id;
  const PonenteDetalleScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ponenteDetalleProvider(id));

    return async.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          leading: _backButton(context),
        ),
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFFC9A84C))),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          leading: _backButton(context),
        ),
        body: Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
      ),
      data: (ponente) {
        if (ponente == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0D0D),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0D0D0D),
              leading: _backButton(context),
            ),
            body: const Center(
              child: Text('Ponente no encontrado',
                  style: TextStyle(color: Color(0xFF888888))),
            ),
          );
        }
        return _PonenteCuerpo(id: id, ponente: ponente);
      },
    );
  }

  Widget _backButton(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black54,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/agenda'),
          ),
        ),
      );
}

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _PonenteCuerpo extends ConsumerWidget {
  final String id;
  final Ponente ponente;
  const _PonenteCuerpo({required this.id, required this.ponente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventosAsync = ref.watch(ponenteEventosProvider(id));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ponente.bio != null && ponente.bio!.isNotEmpty) ...[
                  _buildBio(),
                  _divider(),
                ],
                if (ponente.linkedinUrl != null || ponente.web != null) ...[
                  _buildLinks(),
                  _divider(),
                ],
                _buildEventos(context, eventosAsync),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: const Color(0xFF0D0D0D),
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black54,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/agenda'),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF181818), Color(0xFF0D0D0D)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 56),
              CircleAvatar(
                radius: 52,
                backgroundColor: const Color(0xFF222222),
                backgroundImage: ponente.fotoUrl != null
                    ? NetworkImage(ponente.fotoUrl!)
                    : null,
                child: ponente.fotoUrl == null
                    ? Text(ponente.nombre[0],
                        style: const TextStyle(
                          color: Color(0xFFC9A84C),
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ))
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                ponente.nombreCompleto,
                style: const TextStyle(
                  color: Color(0xFFF0E8D8),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (ponente.cargo != null) ...[
                const SizedBox(height: 4),
                Text(ponente.cargo!,
                    style: const TextStyle(
                        color: Color(0xFFC9A84C), fontSize: 13),
                    textAlign: TextAlign.center),
              ],
              if (ponente.organizacion != null) ...[
                const SizedBox(height: 2),
                Text(ponente.organizacion!,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12),
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBio() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Titulo('Sobre el ponente'),
            const SizedBox(height: 10),
            Text(ponente.bio!,
                style: const TextStyle(
                    color: Color(0xFFBBBBBB), fontSize: 15, height: 1.7)),
          ],
        ),
      );

  Widget _buildLinks() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Titulo('Enlaces'),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              if (ponente.linkedinUrl != null)
                _LinkBtn(
                    icon: Icons.link,
                    label: 'LinkedIn',
                    url: ponente.linkedinUrl!,
                    color: const Color(0xFF0A66C2)),
              if (ponente.web != null)
                _LinkBtn(
                    icon: Icons.language,
                    label: 'Web',
                    url: ponente.web!,
                    color: const Color(0xFFC9A84C)),
            ]),
          ],
        ),
      );

  Widget _buildEventos(
      BuildContext context, AsyncValue<List<Evento>> eventosAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Titulo('Próximos eventos'),
          const SizedBox(height: 12),
          eventosAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFC9A84C), strokeWidth: 2)),
            error: (_, __) => const SizedBox.shrink(),
            data: (eventos) => eventos.isEmpty
                ? const Text('No hay eventos próximos programados.',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 14))
                : Column(
                    children: eventos
                        .map((e) => _EventoMini(
                              evento: e,
                              onTap: () => context.push('/eventos/${e.id}'),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
      color: Color(0xFF1A1A1A), thickness: 1, height: 1);
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _Titulo extends StatelessWidget {
  final String texto;
  const _Titulo(this.texto);
  @override
  Widget build(BuildContext context) => Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _LinkBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color color;
  const _LinkBtn(
      {required this.icon,
      required this.label,
      required this.url,
      required this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => launchUrl(Uri.parse(url)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}

class _EventoMini extends StatelessWidget {
  final Evento evento;
  final VoidCallback onTap;
  const _EventoMini({required this.evento, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF222222)),
          ),
          child: Row(children: [
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFC9A84C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(children: [
                Text(
                  DateFormat('d', 'es').format(evento.fechaInicio),
                  style: const TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM', 'es')
                      .format(evento.fechaInicio)
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFFC9A84C), fontSize: 10),
                ),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(evento.nombre,
                      style: const TextStyle(
                          color: Color(0xFFF0E8D8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${evento.ciudad}, ${evento.pais}',
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 12)),
                  if (evento.horaInicio != null) ...[
                    const SizedBox(height: 2),
                    Text(evento.horaInicio!,
                        style: const TextStyle(
                            color: Color(0xFF666666), fontSize: 11)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF333333), size: 18),
          ]),
        ),
      );
}
