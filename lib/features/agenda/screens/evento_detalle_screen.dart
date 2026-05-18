import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pgh_app/core/models/models.dart';
import 'package:pgh_app/mock/mock_data.dart';

class EventoDetalleScreen extends StatelessWidget {
  final String id;
  const EventoDetalleScreen({super.key, required this.id});

  Evento? get _evento =>
      mockEventos.where((e) => e.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final evento = _evento;
    if (evento == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(backgroundColor: const Color(0xFF0D0D0D)),
        body: const Center(
          child: Text('Evento no encontrado',
            style: TextStyle(color: Color(0xFF888888))),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context, evento),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoPrincipal(evento),
                _buildDivider(),
                _buildDescripcion(evento),
                if (evento.ponentes.isNotEmpty) ...[
                  _buildDivider(),
                  _buildPonentes(context, evento),
                ],
                _buildDivider(),
                _buildLugar(context, evento),
                if (evento.coorganizadorNombre != null) ...[
                  _buildDivider(),
                  _buildCoorganizador(evento),
                ],
                _buildDivider(),
                _buildEntidad(context, evento),
                _buildDivider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: _buildCTA(evento),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, Evento evento) {
    return SliverAppBar(
      expandedHeight: 260,
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
        background: Stack(
          fit: StackFit.expand,
          children: [
            evento.portadaUrl != null
                ? Image.network(evento.portadaUrl!, fit: BoxFit.cover)
                : _buildPlaceholder(evento),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0D0D0D)],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Row(
                children: [
                  _TipoChip(tipo: evento.tipo),
                  const SizedBox(width: 8),
                  _ModalidadBadge(evento: evento),
                  const Spacer(),
                  _CosteBadge(gratuito: evento.esGratuito),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Evento evento) {
    final color = _tipoColors[evento.tipo] ?? const Color(0xFFC9A84C);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.3), const Color(0xFF0D0D0D)],
        ),
      ),
      child: Center(
        child: Text(
          evento.nombre[0],
          style: TextStyle(
            color: color.withOpacity(0.15),
            fontSize: 120,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPrincipal(Evento evento) {
    final fmt = DateFormat('EEEE, d MMMM yyyy', 'es');
    String fecha = fmt.format(evento.fechaInicio);
    fecha = fecha[0].toUpperCase() + fecha.substring(1);
    if (evento.fechaFin != null) {
      final fin = DateFormat('d MMMM yyyy', 'es').format(evento.fechaFin!);
      fecha = '$fecha — $fin';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(evento.nombre,
            style: const TextStyle(
              color: Color(0xFFF0E8D8),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            content: fecha,
            accentColor: const Color(0xFFC9A84C),
          ),
          if (evento.horaInicio != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.access_time,
              content: evento.horaFin != null
                  ? '${evento.horaInicio} – ${evento.horaFin}'
                  : evento.horaInicio!,
            ),
          ],
          const SizedBox(height: 10),
          _InfoRow(
            icon: evento.tienePresencial && evento.tieneStreaming
                ? Icons.devices
                : evento.tieneStreaming ? Icons.wifi : Icons.location_on_outlined,
            content: evento.modalidadLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildDescripcion(Evento evento) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo('Sobre el evento'),
          const SizedBox(height: 10),
          Text(
            evento.descripcion ?? 'Sin descripción disponible.',
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

  Widget _buildPonentes(BuildContext context, Evento evento) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SeccionTitulo(evento.ponentes.length == 1 ? 'Ponente' : 'Ponentes'),
          const SizedBox(height: 12),
          ...evento.ponentes.map((p) => _PonenteCard(
            ponente: p,
            onTap: () => context.push('/ponentes/${p.id}'),
          )),
        ],
      ),
    );
  }

  Widget _buildLugar(BuildContext context, Evento evento) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo('Lugar'),
          const SizedBox(height: 12),
          if (evento.tienePresencial) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                        color: Color(0xFFC9A84C), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(evento.venueNombre,
                          style: const TextStyle(
                            color: Color(0xFFF0E8D8),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (evento.venue?.direccion != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(evento.venue!.direccion!,
                        style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 13)),
                    ),
                  ],
                  if (evento.venue?.urlMapa != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _abrirUrl(evento.venue!.urlMapa!),
                      child: const Row(
                        children: [
                          SizedBox(width: 24),
                          Icon(Icons.map_outlined,
                            color: Color(0xFFC9A84C), size: 14),
                          SizedBox(width: 6),
                          Text('Ver en Google Maps',
                            style: TextStyle(
                              color: Color(0xFFC9A84C),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (evento.tieneStreaming) const SizedBox(height: 10),
          ],
          if (evento.tieneStreaming)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi,
                    color: Color(0xFF4C8EC9), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Disponible en streaming',
                      style: TextStyle(
                        color: Color(0xFFF0E8D8), fontSize: 14)),
                  ),
                  if (evento.urlOnline != null)
                    GestureDetector(
                      onTap: () => _abrirUrl(evento.urlOnline!),
                      child: const Text('Ver enlace',
                        style: TextStyle(
                          color: Color(0xFF4C8EC9),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Opacity(
            opacity: 0.4,
            child: Row(
              children: const [
                Icon(Icons.calendar_month_outlined,
                  color: Color(0xFF888888), size: 16),
                SizedBox(width: 8),
                Text('Añadir a Google Calendar',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                SizedBox(width: 6),
                Text('· Próximamente',
                  style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoorganizador(Evento evento) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo('Co-organiza'),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.handshake_outlined,
                color: Color(0xFF666666), size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(evento.coorganizadorNombre!,
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC), fontSize: 14)),
              ),
              if (evento.coorganizadorWeb != null)
                GestureDetector(
                  onTap: () => _abrirUrl(evento.coorganizadorWeb!),
                  child: const Icon(Icons.open_in_new,
                    color: Color(0xFF555555), size: 14),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntidad(BuildContext context, Evento evento) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo('Organiza'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/entidades/${evento.entidadId}'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business,
                      color: Color(0xFF555555), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(evento.entidadNombre ?? '',
                                style: const TextStyle(
                                  color: Color(0xFFF0E8D8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (evento.entidadVerificada)
                              const Icon(Icons.verified,
                                color: Color(0xFFC9A84C), size: 14),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text('Ver perfil completo',
                          style: TextStyle(
                            color: Color(0xFF666666), fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                    color: Color(0xFF333333), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA(Evento evento) {
    String label;
    IconData icon;
    String? url;

    if (evento.esGratuito && evento.urlReserva == null) {
      if (evento.enlaceWeb == null) return const SizedBox.shrink();
      label = 'Más información';
      icon = Icons.open_in_new;
      url = evento.enlaceWeb;
    } else if (evento.esGratuito) {
      label = 'Reservar plaza — Gratis';
      icon = Icons.confirmation_number_outlined;
      url = evento.urlReserva;
    } else {
      label = 'Comprar entrada';
      icon = Icons.confirmation_number_outlined;
      url = evento.urlReserva ?? evento.enlaceWeb;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: url != null ? () => _abrirUrl(url!) : null,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC9A84C),
            foregroundColor: const Color(0xFF0D0D0D),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  void _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _buildDivider() => const Divider(
    color: Color(0xFF1A1A1A), height: 1, indent: 20, endIndent: 20);
}

const _tipoColors = {
  TipoEvento.conferencia:  Color(0xFF4C8EC9),
  TipoEvento.mesaRedonda:  Color(0xFF9B59B6),
  TipoEvento.congreso:     Color(0xFFC9A84C),
  TipoEvento.networking:   Color(0xFF27AE60),
  TipoEvento.cultural:     Color(0xFF8E44AD),
  TipoEvento.academico:    Color(0xFF16A085),
  TipoEvento.empresarial:  Color(0xFFE67E22),
  TipoEvento.politico:     Color(0xFFC0392B),
  TipoEvento.exposicion:   Color(0xFF2980B9),
  TipoEvento.otro:         Color(0xFF7F8C8D),
};

const _tipoLabels = {
  TipoEvento.conferencia:  'Conferencia',
  TipoEvento.mesaRedonda:  'Mesa redonda',
  TipoEvento.congreso:     'Congreso',
  TipoEvento.networking:   'Networking',
  TipoEvento.cultural:     'Cultural',
  TipoEvento.academico:    'Académico',
  TipoEvento.empresarial:  'Empresarial',
  TipoEvento.politico:     'Político',
  TipoEvento.exposicion:   'Exposición',
  TipoEvento.otro:         'Otro',
};

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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String content;
  final Color? accentColor;

  const _InfoRow({required this.icon, required this.content, this.accentColor});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: accentColor ?? const Color(0xFF666666), size: 16),
      const SizedBox(width: 10),
      Expanded(
        child: Text(content,
          style: TextStyle(
            color: accentColor != null
                ? const Color(0xFFF0E8D8)
                : const Color(0xFFAAAAAA),
            fontSize: 14,
            fontWeight: accentColor != null
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ),
    ],
  );
}

class _PonenteCard extends StatelessWidget {
  final Ponente ponente;
  final VoidCallback onTap;

  const _PonenteCard({required this.ponente, required this.onTap});

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
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF222222),
              backgroundImage: ponente.fotoUrl != null
                  ? NetworkImage(ponente.fotoUrl!) : null,
              child: ponente.fotoUrl == null
                  ? Text(ponente.nombre[0],
                      style: const TextStyle(
                        color: Color(0xFFC9A84C),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ponente.nombreCompleto,
                    style: const TextStyle(
                      color: Color(0xFFF0E8D8),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (ponente.cargo != null) ...[
                    const SizedBox(height: 2),
                    Text(ponente.cargo!,
                      style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12)),
                  ],
                  if (ponente.organizacion != null) ...[
                    const SizedBox(height: 1),
                    Text(ponente.organizacion!,
                      style: const TextStyle(
                        color: Color(0xFF666666), fontSize: 11)),
                  ],
                  if (ponente.rolEnEvento != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9A84C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: const Color(0xFFC9A84C).withOpacity(0.3)),
                      ),
                      child: Text(ponente.rolEnEvento!,
                        style: const TextStyle(
                          color: Color(0xFFC9A84C), fontSize: 10)),
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

class _TipoChip extends StatelessWidget {
  final TipoEvento tipo;
  const _TipoChip({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final color = _tipoColors[tipo] ?? const Color(0xFF7F8C8D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(_tipoLabels[tipo] ?? 'Otro',
        style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _ModalidadBadge extends StatelessWidget {
  final Evento evento;
  const _ModalidadBadge({required this.evento});

  @override
  Widget build(BuildContext context) {
    final icon = evento.tienePresencial && evento.tieneStreaming
        ? Icons.devices
        : evento.tieneStreaming ? Icons.wifi : Icons.location_on;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(evento.modalidadLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _CosteBadge extends StatelessWidget {
  final bool gratuito;
  const _CosteBadge({required this.gratuito});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: gratuito
            ? const Color(0xFF27AE60).withOpacity(0.3)
            : Colors.black45,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: gratuito
              ? const Color(0xFF27AE60)
              : const Color(0xFFC9A84C),
        ),
      ),
      child: Text(
        gratuito ? 'Gratuito' : 'De pago',
        style: TextStyle(
          color: gratuito
              ? const Color(0xFF27AE60)
              : const Color(0xFFC9A84C),
          fontSize: 11,
        ),
      ),
    );
  }
}
