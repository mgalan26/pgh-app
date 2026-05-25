class Entidad {
  final String id;
  final String nombre;
  final String? descripcion;
  final String tipo;
  final String pais;
  final String? ciudad;
  final String? direccion;
  final String? telefono;
  final String? web;
  final String? emailPublico;
  final String? linkedinUrl;
  final String? instagramUrl;
  final String? twitterUrl;
  final bool verificada;
  final bool activa;
  final DateTime createdAt;
  final String? logoUrl;
  final List<EntidadImagen> imagenes;

  const Entidad({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.tipo,
    required this.pais,
    this.ciudad,
    this.direccion,
    this.telefono,
    this.web,
    this.emailPublico,
    this.linkedinUrl,
    this.instagramUrl,
    this.twitterUrl,
    required this.verificada,
    required this.activa,
    required this.createdAt,
    this.logoUrl,
    this.imagenes = const [],
  });

  factory Entidad.fromJson(Map<String, dynamic> json) => Entidad(
    id:           json['id'],
    nombre:       json['nombre'],
    descripcion:  json['descripcion'],
    tipo:         json['tipo'],
    pais:         json['pais'],
    ciudad:       json['ciudad'],
    direccion:    json['direccion'],
    telefono:     json['telefono'],
    web:          json['web'],
    emailPublico: json['email_publico'],
    linkedinUrl:  json['linkedin_url'],
    instagramUrl: json['instagram_url'],
    twitterUrl:   json['twitter_url'],
    verificada:   json['verificada'] ?? false,
    activa:       json['activa'] ?? true,
    createdAt:    DateTime.parse(json['created_at']),
    logoUrl:      json['logo_url'],
  );
}


class Venue {
  final String id;
  final String nombre;
  final String? direccion;
  final String ciudad;
  final String pais;
  final String? urlMapa;
  final String? web;

  const Venue({
    required this.id,
    required this.nombre,
    this.direccion,
    required this.ciudad,
    required this.pais,
    this.urlMapa,
    this.web,
  });

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
    id:        json['id'],
    nombre:    json['nombre'],
    direccion: json['direccion'],
    ciudad:    json['ciudad'],
    pais:      json['pais'],
    urlMapa:   json['url_mapa'],
    web:       json['web'],
  );

  String get direccionCompleta =>
      [direccion, ciudad, pais]
        .where((e) => e != null && e.isNotEmpty)
        .join(', ');
}

class Ponente {
  final String id;
  final String nombre;
  final String apellido;
  final String? cargo;
  final String? organizacion;
  final String? bio;
  final String? fotoUrl;
  final String? linkedinUrl;
  final String? web;
  final DateTime createdAt;
  final String? rolEnEvento;
  final int ordenEnEvento;
  final String? usuarioId;

  const Ponente({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.cargo,
    this.organizacion,
    this.bio,
    this.fotoUrl,
    this.linkedinUrl,
    this.web,
    required this.createdAt,
    this.rolEnEvento,
    this.ordenEnEvento = 0,
    this.usuarioId,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory Ponente.fromJson(Map<String, dynamic> json) => Ponente(
    id:            json['id'],
    nombre:        json['nombre'],
    apellido:      json['apellido'],
    cargo:         json['cargo'],
    organizacion:  json['organizacion'],
    bio:           json['bio'],
    fotoUrl:       json['foto_url'],
    linkedinUrl:   json['linkedin_url'],
    web:           json['web'],
    createdAt:     DateTime.parse(json['created_at']),
    rolEnEvento:   json['rol'],
    ordenEnEvento: json['orden'] ?? 0,
    usuarioId:     json['usuario_id'],
  );
}

enum EstadoEvento { borrador, pendiente, publicado, rechazado, cancelado }
enum TipoEvento {
  conferencia, mesaRedonda, congreso, networking,
  cultural, academico, empresarial, politico, exposicion, otro
}

class Evento {
  final String id;
  final String organizadorId;
  final String entidadId;
  final String? coorganizadorNombre;
  final String? coorganizadorWeb;
  final String nombre;
  final String? descripcion;
  final String? venueId;
  final String? venueNombreLibre;
  final String pais;
  final String ciudad;
  final bool tienePresencial;
  final bool tieneStreaming;
  final String? urlOnline;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? horaInicio;
  final String? horaFin;
  final TipoEvento tipo;
  final bool esGratuito;
  final String? urlReserva;
  final String? emailContacto;
  final String? enlaceWeb;
  final EstadoEvento estado;
  final String? notaModeracion;
  final int visitas;
  final DateTime createdAt;
  final String? portadaUrl;
  final String? ponenteId;
  final Ponente? ponente;
  final List<EventoImagen> imagenes;
  final List<Ponente> ponentes;
  final Venue? venue;
  final String? entidadNombre;
  final String? entidadLogoUrl;
  final bool entidadVerificada;

  const Evento({
    required this.id,
    required this.organizadorId,
    required this.entidadId,
    this.coorganizadorNombre,
    this.coorganizadorWeb,
    required this.nombre,
    this.descripcion,
    this.venueId,
    this.venueNombreLibre,
    required this.pais,
    required this.ciudad,
    required this.tienePresencial,
    required this.tieneStreaming,
    this.urlOnline,
    required this.fechaInicio,
    this.fechaFin,
    this.horaInicio,
    this.horaFin,
    required this.tipo,
    required this.esGratuito,
    this.urlReserva,
    this.emailContacto,
    this.enlaceWeb,
    required this.estado,
    this.notaModeracion,
    required this.visitas,
    required this.createdAt,
    this.portadaUrl,
    this.imagenes = const [],
    this.ponenteId,
    this.ponente,
    this.ponentes = const [],
    this.venue,
    this.entidadNombre,
    this.entidadLogoUrl,
    this.entidadVerificada = false,
  });

  bool get isMultidia =>
      fechaFin != null && fechaFin!.isAfter(fechaInicio);

  String get modalidadLabel {
    if (tienePresencial && tieneStreaming) return 'Presencial + Streaming';
    if (tieneStreaming) return 'Online';
    return 'Presencial';
  }

  String get venueNombre =>
      venue?.nombre ?? venueNombreLibre ?? ciudad;

  factory Evento.fromJson(Map<String, dynamic> json) => Evento(
    id:                  json['id'],
    organizadorId:       json['organizador_id'],
    entidadId:           json['entidad_id'],
    coorganizadorNombre: json['coorganizador_nombre'],
    coorganizadorWeb:    json['coorganizador_web'],
    nombre:              json['nombre'],
    descripcion:         json['descripcion'],
    venueId:             json['venue_id'],
    venueNombreLibre:    json['venue_nombre_libre'],
    pais:                json['pais'],
    ciudad:              json['ciudad'],
    tienePresencial:     json['tiene_presencial'] ?? true,
    tieneStreaming:      json['tiene_streaming'] ?? false,
    urlOnline:           json['url_online'],
    fechaInicio:         DateTime.parse(json['fecha_inicio']),
    fechaFin:            json['fecha_fin'] != null
                           ? DateTime.parse(json['fecha_fin'])
                           : null,
    horaInicio:          json['hora_inicio'],
    horaFin:             json['hora_fin'],
    tipo:                _parseTipo(json['tipo']),
    esGratuito:          json['es_gratuito'] ?? true,
    urlReserva:          json['url_reserva'],
    emailContacto:       json['email_contacto'],
    enlaceWeb:           json['enlace_web'],
    estado:              EstadoEvento.values.byName(json['estado']),
    notaModeracion:      json['nota_moderacion'],
    visitas:             json['visitas'] ?? 0,
    createdAt:           DateTime.parse(json['created_at']),
    portadaUrl:          json['portada_url'],
    ponenteId:           json['ponente_id'],
    ponente:             json['ponentes'] != null
                           ? Ponente.fromJson(json['ponentes'])
                           : null,
    entidadNombre:       json['entidad_nombre'],
    entidadLogoUrl:      json['entidad_logo_url'],
    entidadVerificada:   json['entidad_verificada'] ?? false,
  );

  static TipoEvento _parseTipo(String? tipo) {
    const map = {
      'Conferencia':  TipoEvento.conferencia,
      'Mesa redonda': TipoEvento.mesaRedonda,
      'Congreso':     TipoEvento.congreso,
      'Networking':   TipoEvento.networking,
      'Cultural':     TipoEvento.cultural,
      'Académico':    TipoEvento.academico,
      'Empresarial':  TipoEvento.empresarial,
      'Político':     TipoEvento.politico,
      'Exposición':   TipoEvento.exposicion,
    };
    return map[tipo] ?? TipoEvento.otro;
  }
}

class EntidadImagen {
  final String id;
  final String entidadId;
  final String storagePath;
  final String url;
  final String tipo;
  final String? descripcion;
  final int orden;

  const EntidadImagen({
    required this.id,
    required this.entidadId,
    required this.storagePath,
    required this.url,
    required this.tipo,
    this.descripcion,
    required this.orden,
  });

  factory EntidadImagen.fromJson(Map<String, dynamic> json) => EntidadImagen(
    id:          json['id'],
    entidadId:   json['entidad_id'],
    storagePath: json['storage_path'],
    url:         json['url'],
    tipo:        json['tipo'],
    descripcion: json['descripcion'],
    orden:       json['orden'] ?? 0,
  );
}

class EventoImagen {
  final String id;
  final String eventoId;
  final String storagePath;
  final String url;
  final String tipo;
  final String? descripcion;
  final int orden;

  const EventoImagen({
    required this.id,
    required this.eventoId,
    required this.storagePath,
    required this.url,
    required this.tipo,
    this.descripcion,
    required this.orden,
  });

  factory EventoImagen.fromJson(Map<String, dynamic> json) => EventoImagen(
    id:          json['id'],
    eventoId:    json['evento_id'],
    storagePath: json['storage_path'],
    url:         json['url'],
    tipo:        json['tipo'],
    descripcion: json['descripcion'],
    orden:       json['orden'] ?? 0,
  );
}

class Usuario {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final bool activo;
  final bool emailVerificado;
  final bool aceptaComunicaciones;
  final DateTime createdAt;
  final DateTime? ultimoAcceso;
  final List<Tema> temas;
  // CRM fields
  final String? telefonoWhatsapp;
  final String? profesion;
  final String? ciudad;
  final String? pais;
  final String? direccion;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.activo,
    required this.emailVerificado,
    required this.aceptaComunicaciones,
    required this.createdAt,
    this.ultimoAcceso,
    this.temas = const [],
    this.telefonoWhatsapp,
    this.profesion,
    this.ciudad,
    this.pais,
    this.direccion,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id:                   json['id'],
    nombre:               json['nombre'] ?? '',
    apellido:             json['apellido'] ?? '',
    email:                json['email'] ?? '',
    activo:               json['activo'] ?? true,
    emailVerificado:      json['email_verificado'] ?? false,
    aceptaComunicaciones: json['acepta_comunicaciones'] ?? false,
    createdAt:            DateTime.parse(json['created_at']),
    ultimoAcceso:         json['ultimo_acceso'] != null
                            ? DateTime.parse(json['ultimo_acceso'])
                            : null,
    telefonoWhatsapp:     json['telefono_whatsapp'],
    profesion:            json['profesion'],
    ciudad:               json['ciudad'],
    pais:                 json['pais'],
    direccion:            json['direccion'],
  );
}

class Tema {
  final String id;
  final String nombre;
  final String slug;
  final int orden;

  const Tema({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.orden,
  });

  factory Tema.fromJson(Map<String, dynamic> json) => Tema(
    id:     json['id'],
    nombre: json['nombre'],
    slug:   json['slug'],
    orden:  json['orden'] ?? 0,
  );
}
