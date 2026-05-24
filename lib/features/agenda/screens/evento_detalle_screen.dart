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

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _EventoDetalleBody extends StatelessWidget {
  final Evento evento;
  const _EventoDetalleBody({required this.evento});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Mitad superior: imagen fija 340px ─────────────────────────────────
        SizedBox(
          height: 340,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen o placeholder
              _buildImagen(),
              // Gradiente negro de abajo hacia arriba
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),
              // Botón volver + chips arriba izquierda
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                right: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildBackButton(context),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
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
              // Título, descripción y ponente superpuestos abajo
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        height: 1.3,
                      ),
                    ),
                    if (evento.descripcion?.isNotEmpty == true) ...[
                      const SizedBox(height: 5),
                      Text(
                        evento.descripcion!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (evento.ponente != null) ...[
                      const SizedBox(height: 10),
                      _PonenteRowInline(ponente: evento.ponente!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── Mitad inferior: scrolleable ────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFecha(),
                _buildDivider(),
                _buildLugar(context),
                _buildDivider(),
                _buildEntidad(context),
                _buildDivider(),
                _buildCTA(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Imagen / placeholder ───────────────────────────────────────────────────

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

  // ── Botón volver ───────────────────────────────────────────────────────────

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.canPop() ? context.pop() : context.go('/agenda'),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
      ),
    );
  }

  // ── Fecha + Google Calendar ────────────────────────────────────────────────

  Widget _buildFecha() {
    final fmt   = DateFormat('d MMMM yyyy', 'es');
    final fecha = fmt.format(evento.fechaInicio);
    final hora  = evento.horaInicio != null
        ? (evento.horaFin != null
            ? '${evento.horaInicio} – ${evento.horaFin}'
            : evento.horaInicio!)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFFC9A84C), size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hora != null ? '$fecha  ·  $hora' : fecha,
                  style: const TextStyle(
                    color: Color(0xFFF0E8D8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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

  // ── Lugar + Google Maps ────────────────────────────────────────────────────

  Widget _buildLugar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo('Lugar'),
          const SizedBox(height: 12),
          if (evento.tienePresencial) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Color(0xFF666666), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evento.venueNombre,
                        style: const TextStyle(
                          color: Color(0xFFF0E8D8),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${evento.ciudad}, ${evento.pais}',
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
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
          if (evento.tieneStreaming) ...[
            if (evento.tienePresencial) const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.wifi, color: Color(0xFF4C8EC9), size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Disponible en streaming',
                    style: TextStyle(color: Color(0xFFF0E8D8), fontSize: 14)),
              ),
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
          ],
          if (!evento.tienePresencial && !evento.tieneStreaming)
            Text(
              '${evento.ciudad}, ${evento.pais}',
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
            ),
        ],
      ),
    );
  }

  // ── Organiza ───────────────────────────────────────────────────────────────

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
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: evento.entidadLogoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            evento.entidadLogoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.business,
                                color: Color(0xFF555555), size: 20),
                          ),
                        )
                      : const Icon(Icons.business,
                          color: Color(0xFF555555), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          evento.entidadNombre ?? '',
                          style: const TextStyle(
                            color: Color(0xFFF0E8D8),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (evento.entidadVerificada) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            color: Color(0xFFC9A84C), size: 14),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF444444), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CTA ────────────────────────────────────────────────────────────────────

  Widget _buildCTA() {
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

  // ── Helpers ────────────────────────────────────────────────────────────────

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
      final p  = evento.horaInicio!.split(':');
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

// ─── Ponente inline sobre imagen ──────────────────────────────────────────────

class _PonenteRowInline extends StatelessWidget {
  final Ponente ponente;
  const _PonenteRowInline({required this.ponente});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF333333),
          backgroundImage:
              ponente.fotoUrl != null ? NetworkImage(ponente.fotoUrl!) : null,
          child: ponente.fotoUrl == null
              ? Text(
                  ponente.nombre[0],
                  style: const TextStyle(
                    color: Color(0xFFC9A84C),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
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
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (ponente.cargo != null)
                Text(
                  ponente.cargo!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

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
