import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pgh_app/core/models/models.dart';
import 'package:pgh_app/mock/mock_data.dart';

class PonenteDetalleScreen extends StatelessWidget {
  final String id;
  const PonenteDetalleScreen({super.key, required this.id});

  Ponente? get _ponente =>
      mockPonentes.where((p) => p.id == id).firstOrNull;

  List<Evento> get _proximosEventos {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    return mockEventos
        .where((e) =>
            !e.fechaInicio.isBefore(inicioDia) &&
            e.ponentes.any((p) => p.id == id))
        .toList()
      ..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
  }

  @override
  Widget build(BuildContext context) {
    final ponente = _ponente;
    if (ponente == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(backgroundColor: const Color(0xFF0D0D0D)),
        body: const Center(
          child: Text('Ponente no encontrado',
              style: TextStyle(color: Color(0xFF888888))),
        ),
      );
    }

    final eventos = _proximosEventos;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context, ponente),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ponente.bio != null) ...[
                  _buildBio(ponente),
                  _buildDivider(),
                ],
                if (ponente.linkedinUrl != null || ponente.web != null) ...[
                  _buildLinks(ponente),
                  _buildDivider(),
                ],
                _buildProximosEventos(context, eventos),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, Ponente ponente) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: const Color(0xFF0D0D0D),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black54,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF161616), Color(0xFF0D0D0D)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              CircleAvatar(
                radius: 52,
                backgroundColor: const Color(0xFF222222),
                backgroundImage: ponente.fotoUrl != null
                    ? (ponente.fotoUrl!.startsWith('asset:')
                        ? AssetImage(ponente.fotoUrl!.substring(6)) as ImageProvider
                        : NetworkImage(ponente.fotoUrl!))
                    : null,
                child: ponente.fotoUrl == null
                    ? Text(
                        ponente.nombre[0],
                        style: const TextStyle(
                          color: Color(0xFFC9A84C),
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      )
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
                Text(
                  ponente.cargo!,
                  style: const TextStyle(
                    color: Color(0xFFC9A84C),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (ponente.organizacion != null) ...[
                const SizedBox(height: 2),
                Text(
                  ponente.organizacion!,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBio(Ponente ponente) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo('Sobre el ponente'),
          const SizedBox(height: 10),
          Text(
            ponente.bio!,
            style: const TextStyle(
              color: Color(0xFFBBBBBB),
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinks(Ponente ponente) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo('Enlaces'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (ponente.linkedinUrl != null)
                _LinkButton(
                  icon: Icons.link,
                  label: 'LinkedIn',
                  url: ponente.linkedinUrl!,
                  color: const Color(0xFF0A66C2),
                ),
              if (ponente.web != null)
                _LinkButton(
                  icon: Icons.language,
                  label: 'Web',
                  url: ponente.web!,
                  color: const Color(0xFFC9A84C),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProximosEventos(BuildContext context, List<Evento> eventos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo('Próximos eventos'),
          const SizedBox(height: 12),
          if (eventos.isEmpty)
            const Text(
              'No hay eventos próximos programados.',
              style: TextStyle(color: Color(0xFF666666), fontSize: 14),
            )
          else
            ...eventos.map((e) => _EventoCard(
                  evento: e,
                  onTap: () => context.push('/eventos/${e.id}'),
                )),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(
        color: Color(0xFF1A1A1A),
        thickness: 1,
        height: 1,
      );
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color color;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  final Evento evento;
  final VoidCallback onTap;

  const _EventoCard({required this.evento, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFC9A84C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('d', 'es').format(evento.fechaInicio),
                    style: const TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMM', 'es').format(evento.fechaInicio).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.nombre,
                    style: const TextStyle(
                      color: Color(0xFFF0E8D8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${evento.ciudad}, ${evento.pais}',
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                  if (evento.horaInicio != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      evento.horaInicio!,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 11,
                      ),
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

class _SeccionTitulo extends StatelessWidget {
  final String texto;
  const _SeccionTitulo(this.texto);

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
