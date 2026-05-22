import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pgh_app/core/models/models.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final eventoDetalleProvider =
    FutureProvider.autoDispose.family<Evento?, String>((ref, id) async {
  final data = await Supabase.instance.client
      .from('eventos')
      .select('*, entidades(nombre, verificada, logo_url), ponentes(*)')
      .eq('id', id)
      .maybeSingle();

  if (data == null) return null;

  final entidad = data['entidades'] as Map<String, dynamic>?;
  final ponenteData = data['ponentes'] as Map<String, dynamic>?;

  return Evento.fromJson({
    ...data,
    'entidad_nombre':     entidad?['nombre'],
    'entidad_logo_url':   entidad?['logo_url'],
    'entidad_verificada': entidad?['verificada'] ?? false,
  });
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class EventoDetalleScreen extends ConsumerWidget {
  final String id;
  const EventoDetalleScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventoDetalleProvider(id));

    return async.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          leading: _backButton(context),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          leading: _backButton(context),
        ),
        body: Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
      data: (evento) {
        if (evento == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0D0D),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0D0D0D),
              leading: _backButton(context),
            ),
            body: const Center(
              child: Text('Evento no encontrado',
                  style: TextStyle(color: Color(0xFF888888))),
            ),
          );
        }
        return _EventoDetalleBody(evento: evento);
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

class _EventoDetalleBody extends StatelessWidget {
  final Evento evento;
  const _EventoDetalleBody({required this.evento});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoPrincipal(),
                _buildDivider(),
                _buildDescripcion(),
                if (evento.ponente != null) ...[
                  _buildDivider(),
                  _buildPonente(context),
                ],
                _buildDivider(),
                _buildLugar(context),
                if (evento.coorganizadorNombre != null) ...[
                  _buildDivider(),
                  _buildCoorganizador(),
                ],
                _buildDivider(),
                _buildEntidad(context),
                _buildDivider(),
                _buildCTA(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
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
        background: Stack(
          fit: StackFit.expand,
          children: [
            evento.portadaUrl != null
                ? Image.network(evento.portadaUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0D0D0D)],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _TipoChip(tipo: evento.tipo),
                  _ModalidadBadge(evento: evento),
                  if (evento.esGratuito) const _CosteBadge(gratuito: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
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
          evento.nombre.isNotEmpty ? evento.nombre[0] : 'E',
          style: TextStyle(
            color: color.withOpacity(0.15),
            fontSize: 100,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPrincipal() {
    final fmt = DateFormat('EEEE, d MMMM yyyy', 'es');
    String fecha = fmt.format(evento.fechaInicio);
    fecha = fecha[0].toUpperCase() + fecha.substring(1);
    if (evento.fechaFin != null && evento.fechaFin!.isAfter(evento.fechaInicio)) {
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
                : evento.tieneStreaming
                    ? Icons.wifi
                    : Icons.location_on_outlined,
            content: evento.modalidadLabel,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.location_city_outlined,
            content: '${evento.ciudad}, ${evento.pais}',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _abrirUrl(_googleCalendarUrl()),
              icon: const Icon(Icons.calendar_month_outlined, size: 16),
              label: const Text('Añadir a Google Calendar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.goldColor,
                side: const BorderSide(color: AppTheme.goldColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescripcion() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo('Sobre el evento'),
          const SizedBox(height: 10),
          Text(
            evento.descripcion?.isNotEmpty == true
                ? evento.descripcion!
                : 'Sin descripción disponible.',
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

  Widget _buildPonente(BuildContext context) {
    final p = evento.ponente!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo('Ponente'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/ponentes/${p.id}'),
            child: Container(
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
                  backgroundImage: p.fotoUrl != null
                      ? NetworkImage(p.fotoUrl!) : null,
                  child: p.fotoUrl == null
                      ? Text(p.nombre[0],
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
                      Text(p.nombreCompleto,
                          style: const TextStyle(
                            color: Color(0xFFF0E8D8),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          )),
                      if (p.cargo != null) ...[
                        const SizedBox(height: 2),
                        Text(p.cargo!,
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 12)),
                      ],
                      if (p.organizacion != null) ...[
                        const SizedBox(height: 1),
                        Text(p.organizacion!,
                            style: const TextStyle(
                                color: Color(0xFF666666), fontSize: 11)),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF333333), size: 16),
              ],
            ),
          ),
          ),  // GestureDetector
        ],
      ),
    );
  }

  Widget _buildLugar(BuildContext context) {
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
                  Row(children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFFC9A84C), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(evento.venueNombre,
                          style: const TextStyle(
                            color: Color(0xFFF0E8D8),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          )),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text('${evento.ciudad}, ${evento.pais}',
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final url = evento.venue?.urlMapa ??
                            'https://www.google.com/maps/search/?api=1&query='
                            '${Uri.encodeComponent('${evento.venueNombre}, ${evento.ciudad}, ${evento.pais}')}';
                        _abrirUrl(url);
                      },
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Ver en Google Maps'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.goldColor,
                        side: const BorderSide(color: AppTheme.goldColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
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
              child: Row(children: [
                const Icon(Icons.wifi,
                    color: Color(0xFF4C8EC9), size: 16),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Disponible en streaming',
                        style: TextStyle(
                            color: Color(0xFFF0E8D8), fontSize: 14))),
                if (evento.urlOnline != null)
                  GestureDetector(
                    onTap: () => _abrirUrl(evento.urlOnline!),
                    child: const Text('Ver enlace',
                        style: TextStyle(
                          color: Color(0xFF4C8EC9),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        )),
                  ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildCoorganizador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo('Co-organiza'),
          const SizedBox(height: 10),
          Row(children: [
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
          ]),
        ],
      ),
    );
  }

  Widget _buildEntidad(BuildContext context) {
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
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: evento.entidadLogoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(evento.entidadLogoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.business,
                                  color: Color(0xFF555555), size: 22)))
                      : const Icon(Icons.business,
                          color: Color(0xFF555555), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(evento.entidadNombre ?? '',
                              style: const TextStyle(
                                color: Color(0xFFF0E8D8),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              )),
                        ),
                        if (evento.entidadVerificada)
                          const Icon(Icons.verified,
                              color: Color(0xFFC9A84C), size: 14),
                      ]),
                      const SizedBox(height: 2),
                      const Text('Ver perfil completo',
                          style: TextStyle(
                              color: Color(0xFF666666), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF333333), size: 18),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA() {
    String? label;
    IconData icon = Icons.open_in_new;
    String? url;

    if (evento.urlReserva != null) {
      label = evento.esGratuito ? 'Reservar plaza — Gratis' : 'Comprar entrada';
      icon  = Icons.confirmation_number_outlined;
      url   = evento.urlReserva;
    } else if (evento.enlaceWeb != null) {
      label = 'Más información';
      icon  = Icons.open_in_new;
      url   = evento.enlaceWeb;
    } else if (evento.emailContacto != null) {
      label = 'Contactar';
      icon  = Icons.email_outlined;
      url   = 'mailto:${evento.emailContacto}';
    }

    if (label == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                borderRadius: BorderRadius.circular(8)),
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

  String _googleCalendarUrl() {
    String formatDt(DateTime date, String? hora) {
      final y  = date.year.toString().padLeft(4, '0');
      final mo = date.month.toString().padLeft(2, '0');
      final d  = date.day.toString().padLeft(2, '0');
      if (hora == null) return '${y}${mo}${d}T000000';
      final p  = hora.split(':');
      final h  = p[0].padLeft(2, '0');
      final mi = (p.length > 1 ? p[1] : '00').padLeft(2, '0');
      return '${y}${mo}${d}T${h}${mi}00';
    }

    final start = formatDt(evento.fechaInicio, evento.horaInicio);

    String end;
    if (evento.horaFin != null) {
      end = formatDt(evento.fechaFin ?? evento.fechaInicio, evento.horaFin);
    } else if (evento.horaInicio != null) {
      final p = evento.horaInicio!.split(':');
      final h  = int.parse(p[0]);
      final mi = p.length > 1 ? int.parse(p[1]) : 0;
      final endDt = DateTime(evento.fechaInicio.year, evento.fechaInicio.month,
              evento.fechaInicio.day, h, mi)
          .add(const Duration(hours: 2));
      end = formatDt(endDt,
          '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}');
    } else {
      end = formatDt(evento.fechaFin ?? evento.fechaInicio, null);
    }

    final locationParts = <String>[];
    if (evento.venueNombre.isNotEmpty) locationParts.add(evento.venueNombre);
    locationParts.add('${evento.ciudad}, ${evento.pais}');

    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action':   'TEMPLATE',
      'text':     evento.nombre,
      'dates':    '$start/$end',
      if (evento.descripcion?.isNotEmpty == true) 'details': evento.descripcion!,
      'location': locationParts.join(', '),
    });
    return uri.toString();
  }

  Widget _buildDivider() => const Divider(
      color: Color(0xFF1A1A1A), height: 1, indent: 20, endIndent: 20);
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

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
  const _InfoRow(
      {required this.icon, required this.content, this.accentColor});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: accentColor ?? const Color(0xFF666666), size: 16),
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
                )),
          ),
        ],
      );
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
        : evento.tieneStreaming
            ? Icons.wifi
            : Icons.location_on;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.black45, borderRadius: BorderRadius.circular(4)),
      child: Row(children: [
        Icon(icon, color: Colors.white70, size: 12),
        const SizedBox(width: 4),
        Text(evento.modalidadLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
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
        color: const Color(0xFF27AE60).withOpacity(0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF27AE60)),
      ),
      child: const Text('Gratuito',
          style: TextStyle(color: Color(0xFF27AE60), fontSize: 11)),
    );
  }
}
