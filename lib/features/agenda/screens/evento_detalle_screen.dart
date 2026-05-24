import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pgh_app/core/models/models.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Constantes de tipo ───────────────────────────────────────────────────────

const _tipoLabels = {
  TipoEvento.conferencia: 'Conferencia',
  TipoEvento.mesaRedonda: 'Mesa redonda',
  TipoEvento.congreso:    'Congreso',
  TipoEvento.networking:  'Networking',
  TipoEvento.cultural:    'Cultural',
  TipoEvento.academico:   'Académico',
  TipoEvento.empresarial: 'Empresarial',
  TipoEvento.politico:    'Político',
  TipoEvento.exposicion:  'Exposición',
  TipoEvento.otro:        'Otro',
};

const _tipoIcons = {
  TipoEvento.conferencia: Icons.mic_outlined,
  TipoEvento.mesaRedonda: Icons.forum_outlined,
  TipoEvento.congreso:    Icons.groups_outlined,
  TipoEvento.networking:  Icons.hub_outlined,
  TipoEvento.cultural:    Icons.palette_outlined,
  TipoEvento.academico:   Icons.school_outlined,
  TipoEvento.empresarial: Icons.business_center_outlined,
  TipoEvento.politico:    Icons.account_balance_outlined,
  TipoEvento.exposicion:  Icons.image_outlined,
  TipoEvento.otro:        Icons.category_outlined,
};

const _tipoColors = {
  TipoEvento.conferencia: Color(0xFF4C8EC9),
  TipoEvento.mesaRedonda: Color(0xFF9B59B6),
  TipoEvento.congreso:    Color(0xFFC9A84C),
  TipoEvento.networking:  Color(0xFF27AE60),
  TipoEvento.cultural:    Color(0xFF8E44AD),
  TipoEvento.academico:   Color(0xFF16A085),
  TipoEvento.empresarial: Color(0xFFE67E22),
  TipoEvento.politico:    Color(0xFFC0392B),
  TipoEvento.exposicion:  Color(0xFF2980B9),
  TipoEvento.otro:        Color(0xFF7F8C8D),
};

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

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (evento) {
          if (evento == null) {
            return const Center(
              child: Text('Evento no encontrado',
                  style: TextStyle(color: Color(0xFF888888))),
            );
          }
          return _EventoDetalleBody(evento: evento);
        },
      ),
    );
  }
}

// ─── Cuerpo principal ─────────────────────────────────────────────────────────

class _EventoDetalleBody extends StatelessWidget {
  final Evento evento;
  const _EventoDetalleBody({required this.evento});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Imagen fija 320px ─────────────────────────────────────────────
        SizedBox(
          height: 320,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImagen(),

              // Gradiente: transparente hasta el 50%, negro casi total al 100%
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xF2000000)],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),

              // Solo botón volver — círculo semitransparente, arriba izquierda
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: GestureDetector(
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/agenda'),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),

              // Título (16px bold) + descripción (11px, max 2 líneas)
              // pegados al fondo de la imagen, padding 12px 16px
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        evento.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.25,
                        ),
                      ),
                      if (evento.descripcion?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          evento.descripcion!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Zona inferior scrolleable ──────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Chips discretos en fila
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TipoChip(tipo: evento.tipo),
                    _ModalidadChip(evento: evento),
                    if (evento.esGratuito) const _GratuitoChip(),
                  ],
                ),
                const SizedBox(height: 14),

                // Grid 1fr 1fr: Fecha | Lugar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _FechaCard(evento: evento)),
                    const SizedBox(width: 10),
                    Expanded(child: _LugarCard(evento: evento)),
                  ],
                ),

                // Card ponente
                if (evento.ponente != null) ...[
                  const SizedBox(height: 10),
                  _PonenteCard(ponente: evento.ponente!),
                ],

                // Card entidad
                const SizedBox(height: 10),
                _EntidadCard(evento: evento),

                // CTA dorado
                const SizedBox(height: 14),
                _CtaButton(evento: evento),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagen() {
    if (evento.portadaUrl != null) {
      return Image.network(
        evento.portadaUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final initial = evento.nombre.isNotEmpty ? evento.nombre[0] : 'E';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF181818), Color(0xFF0D0D0D)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 160,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─── Chips ────────────────────────────────────────────────────────────────────

class _TipoChip extends StatelessWidget {
  final TipoEvento tipo;
  const _TipoChip({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final color = _tipoColors[tipo] ?? const Color(0xFF7F8C8D);
    final icon  = _tipoIcons[tipo]  ?? Icons.category_outlined;
    final label = _tipoLabels[tipo] ?? 'Otro';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ModalidadChip extends StatelessWidget {
  final Evento evento;
  const _ModalidadChip({required this.evento});

  @override
  Widget build(BuildContext context) {
    final icon = evento.tienePresencial && evento.tieneStreaming
        ? Icons.devices_outlined
        : evento.tieneStreaming
            ? Icons.wifi_outlined
            : Icons.location_on_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF777777), size: 12),
          const SizedBox(width: 4),
          Text(evento.modalidadLabel,
              style: const TextStyle(color: Color(0xFF777777), fontSize: 11)),
        ],
      ),
    );
  }
}

class _GratuitoChip extends StatelessWidget {
  const _GratuitoChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1A0E),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.45)),
      ),
      child: const Text('Gratuito',
          style: TextStyle(color: Color(0xFF27AE60), fontSize: 11)),
    );
  }
}

// ─── Tarjeta reutilizable ─────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _CardLabel extends StatelessWidget {
  final String text;
  const _CardLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );
}

ButtonStyle get _cardButtonStyle => OutlinedButton.styleFrom(
      foregroundColor: AppTheme.goldColor,
      side: BorderSide(color: AppTheme.goldColor.withOpacity(0.35)),
      padding: const EdgeInsets.symmetric(vertical: 7),
      minimumSize: const Size(0, 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );

// ─── Fecha card ───────────────────────────────────────────────────────────────

class _FechaCard extends StatelessWidget {
  final Evento evento;
  const _FechaCard({required this.evento});

  @override
  Widget build(BuildContext context) {
    final fmt   = DateFormat('d MMM yyyy', 'es');
    final fecha = fmt.format(evento.fechaInicio);
    final hora  = evento.horaInicio != null
        ? (evento.horaFin != null
            ? '${evento.horaInicio} – ${evento.horaFin}'
            : evento.horaInicio!)
        : null;

    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel('FECHA'),
          const SizedBox(height: 6),
          Text(
            fecha,
            style: const TextStyle(
              color: Color(0xFFF0E8D8),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          if (hora != null) ...[
            const SizedBox(height: 2),
            Text(hora,
                style: const TextStyle(
                    color: Color(0xFF888888), fontSize: 12)),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _abrirUrl(_googleCalendarUrl(evento)),
              style: _cardButtonStyle,
              child: const Text('Añadir al calendar'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lugar card ───────────────────────────────────────────────────────────────

class _LugarCard extends StatelessWidget {
  final Evento evento;
  const _LugarCard({required this.evento});

  @override
  Widget build(BuildContext context) {
    final bool presencial = evento.tienePresencial;
    final String venueLine;
    final String locationLine;
    final String? actionUrl;
    final String actionLabel;

    if (presencial) {
      venueLine    = evento.venueNombre.isNotEmpty ? evento.venueNombre : '—';
      locationLine = '${evento.ciudad}, ${evento.pais}';
      actionUrl    = evento.venue?.urlMapa ??
          'https://www.google.com/maps/search/?api=1&query='
          '${Uri.encodeComponent('${evento.venueNombre}, ${evento.ciudad}, ${evento.pais}')}';
      actionLabel  = 'Ver en Maps';
    } else {
      venueLine    = 'En línea';
      locationLine = evento.urlOnline != null ? 'Ver enlace disponible' : 'Streaming';
      actionUrl    = evento.urlOnline;
      actionLabel  = 'Ver enlace';
    }

    final resolvedUrl = actionUrl; // copia local para null-safety en closure

    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel('LUGAR'),
          const SizedBox(height: 6),
          Text(
            venueLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFF0E8D8),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(locationLine,
              style: const TextStyle(
                  color: Color(0xFF888888), fontSize: 12)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: resolvedUrl != null
                  ? () => _abrirUrl(resolvedUrl)
                  : null,
              style: _cardButtonStyle,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ponente card ─────────────────────────────────────────────────────────────

class _PonenteCard extends StatelessWidget {
  final Ponente ponente;
  const _PonenteCard({required this.ponente});

  @override
  Widget build(BuildContext context) {
    final initial = ponente.nombre.isNotEmpty
        ? ponente.nombre[0].toUpperCase()
        : 'P';

    return _InfoCard(
      child: Row(
        children: [
          // Avatar circular 34px dorado con inicial (o foto si existe)
          SizedBox(
            width: 34,
            height: 34,
            child: ponente.fotoUrl != null
                ? ClipOval(
                    child: Image.network(
                      ponente.fotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarInicial(initial),
                    ),
                  )
                : _avatarInicial(initial),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ponente.nombreCompleto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF0E8D8),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (ponente.cargo?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    ponente.cargo!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarInicial(String initial) => Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFC9A84C), Color(0xFF8B6914)],
          ),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Color(0xFF0D0D0D),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );
}

// ─── Entidad card ─────────────────────────────────────────────────────────────

class _EntidadCard extends StatelessWidget {
  final Evento evento;
  const _EntidadCard({required this.evento});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/entidades/${evento.entidadId}'),
      child: _InfoCard(
        child: Row(
          children: [
            // Icono building o logo
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.antiAlias,
              child: evento.entidadLogoUrl != null
                  ? Image.network(
                      evento.entidadLogoUrl!,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.business_outlined,
                          color: Color(0xFF555555),
                          size: 18),
                    )
                  : const Icon(Icons.business_outlined,
                      color: Color(0xFF555555), size: 18),
            ),
            const SizedBox(width: 12),

            // Nombre + badge verificado
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      evento.entidadNombre ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF0E8D8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (evento.entidadVerificada) ...[
                    const SizedBox(width: 5),
                    const Icon(Icons.verified,
                        color: Color(0xFFC9A84C), size: 14),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                color: Color(0xFF444444), size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Botón CTA dorado ─────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final Evento evento;
  const _CtaButton({required this.evento});

  @override
  Widget build(BuildContext context) {
    String? label;
    IconData icon = Icons.open_in_new;
    String? url;

    if (evento.urlReserva != null) {
      label = evento.esGratuito ? 'Reservar gratis' : 'Comprar entrada';
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

    return SizedBox(
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
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Future<void> _abrirUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

String _googleCalendarUrl(Evento evento) {
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
    final p    = evento.horaInicio!.split(':');
    final h    = int.parse(p[0]);
    final mi   = p.length > 1 ? int.parse(p[1]) : 0;
    final endDt = DateTime(evento.fechaInicio.year, evento.fechaInicio.month,
            evento.fechaInicio.day, h, mi)
        .add(const Duration(hours: 2));
    end = formatDt(
        endDt,
        '${endDt.hour.toString().padLeft(2, '0')}:'
        '${endDt.minute.toString().padLeft(2, '0')}');
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
