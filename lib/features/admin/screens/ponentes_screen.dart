import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/models/models.dart';
import 'package:pgh_app/core/theme.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final adminPonentesProvider =
    FutureProvider.autoDispose<List<Ponente>>((ref) async {
  final data = await Supabase.instance.client
      .from('ponentes')
      .select()
      .order('apellido', ascending: true);
  return (data as List).map((e) => Ponente.fromJson(e)).toList();
});

// ─── Lista de ponentes ────────────────────────────────────────────────────────

class PonentesScreen extends ConsumerWidget {
  const PonentesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPonentesProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Ponentes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/organizadores'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminPonentesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context, ref, ponente: null),
        backgroundColor: AppTheme.goldColor,
        foregroundColor: AppTheme.darkBg,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo ponente'),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.goldColor)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.redAccent))),
        data: (ponentes) {
          if (ponentes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined,
                      color: AppTheme.textMuted, size: 48),
                  const SizedBox(height: 12),
                  const Text('No hay ponentes registrados',
                      style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _abrirFormulario(context, ref, ponente: null),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Añadir el primero'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: ponentes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) =>
                _PonenteTile(ponente: ponentes[i], ref: ref),
          );
        },
      ),
    );
  }

  static Future<void> _abrirFormulario(
    BuildContext context,
    WidgetRef ref, {
    required Ponente? ponente,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PonenteForms(ponente: ponente),
    );
    ref.invalidate(adminPonentesProvider);
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _PonenteTile extends StatelessWidget {
  final Ponente ponente;
  final WidgetRef ref;
  const _PonenteTile({required this.ponente, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.goldColor.withAlpha(40),
          backgroundImage:
              ponente.fotoUrl != null ? NetworkImage(ponente.fotoUrl!) : null,
          child: ponente.fotoUrl == null
              ? Text(
                  ponente.nombre[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.goldColor, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          ponente.nombreCompleto,
          style: const TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: ponente.cargo != null || ponente.organizacion != null
            ? Text(
                [ponente.cargo, ponente.organizacion]
                    .where((e) => e != null)
                    .join(' · '),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.goldColor, size: 20),
              onPressed: () => PonentesScreen._abrirFormulario(
                context, ref,
                ponente: ponente,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: () => _confirmarBorrar(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarBorrar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Eliminar ponente',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '¿Eliminar a ${ponente.nombreCompleto}? Los eventos que lo tengan asignado perderán esa asignación.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Supabase.instance.client
        .from('ponentes')
        .delete()
        .eq('id', ponente.id);
    ref.invalidate(adminPonentesProvider);
  }
}

// ─── Formulario (crear / editar) ──────────────────────────────────────────────

class _PonenteForms extends StatefulWidget {
  final Ponente? ponente;
  const _PonenteForms({required this.ponente});

  @override
  State<_PonenteForms> createState() => _PonenteForms_State();
}

class _PonenteForms_State extends State<_PonenteForms> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl       = TextEditingController(text: widget.ponente?.nombre);
  late final _apellidoCtrl     = TextEditingController(text: widget.ponente?.apellido);
  late final _cargoCtrl        = TextEditingController(text: widget.ponente?.cargo);
  late final _organizacionCtrl = TextEditingController(text: widget.ponente?.organizacion);
  late final _bioCtrl          = TextEditingController(text: widget.ponente?.bio);
  late final _fotoUrlCtrl      = TextEditingController(text: widget.ponente?.fotoUrl);
  late final _linkedinCtrl     = TextEditingController(text: widget.ponente?.linkedinUrl);
  late final _webCtrl          = TextEditingController(text: widget.ponente?.web);
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _apellidoCtrl, _cargoCtrl, _organizacionCtrl,
      _bioCtrl, _fotoUrlCtrl, _linkedinCtrl, _webCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final payload = {
        'nombre':       _nombreCtrl.text.trim(),
        'apellido':     _apellidoCtrl.text.trim(),
        'cargo':        _cargoCtrl.text.trim().isEmpty ? null : _cargoCtrl.text.trim(),
        'organizacion': _organizacionCtrl.text.trim().isEmpty ? null : _organizacionCtrl.text.trim(),
        'bio':          _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'foto_url':     _fotoUrlCtrl.text.trim().isEmpty ? null : _fotoUrlCtrl.text.trim(),
        'linkedin_url': _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
        'web':          _webCtrl.text.trim().isEmpty ? null : _webCtrl.text.trim(),
      };
      final sb = Supabase.instance.client;
      if (widget.ponente == null) {
        await sb.from('ponentes').insert(payload);
      } else {
        await sb.from('ponentes').update(payload).eq('id', widget.ponente!.id);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.ponente == null ? 'Nuevo ponente' : 'Editar ponente',
                style: const TextStyle(
                  color: AppTheme.goldColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _tf(_nombreCtrl, 'Nombre *',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Obligatorio' : null)),
                const SizedBox(width: 10),
                Expanded(child: _tf(_apellidoCtrl, 'Apellido *',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Obligatorio' : null)),
              ]),
              const SizedBox(height: 10),
              _tf(_cargoCtrl, 'Cargo'),
              const SizedBox(height: 10),
              _tf(_organizacionCtrl, 'Organización'),
              const SizedBox(height: 10),
              _tf(_bioCtrl, 'Bio', maxLines: 3),
              const SizedBox(height: 10),
              _tf(_fotoUrlCtrl, 'URL foto', hint: 'https://...'),
              const SizedBox(height: 10),
              _tf(_linkedinCtrl, 'LinkedIn URL', hint: 'https://linkedin.com/in/...'),
              const SizedBox(height: 10),
              _tf(_webCtrl, 'Web personal', hint: 'https://...'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.darkBg))
                    : Text(widget.ponente == null ? 'Crear ponente' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(
    TextEditingController ctrl,
    String label, {
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator,
      );
}
