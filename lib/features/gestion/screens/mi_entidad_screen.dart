import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/models/models.dart';
import 'package:pgh_app/core/providers/auth_provider.dart';
import 'package:pgh_app/core/theme.dart';
import 'package:pgh_app/core/widgets/logo_upload_button.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final miEntidadProvider = FutureProvider.autoDispose<Entidad?>((ref) async {
  final org = await ref.watch(organizadorProvider.future);
  if (org == null) return null;

  final data = await Supabase.instance.client
      .from('entidades')
      .select()
      .eq('id', org.entidadId)
      .maybeSingle();

  if (data == null) return null;
  return Entidad.fromJson(data);
});

// ─── Constantes ───────────────────────────────────────────────────────────────

const _tiposEntidad = [
  'Asociación',
  'Fundación',
  'Empresa',
  'Instituto',
  'Universidad',
  'ONG',
  'Partido político',
  'Administración pública',
  'Otro',
];

const _paises = [
  'Argentina', 'Bolivia', 'Chile', 'Colombia', 'Costa Rica', 'Cuba',
  'Ecuador', 'El Salvador', 'España', 'Guatemala', 'Honduras', 'México',
  'Nicaragua', 'Panamá', 'Paraguay', 'Perú', 'Puerto Rico',
  'República Dominicana', 'Uruguay', 'Venezuela',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class MiEntidadScreen extends ConsumerWidget {
  const MiEntidadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(miEntidadProvider);

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.goldColor),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
      data: (entidad) {
        if (entidad == null) {
          return const Scaffold(
            backgroundColor: AppTheme.darkBg,
            body: Center(
              child: Text('No se encontró la entidad',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
          );
        }
        return _EntidadBody(entidad: entidad, ref: ref);
      },
    );
  }
}

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _EntidadBody extends StatelessWidget {
  final Entidad entidad;
  final WidgetRef ref;
  const _EntidadBody({required this.entidad, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        automaticallyImplyLeading: false,
        title: const Text('Mi Entidad'),
        actions: [
          TextButton.icon(
            onPressed: () => _abrirEdicion(context),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Editar'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.goldColor),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          if (entidad.descripcion?.isNotEmpty == true) ...[
            _buildSeccion('Descripción', [
              Text(entidad.descripcion!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.6)),
            ]),
            const SizedBox(height: 20),
          ],
          _buildSeccion('Información', [
            _buildFila(Icons.category_outlined, 'Tipo', entidad.tipo),
            _buildFila(Icons.flag_outlined, 'País', entidad.pais),
            if (entidad.ciudad?.isNotEmpty == true)
              _buildFila(Icons.location_city_outlined, 'Ciudad', entidad.ciudad!),
            if (entidad.direccion?.isNotEmpty == true)
              _buildFila(Icons.place_outlined, 'Dirección', entidad.direccion!),
          ]),
          const SizedBox(height: 20),
          _buildSeccion('Contacto', [
            if (entidad.emailPublico?.isNotEmpty == true)
              _buildFila(Icons.email_outlined, 'Email', entidad.emailPublico!),
            if (entidad.telefono?.isNotEmpty == true)
              _buildFila(Icons.phone_outlined, 'Teléfono', entidad.telefono!),
            if (entidad.web?.isNotEmpty == true)
              _buildFila(Icons.language_outlined, 'Web', entidad.web!),
            if (entidad.emailPublico == null &&
                entidad.telefono == null &&
                entidad.web == null)
              const Text('Sin datos de contacto',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ]),
          if (entidad.linkedinUrl?.isNotEmpty == true ||
              entidad.instagramUrl?.isNotEmpty == true ||
              entidad.twitterUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            _buildSeccion('Redes sociales', [
              if (entidad.linkedinUrl?.isNotEmpty == true)
                _buildFila(Icons.link, 'LinkedIn', entidad.linkedinUrl!),
              if (entidad.instagramUrl?.isNotEmpty == true)
                _buildFila(Icons.camera_alt_outlined, 'Instagram', entidad.instagramUrl!),
              if (entidad.twitterUrl?.isNotEmpty == true)
                _buildFila(Icons.alternate_email, 'Twitter / X', entidad.twitterUrl!),
            ]),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: entidad.logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    entidad.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.business, color: AppTheme.textMuted, size: 28),
                  ),
                )
              : const Icon(Icons.business, color: AppTheme.textMuted, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(entidad.nombre,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                ),
                if (entidad.verificada)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.verified,
                        color: AppTheme.goldColor, size: 18),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(entidad.tipo,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 13)),
              if (!entidad.activa) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Inactiva',
                      style:
                          TextStyle(color: Colors.redAccent, fontSize: 11)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildFila(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 15),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 2),
              Text(valor,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _abrirEdicion(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EntidadEditSheet(
        entidad: entidad,
        onGuardado: () => ref.invalidate(miEntidadProvider),
      ),
    );
  }
}

// ─── Modal edición ────────────────────────────────────────────────────────────

class _EntidadEditSheet extends StatefulWidget {
  final Entidad entidad;
  final VoidCallback onGuardado;
  const _EntidadEditSheet(
      {required this.entidad, required this.onGuardado});

  @override
  State<_EntidadEditSheet> createState() => _EntidadEditSheetState();
}

class _EntidadEditSheetState extends State<_EntidadEditSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _nombreCtrl      = TextEditingController(text: widget.entidad.nombre);
  late final _descripcionCtrl = TextEditingController(text: widget.entidad.descripcion);
  late final _ciudadCtrl      = TextEditingController(text: widget.entidad.ciudad);
  late final _direccionCtrl   = TextEditingController(text: widget.entidad.direccion);
  late final _telefonoCtrl    = TextEditingController(text: widget.entidad.telefono);
  late final _webCtrl         = TextEditingController(text: widget.entidad.web);
  late final _emailCtrl       = TextEditingController(text: widget.entidad.emailPublico);
  late final _linkedinCtrl    = TextEditingController(text: widget.entidad.linkedinUrl);
  late final _instagramCtrl   = TextEditingController(text: widget.entidad.instagramUrl);
  late final _twitterCtrl     = TextEditingController(text: widget.entidad.twitterUrl);

  late String? _logoUrl = widget.entidad.logoUrl;
  late String? _tipo = widget.entidad.tipo.isNotEmpty ? widget.entidad.tipo : null;
  late String? _pais = widget.entidad.pais.isNotEmpty ? widget.entidad.pais : null;

  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _descripcionCtrl, _ciudadCtrl, _direccionCtrl,
      _telefonoCtrl, _webCtrl, _emailCtrl,
      _linkedinCtrl, _instagramCtrl, _twitterCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await Supabase.instance.client.from('entidades').update({
        'nombre':       _nombreCtrl.text.trim(),
        'descripcion':  _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        'tipo':         _tipo,
        'pais':         _pais,
        'ciudad':       _ciudadCtrl.text.trim().isEmpty ? null : _ciudadCtrl.text.trim(),
        'direccion':    _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
        'telefono':     _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
        'web':          _webCtrl.text.trim().isEmpty ? null : _webCtrl.text.trim(),
        'email_publico': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'logo_url':     _logoUrl,
        'linkedin_url': _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
        'instagram_url': _instagramCtrl.text.trim().isEmpty ? null : _instagramCtrl.text.trim(),
        'twitter_url':  _twitterCtrl.text.trim().isEmpty ? null : _twitterCtrl.text.trim(),
      }).eq('id', widget.entidad.id);

      if (mounted) {
        Navigator.pop(context);
        widget.onGuardado();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Perfil actualizado ✓'),
          backgroundColor: AppTheme.goldColor,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
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
              // Cabecera del sheet
              Row(children: [
                const Expanded(
                  child: Text('Editar perfil de entidad',
                      style: TextStyle(
                          color: AppTheme.goldColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Identidad ──────────────────────────────────────────────
              _label('IDENTIDAD'),
              const SizedBox(height: 10),
              _tf(_nombreCtrl, 'Nombre de la entidad *',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre es obligatorio'
                      : null),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de entidad *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                isExpanded: true,
                items: _tiposEntidad
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v),
                validator: (v) => v == null ? 'Selecciona un tipo' : null,
              ),
              const SizedBox(height: 10),
              _tf(_descripcionCtrl, 'Descripción',
                  hint: 'Breve descripción de la entidad y su misión…',
                  maxLines: 4),
              const SizedBox(height: 16),
              _label('LOGOTIPO'),
              const SizedBox(height: 10),
              Row(children: [
                LogoUploadButton(
                  currentUrl: _logoUrl,
                  storagePath: 'entidades/${widget.entidad.id}',
                  size: 90,
                  onUploaded: (url) => setState(() => _logoUrl = url),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Pulsa la imagen para seleccionar un archivo desde tu dispositivo.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5),
                  ),
                ),
              ]),

              const SizedBox(height: 20),
              // ── Ubicación ──────────────────────────────────────────────
              _label('UBICACIÓN'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _paises.contains(_pais) ? _pais : null,
                decoration: const InputDecoration(labelText: 'País *'),
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                isExpanded: true,
                items: _paises
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _pais = v),
                validator: (v) => v == null ? 'Selecciona un país' : null,
              ),
              const SizedBox(height: 10),
              _tf(_ciudadCtrl, 'Ciudad', hint: 'Ej: Madrid'),
              const SizedBox(height: 10),
              _tf(_direccionCtrl, 'Dirección', hint: 'Ej: Calle Mayor 1, 1º izq.'),

              const SizedBox(height: 20),
              // ── Contacto ───────────────────────────────────────────────
              _label('CONTACTO'),
              const SizedBox(height: 10),
              _tf(_emailCtrl, 'Email público', hint: 'info@entidad.org',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _tf(_telefonoCtrl, 'Teléfono', hint: '+34 600 000 000',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              _tf(_webCtrl, 'Página web', hint: 'https://...',
                  keyboardType: TextInputType.url),

              const SizedBox(height: 20),
              // ── Redes sociales ─────────────────────────────────────────
              _label('REDES SOCIALES'),
              const SizedBox(height: 10),
              _tf(_linkedinCtrl, 'LinkedIn URL',
                  hint: 'https://linkedin.com/company/...',
                  keyboardType: TextInputType.url),
              const SizedBox(height: 10),
              _tf(_instagramCtrl, 'Instagram URL',
                  hint: 'https://instagram.com/...',
                  keyboardType: TextInputType.url),
              const SizedBox(height: 10),
              _tf(_twitterCtrl, 'Twitter / X URL',
                  hint: 'https://x.com/...',
                  keyboardType: TextInputType.url),

              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.darkBg))
                    : const Text('Guardar cambios'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.w600));

  Widget _tf(
    TextEditingController ctrl,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator,
        onChanged: onChanged,
      );
}
