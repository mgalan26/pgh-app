import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/theme.dart';
import 'package:pgh_app/core/router.dart';

class CuentaScreen extends ConsumerStatefulWidget {
  const CuentaScreen({super.key});

  @override
  ConsumerState<CuentaScreen> createState() => _CuentaScreenState();
}

class _CuentaScreenState extends ConsumerState<CuentaScreen> {
  bool _cargando  = true;
  bool _guardando = false;

  String _email      = '';
  String _nombre     = '';
  String _apellido   = '';

  final _telefonoCtrl  = TextEditingController();
  final _profesionCtrl = TextEditingController();
  final _ciudadCtrl    = TextEditingController();
  final _direccionCtrl = TextEditingController();
  String? _pais;

  List<Map<String, dynamic>> _temas               = [];
  final Set<String>          _temasSeleccionados  = {};
  List<Map<String, dynamic>> _ponentes             = [];
  final Set<String>          _ponentesFavoritos   = {};

  static const _paises = [
    'Afganistán', 'Albania', 'Alemania', 'Andorra', 'Angola',
    'Antigua y Barbuda', 'Arabia Saudita', 'Argelia', 'Argentina', 'Armenia',
    'Australia', 'Austria', 'Azerbaiyán',
    'Bahamas', 'Bangladés', 'Barbados', 'Baréin', 'Bélgica', 'Belice',
    'Benín', 'Bielorrusia', 'Birmania', 'Bolivia', 'Bosnia y Herzegovina',
    'Botsuana', 'Brasil', 'Brunéi', 'Bulgaria', 'Burkina Faso', 'Burundi',
    'Bután',
    'Cabo Verde', 'Camboya', 'Camerún', 'Canadá', 'Catar', 'Chad', 'Chile',
    'China', 'Chipre', 'Colombia', 'Comoras', 'Congo', 'Corea del Norte',
    'Corea del Sur', 'Costa de Marfil', 'Costa Rica', 'Croacia', 'Cuba',
    'Dinamarca', 'Dominica',
    'Ecuador', 'Egipto', 'El Salvador', 'Emiratos Árabes Unidos', 'Eritrea',
    'Eslovaquia', 'Eslovenia', 'España', 'Estados Unidos', 'Estonia',
    'Etiopía', 'Esuatini',
    'Filipinas', 'Finlandia', 'Fiyi', 'Francia',
    'Gabón', 'Gambia', 'Georgia', 'Ghana', 'Granada', 'Grecia', 'Guatemala',
    'Guinea', 'Guinea Ecuatorial', 'Guinea-Bisáu', 'Guyana',
    'Haití', 'Honduras', 'Hungría',
    'India', 'Indonesia', 'Irak', 'Irán', 'Irlanda', 'Islandia',
    'Islas Marshall', 'Islas Salomón', 'Israel', 'Italia',
    'Jamaica', 'Japón', 'Jordania',
    'Kazajistán', 'Kenia', 'Kirguistán', 'Kiribati', 'Kuwait',
    'Laos', 'Lesoto', 'Letonia', 'Líbano', 'Liberia', 'Libia',
    'Liechtenstein', 'Lituania', 'Luxemburgo',
    'Madagascar', 'Malaui', 'Maldivas', 'Malasia', 'Malí', 'Malta',
    'Marruecos', 'Mauricio', 'Mauritania', 'México', 'Micronesia', 'Moldavia',
    'Mónaco', 'Mongolia', 'Montenegro', 'Mozambique',
    'Namibia', 'Nauru', 'Nepal', 'Nicaragua', 'Níger', 'Nigeria', 'Noruega',
    'Nueva Zelanda',
    'Omán',
    'Países Bajos', 'Pakistán', 'Palaos', 'Palestina', 'Panamá',
    'Papúa Nueva Guinea', 'Paraguay', 'Perú', 'Polonia', 'Portugal',
    'Puerto Rico',
    'Reino Unido', 'República Centroafricana', 'República Checa',
    'República del Congo', 'República Democrática del Congo',
    'República Dominicana', 'Ruanda', 'Rumanía', 'Rusia',
    'Samoa', 'San Cristóbal y Nieves', 'San Marino', 'San Vicente y las Granadinas',
    'Santa Lucía', 'Santo Tomé y Príncipe', 'Senegal', 'Serbia',
    'Seychelles', 'Sierra Leona', 'Singapur', 'Siria', 'Somalia',
    'Sri Lanka', 'Sudáfrica', 'Sudán', 'Sudán del Sur', 'Suecia', 'Suiza',
    'Surinam',
    'Tailandia', 'Tanzania', 'Tayikistán', 'Timor Oriental', 'Togo', 'Tonga',
    'Trinidad y Tobago', 'Túnez', 'Turkmenistán', 'Turquía', 'Tuvalu',
    'Ucrania', 'Uganda', 'Uruguay', 'Uzbekistán',
    'Vanuatu', 'Venezuela', 'Vietnam',
    'Yemen', 'Yibuti',
    'Zambia', 'Zimbabue',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _profesionCtrl.dispose();
    _ciudadCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final sb   = Supabase.instance.client;
    final user = sb.auth.currentUser;
    if (user == null) {
      if (mounted) context.go(AppRoutes.agenda);
      return;
    }

    _email = user.email ?? '';
    final meta = user.userMetadata ?? {};

    try {
      // 1. Cargar o crear registro en usuarios
      var row = await sb
          .from('usuarios')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) {
        await sb.from('usuarios').insert({
          'id':       user.id,
          'nombre':   meta['nombre'] as String? ?? meta['name'] as String? ?? '',
          'apellido': meta['apellido'] as String? ?? '',
          'email':    _email,
          'activo':   true,
          'email_verificado':       user.emailConfirmedAt != null,
          'acepta_comunicaciones':  false,
        });
        row = await sb.from('usuarios').select().eq('id', user.id).maybeSingle();
      }

      if (row != null) {
        _nombre            = row['nombre']            as String? ?? '';
        _apellido          = row['apellido']           as String? ?? '';
        _telefonoCtrl.text = row['telefono_whatsapp']  as String? ?? '';
        _profesionCtrl.text= row['profesion']           as String? ?? '';
        _ciudadCtrl.text   = row['ciudad']              as String? ?? '';
        _direccionCtrl.text= row['direccion']            as String? ?? '';
        final paisDb = row['pais'] as String?;
        if (paisDb != null && _paises.contains(paisDb)) _pais = paisDb;
      }

      // 2. Cargar temas disponibles
      final temasData = await sb
          .from('temas')
          .select('id, nombre, slug, orden')
          .order('orden', ascending: true);
      _temas = List<Map<String, dynamic>>.from(temasData as List);

      // Temas del usuario
      final userTemas = await sb
          .from('usuario_temas')
          .select('tema_id')
          .eq('usuario_id', user.id);
      for (final t in userTemas as List) {
        _temasSeleccionados.add(t['tema_id'] as String);
      }

      // 3. Cargar ponentes
      final ponentesData = await sb
          .from('ponentes')
          .select('id, nombre, apellido, cargo, foto_url')
          .order('apellido', ascending: true);
      _ponentes = List<Map<String, dynamic>>.from(ponentesData as List);

      // Favoritos del usuario
      final favData = await sb
          .from('usuario_ponentes_favoritos')
          .select('ponente_id')
          .eq('usuario_id', user.id);
      for (final f in favData as List) {
        _ponentesFavoritos.add(f['ponente_id'] as String);
      }
    } catch (e) {
      if (mounted) _snack('Error al cargar datos: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    final sb   = Supabase.instance.client;
    final user = sb.auth.currentUser;
    if (user == null) return;

    setState(() => _guardando = true);
    try {
      await sb.from('usuarios').update({
        'telefono_whatsapp': _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
        'profesion':         _profesionCtrl.text.trim().isEmpty ? null : _profesionCtrl.text.trim(),
        'ciudad':            _ciudadCtrl.text.trim().isEmpty ? null : _ciudadCtrl.text.trim(),
        'pais':              _pais,
        'direccion':         _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
      }).eq('id', user.id);

      // Temas: borrar y reinsertar
      await sb.from('usuario_temas').delete().eq('usuario_id', user.id);
      if (_temasSeleccionados.isNotEmpty) {
        await sb.from('usuario_temas').insert(
          _temasSeleccionados.map((temaId) => {
            'usuario_id': user.id,
            'tema_id':    temaId,
          }).toList(),
        );
      }

      if (mounted) _snack('Perfil guardado', isError: false);
    } catch (e) {
      if (mounted) _snack('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _toggleFavorito(String ponenteId) async {
    final sb   = Supabase.instance.client;
    final user = sb.auth.currentUser;
    if (user == null) return;

    final esFav = _ponentesFavoritos.contains(ponenteId);
    setState(() {
      if (esFav) {
        _ponentesFavoritos.remove(ponenteId);
      } else {
        _ponentesFavoritos.add(ponenteId);
      }
    });
    try {
      if (esFav) {
        await sb.from('usuario_ponentes_favoritos')
            .delete()
            .eq('usuario_id', user.id)
            .eq('ponente_id', ponenteId);
      } else {
        await sb.from('usuario_ponentes_favoritos').insert({
          'usuario_id': user.id,
          'ponente_id': ponenteId,
        });
      }
    } catch (e) {
      setState(() {
        if (esFav) {
          _ponentesFavoritos.add(ponenteId);
        } else {
          _ponentesFavoritos.remove(ponenteId);
        }
      });
      if (mounted) _snack('Error: $e');
    }
  }

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go(AppRoutes.agenda);
  }

  void _snack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : AppTheme.goldColor,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.goldColor)),
      );
    }

    final nombreCompleto = [_nombre, _apellido].where((s) => s.isNotEmpty).join(' ');
    final src     = nombreCompleto.isNotEmpty ? nombreCompleto : _email;
    final inicial = src.isNotEmpty ? src[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        title: const Text('Mi cuenta',
            style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go(AppRoutes.agenda),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [

          // ── Perfil básico ──────────────────────────────────────────────────
          _seccion('Perfil', [
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.goldColor.withAlpha(40),
                child: Text(inicial,
                    style: const TextStyle(
                        color: AppTheme.goldColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            if (nombreCompleto.isNotEmpty) ...[
              Center(
                child: Text(nombreCompleto,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
            ],
            Center(
              child: Text(_email,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ),
          ]),

          // ── Datos de contacto (CRM) ────────────────────────────────────────
          _seccion('Datos de contacto', [
            _campo(_telefonoCtrl, 'Teléfono / WhatsApp',
                hint: '+34 600 000 000',
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _campo(_profesionCtrl, 'Profesión',
                hint: 'Ej: Abogado, Periodista…'),
            const SizedBox(height: 12),
            _campo(_ciudadCtrl, 'Ciudad', hint: 'Ej: Madrid'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _pais,
              decoration: const InputDecoration(labelText: 'País'),
              dropdownColor: AppTheme.darkCard,
              style: const TextStyle(color: AppTheme.textPrimary),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('— Selecciona —')),
                ..._paises.map((p) =>
                    DropdownMenuItem<String>(value: p, child: Text(p))),
              ],
              onChanged: (v) => setState(() => _pais = v),
            ),
            const SizedBox(height: 12),
            _campo(_direccionCtrl, 'Dirección completa',
                hint: 'Calle, número, piso…', maxLines: 2),
          ]),

          // ── Temas de interés ───────────────────────────────────────────────
          _seccion('Temas de interés', [
            if (_temas.isEmpty)
              const Text('No hay temas disponibles',
                  style: TextStyle(color: AppTheme.textMuted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _temas.map((t) {
                  final id       = t['id'] as String;
                  final nombre   = t['nombre'] as String? ?? '';
                  final selected = _temasSeleccionados.contains(id);
                  return FilterChip(
                    label: Text(nombre,
                        style: TextStyle(
                            color: selected
                                ? AppTheme.goldColor
                                : AppTheme.textSecondary,
                            fontSize: 12)),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _temasSeleccionados.add(id);
                      } else {
                        _temasSeleccionados.remove(id);
                      }
                    }),
                    selectedColor: AppTheme.goldColor.withAlpha(50),
                    checkmarkColor: AppTheme.goldColor,
                    backgroundColor: AppTheme.darkCard,
                    side: BorderSide(
                        color: selected
                            ? AppTheme.goldColor.withAlpha(150)
                            : AppTheme.darkBorder),
                  );
                }).toList(),
              ),
          ]),

          // ── Ponentes favoritos ─────────────────────────────────────────────
          _seccion('Ponentes favoritos', [
            if (_ponentes.isEmpty)
              const Text('No hay ponentes disponibles',
                  style: TextStyle(color: AppTheme.textMuted))
            else
              ..._ponentes.map((p) {
                final id      = p['id'] as String;
                final nombre  = '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'.trim();
                final cargo   = p['cargo'] as String?;
                final fotoUrl = p['foto_url'] as String?;
                final esFav   = _ponentesFavoritos.contains(id);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: fotoUrl != null && fotoUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(fotoUrl,
                              width: 40, height: 40, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _avatarInicial(nombre)))
                      : _avatarInicial(nombre),
                  title: Text(nombre,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14)),
                  subtitle: cargo != null
                      ? Text(cargo,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12))
                      : null,
                  trailing: IconButton(
                    icon: Icon(
                      esFav ? Icons.favorite : Icons.favorite_border,
                      color: esFav ? Colors.redAccent : AppTheme.textMuted,
                      size: 22,
                    ),
                    onPressed: () => _toggleFavorito(id),
                  ),
                );
              }),
          ]),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.darkBg))
                  : const Text('Guardar cambios'),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cerrarSesion,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _seccion(String titulo, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 28),
      Text(titulo,
          style: const TextStyle(
              color: AppTheme.goldColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8)),
      const SizedBox(height: 4),
      const Divider(color: AppTheme.darkBorder, height: 1),
      const SizedBox(height: 14),
      ...children,
    ],
  );

  Widget _campo(
    TextEditingController ctrl,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label, hintText: hint),
      );

  Widget _avatarInicial(String nombre) => Container(
    width: 40, height: 40,
    decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF222222)),
    child: Center(
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w600),
      ),
    ),
  );
}
