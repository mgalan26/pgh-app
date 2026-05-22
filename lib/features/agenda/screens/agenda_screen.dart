import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/models/models.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final agendaProvider =
    FutureProvider.autoDispose<List<Evento>>((ref) async {
  final hoy = DateTime.now().toIso8601String().substring(0, 10);
  final data = await Supabase.instance.client
      .from('eventos')
      .select('*, entidades(nombre, verificada), ponentes(*)')
      .eq('estado', 'publicado')
      .gte('fecha_inicio', hoy)
      .order('fecha_inicio', ascending: true);

  return (data as List).map((e) {
    final entidad = e['entidades'] as Map<String, dynamic>?;
    return Evento.fromJson({
      ...e,
      'entidad_nombre':     entidad?['nombre'],
      'entidad_verificada': entidad?['verificada'] ?? false,
    });
  }).toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  String? _filtroPais;
  TipoEvento? _filtroTipo;
  bool? _filtroGratuito;
  bool? _filtroPresencial;
  String? _filtroEntidad;

  List<Evento> _filtrar(List<Evento> eventos) {
    return eventos.where((e) {
      if (_filtroPais != null && e.pais != _filtroPais) return false;
      if (_filtroTipo != null && e.tipo != _filtroTipo) return false;
      if (_filtroGratuito != null && e.esGratuito != _filtroGratuito) return false;
      if (_filtroPresencial == true && !e.tienePresencial) return false;
      if (_filtroPresencial == false && !e.tieneStreaming) return false;
      if (_filtroEntidad != null && e.entidadNombre != _filtroEntidad) return false;
      return true;
    }).toList();
  }

  bool get _hayFiltrosActivos =>
      _filtroPais != null || _filtroTipo != null ||
      _filtroGratuito != null || _filtroPresencial != null ||
      _filtroEntidad != null;

  void _limpiarFiltros() => setState(() {
    _filtroPais = null; _filtroTipo = null;
    _filtroGratuito = null; _filtroPresencial = null;
    _filtroEntidad = null;
  });

  @override
  Widget build(BuildContext context) {
    final asyncEventos = ref.watch(agendaProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: asyncEventos.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.goldColor)),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ERROR SUPABASE:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                Text('$e', style: const TextStyle(color: Colors.redAccent)),
              ],
            )),
          data: (todos) {
            final eventos = _filtrar(todos);
            return Column(
              children: [
                _buildHeader(eventos.length),
                _buildFiltros(todos),
                if (_hayFiltrosActivos) _buildFiltrosActivos(),
                Expanded(
                  child: eventos.isEmpty
                      ? _buildVacio(todos.isEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: eventos.length,
                          itemBuilder: (context, i) => _EventoCard(
                            evento: eventos[i],
                            onTap: () => context.push('/eventos/${eventos[i].id}'),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFC9A84C), Color(0xFF8B6914)]),
            ),
            child: const Center(
              child: Text('P',
                style: TextStyle(
                  color: Color(0xFF0D0D0D),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PARLAMENTO GLOBAL HISPANO',
                  style: TextStyle(
                    color: Color(0xFFC9A84C),
                    fontSize: 10,
                    letterSpacing: 2)),
                Text('Agenda de Eventos',
                  style: TextStyle(
                    color: Color(0xFFF0E8D8),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count eventos',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(List<Evento> todos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FiltroChip(
                label: 'País',
                value: _filtroPais,
                opciones: todos.map((e) => e.pais).toSet().toList()..sort(),
                onSelected: (v) => setState(() => _filtroPais = v),
              ),
              _FiltroChip(
                label: 'Tipo',
                value: _filtroTipo?.name,
                opciones: TipoEvento.values.map((t) => t.name).toList(),
                onSelected: (v) => setState(() =>
                  _filtroTipo = v != null ? TipoEvento.values.byName(v) : null),
              ),
              _FiltroChip(
                label: 'Entidad',
                value: _filtroEntidad,
                opciones: todos
                    .map((e) => e.entidadNombre ?? '')
                    .where((n) => n.isNotEmpty)
                    .toSet().toList()..sort(),
                onSelected: (v) => setState(() => _filtroEntidad = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosActivos() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          const Text('Filtrando · ',
            style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
          GestureDetector(
            onTap: _limpiarFiltros,
            child: const Text('Limpiar todo',
              style: TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 11,
                decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  Widget _buildVacio(bool sinEventos) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            sinEventos
                ? 'Próximamente nuevos eventos'
                : 'No hay eventos con estos filtros',
            style: const TextStyle(color: Color(0xFF555555))),
        ],
      ),
    );
  }
}

// ─── Constantes de tipo ────────────────────────────────────────────────────────

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

// ─── Tarjeta de evento ────────────────────────────────────────────────────────

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
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _buildFecha(),
              Expanded(child: _buildContenido()),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.chevron_right,
                  color: Color(0xFF333333), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFecha() {
    final dia = DateFormat('dd').format(evento.fechaInicio);
    final mes = DateFormat('MMM', 'es').format(evento.fechaInicio).toUpperCase();
    final anio = DateFormat('yyyy').format(evento.fechaInicio);
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8)),
        border: Border(right: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(dia,
            style: const TextStyle(
              color: Color(0xFFC9A84C), fontSize: 22,
              fontWeight: FontWeight.bold, height: 1)),
          const SizedBox(height: 2),
          Text(mes,
            style: const TextStyle(
              color: Color(0xFF666666), fontSize: 10, letterSpacing: 1)),
          Text(anio,
            style: const TextStyle(color: Color(0xFF444444), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _TipoChip(tipo: evento.tipo),
            const SizedBox(width: 6),
            _ModalidadChip(evento: evento),
            if (evento.esGratuito) ...[
              const SizedBox(width: 6),
              const _CosteChip(gratuito: true),
            ],
          ]),
          const SizedBox(height: 6),
          Text(evento.nombre,
            style: const TextStyle(
              color: Color(0xFFF0E8D8), fontSize: 14,
              fontWeight: FontWeight.w600, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on_outlined,
              color: Color(0xFF666666), size: 12),
            const SizedBox(width: 3),
            Text('${evento.ciudad}, ${evento.pais}',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
            if (evento.horaInicio != null) ...[
              const SizedBox(width: 10),
              const Icon(Icons.access_time,
                color: Color(0xFF666666), size: 12),
              const SizedBox(width: 3),
              Text(evento.horaInicio!,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
            ],
          ]),
          if (evento.ponente != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.person_outline,
                color: Color(0xFF888888), size: 12),
              const SizedBox(width: 3),
              Text(evento.ponente!.nombreCompleto,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
              if (evento.ponente!.cargo != null) ...[
                const Text(' · ',
                  style: TextStyle(color: Color(0xFF444444), fontSize: 11)),
                Flexible(child: Text(evento.ponente!.cargo!,
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
                  overflow: TextOverflow.ellipsis)),
              ],
            ]),
          ],
          if (evento.entidadNombre != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              if (evento.entidadVerificada)
                const Icon(Icons.verified,
                  color: Color(0xFFC9A84C), size: 11),
              const SizedBox(width: 3),
              Text(evento.entidadNombre!,
                style: const TextStyle(
                  color: Color(0xFF555555), fontSize: 10)),
            ]),
          ],
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(_tipoLabels[tipo] ?? 'Otro',
        style: TextStyle(color: color, fontSize: 9, letterSpacing: 0.5)),
    );
  }
}

class _ModalidadChip extends StatelessWidget {
  final Evento evento;
  const _ModalidadChip({required this.evento});
  @override
  Widget build(BuildContext context) {
    final icon = evento.tienePresencial && evento.tieneStreaming
        ? Icons.devices
        : evento.tieneStreaming ? Icons.wifi : Icons.location_on;
    return Row(children: [
      Icon(icon, color: const Color(0xFF555555), size: 11),
      const SizedBox(width: 3),
      Text(evento.modalidadLabel,
        style: const TextStyle(color: Color(0xFF555555), fontSize: 9)),
    ]);
  }
}

class _CosteChip extends StatelessWidget {
  final bool gratuito;
  const _CosteChip({required this.gratuito});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60).withAlpha(38),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF27AE60).withAlpha(100)),
      ),
      child: const Text('Gratuito',
        style: TextStyle(
          color: Color(0xFF27AE60), fontSize: 9, letterSpacing: 0.5)),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> opciones;
  final ValueChanged<String?> onSelected;
  const _FiltroChip({
    required this.label, required this.value,
    required this.opciones, required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final activo = value != null;
    return GestureDetector(
      onTap: () => _mostrarOpciones(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo
              ? const Color(0xFFC9A84C).withAlpha(38)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo
                ? const Color(0xFFC9A84C).withAlpha(150)
                : const Color(0xFF2A2A2A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(activo ? value! : label,
              style: TextStyle(
                color: activo
                    ? const Color(0xFFC9A84C)
                    : const Color(0xFF888888),
                fontSize: 12)),
            const SizedBox(width: 4),
            Icon(
              activo ? Icons.close : Icons.keyboard_arrow_down,
              color: activo
                  ? const Color(0xFFC9A84C)
                  : const Color(0xFF666666),
              size: 14),
          ],
        ),
      ),
    );
  }

  void _mostrarOpciones(BuildContext context) {
    if (value != null) { onSelected(null); return; }
    if (opciones.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(label,
            style: const TextStyle(
              color: Color(0xFFF0E8D8), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...opciones.map((op) => ListTile(
            title: Text(op,
              style: const TextStyle(color: Color(0xFFCCCCCC))),
            onTap: () { Navigator.pop(context); onSelected(op); },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ToggleFiltroGroup extends StatelessWidget {
  final List<String> opciones;
  final List<bool> activos;
  final void Function(int) onTap;
  const _ToggleFiltroGroup({
    required this.opciones, required this.activos, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(opciones.length, (i) {
          final activo = activos[i];
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: activo
                    ? const Color(0xFFC9A84C).withAlpha(38)
                    : Colors.transparent,
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(20) : Radius.zero,
                  right: i == opciones.length - 1
                      ? const Radius.circular(20) : Radius.zero),
                border: Border(
                  left: i > 0
                      ? const BorderSide(color: Color(0xFF2A2A2A))
                      : BorderSide.none),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (activo) ...[
                    const Icon(Icons.check, size: 12, color: Color(0xFFC9A84C)),
                    const SizedBox(width: 4),
                  ],
                  Text(opciones[i],
                    style: TextStyle(
                      color: activo
                          ? const Color(0xFFC9A84C)
                          : const Color(0xFF888888),
                      fontSize: 12)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
