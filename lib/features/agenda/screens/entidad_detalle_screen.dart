import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pgh_app/core/models/models.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final entidadDetalleProvider =
    FutureProvider.autoDispose.family<Entidad?, String>((ref, id) async {
  final data = await Supabase.instance.client
      .from('entidades')
      .select()
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return Entidad.fromJson(data);
});

final entidadEventosProvider =
    FutureProvider.autoDispose.family<List<Evento>, String>((ref, entidadId) async {
  final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final data = await Supabase.instance.client
      .from('eventos')
      .select('*, ponentes(*)')
      .eq('entidad_id', entidadId)
      .eq('estado', 'publicado')
      .gte('fecha_inicio', hoy)
      .order('fecha_inicio', ascending: true);

  return (data as List).map((e) => Evento.fromJson(e)).toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class EntidadDetalleScreen extends ConsumerWidget {
  final String id;
  const EntidadDetalleScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(entidadDetalleProvider(id));

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
      data: (entidad) {
        if (entidad == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0D0D),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0D0D0D),
              leading: _backButton(context),
            ),
            body: const Center(
              child: Text('Entidad no encontrada',
                  style: TextStyle(color: Color(0xFF888888))),
            ),
          );
        }
        return _EntidadCuerpo(id: id, entidad: entidad);
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

class _EntidadCuerpo extends ConsumerWidget {
  final String id;
  final Entidad entidad;
  const _EntidadCuerpo({required this.id, required this.entidad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventosAsync = ref.watch(entidadEventosProvider(id));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entidad.descripcion?.isNotEmpty == true) ...[
                  _buildDescripcion(),
                  _divider(),
                ],
                _buildInfo(),
                _divider(),
                if (_tieneContacto) ...[
                  _buildContacto(context),
                  _divider(),
                ],
                if (_tieneRedes) ...[
                  _buildRedes(),
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

  bool get _tieneContacto =>
      (entidad.emailPublico?.isNotEmpty == true) ||
      (entidad.telefono?.isNotEmpty == true) ||
      (entidad.web?.isNotEmpty == true);

  bool get _tieneRedes =>
      (entidad.linkedinUrl?.isNotEmpty == true) ||
      (entidad.instagramUrl?.isNotEmpty == true) ||
      (entidad.twitterUrl?.isNotEmpty == true);

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
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
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: entidad.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(entidad.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.business,
                                color: Color(0xFF555555),
                                size: 32)))
                    : const Icon(Icons.business,
                        color: Color(0xFF555555), size: 32),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entidad.nombre,
                    style: const TextStyle(
                      color: Color(0xFFF0E8D8),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (entidad.verificada) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified,
                        color: Color(0xFFC9A84C), size: 18),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(entidad.tipo,
                  style: const TextStyle(
                      color: Color(0xFF888888), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescripcion() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Titulo('Sobre la entidad'),
            const SizedBox(height: 10),
            Text(entidad.descripcion!,
                style: const TextStyle(
                    color: Color(0xFFBBBBBB), fontSize: 15, height: 1.7)),
          ],
        ),
      );

  Widget _buildInfo() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Titulo('Información'),
            const SizedBox(height: 12),
            _fila(Icons.flag_outlined, entidad.pais),
            if (entidad.ciudad?.isNotEmpty == true)
              _fila(Icons.location_city_outlined, entidad.ciudad!),
            if (entidad.direccion?.isNotEmpty == true)
              _fila(Icons.place_outlined, entidad.direccion!),
          ],
        ),
      );

  Widget _buildContacto(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Titulo('Contacto'),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              if (entidad.web?.isNotEmpty == true)
                _LinkBtn(
                    icon: Icons.language,
                    label: 'Web',
                    url: entidad.web!,
                    color: const Color(0xFFC9A84C)),
              if (entidad.emailPublico?.isNotEmpty == true)
                _LinkBtn(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    url: 'mailto:${entidad.emailPublico}',
                    color: const Color(0xFF4C8EC9)),
              if (entidad.telefono?.isNotEmpty == true)
                _LinkBtn(
                    icon: Icons.phone_outlined,
                    label: entidad.telefono!,
                    url: 'tel:${entidad.telefono}',
                    color: const Color(0xFF27AE60)),
            ]),
          ],
        ),
      );

  Widget _buildRedes() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Titulo('Redes sociales'),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              if (entidad.linkedinUrl?.isNotEmpty == true)
                _LinkBtn(
                    icon: Icons.link,
                    label: 'LinkedIn',
                    url: entidad.linkedinUrl!,
                    color: const Color(0xFF0A66C2)),
              if (entidad.instagramUrl?.isNotEmpty == true)
                _LinkBtn(
                    icon: Icons.camera_alt_outlined,
                    label: 'Instagram',
                    url: entidad.instagramUrl!,
                    color: const Color(0xFFE1306C)),
              if (entidad.twitterUrl?.isNotEmpty == true)
                _LinkBtn(
                    icon: Icons.alternate_email,
                    label: 'Twitter / X',
                    url: entidad.twitterUrl!,
                    color: const Color(0xFF888888)),
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
                    style:
                        TextStyle(color: Color(0xFF666666), fontSize: 14))
                : Column(
                    children: eventos
                        .map((e) => _EventoMini(
                              evento: e,
                              onTap: () =>
                                  context.push('/eventos/${e.id}'),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _fila(IconData icon, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, color: const Color(0xFF666666), size: 15),
          const SizedBox(width: 10),
          Text(texto,
              style: const TextStyle(
                  color: Color(0xFFAAAAAA), fontSize: 14)),
        ]),
      );

  Widget _divider() =>
      const Divider(color: Color(0xFF1A1A1A), thickness: 1, height: 1);
}

// ─── Widgets compartidos ──────────────────────────────────────────────────────

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
