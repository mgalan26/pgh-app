import 'package:pgh_app/core/models/models.dart';

final mockEntidades = [
  Entidad(
    id: 'ent-1',
    nombre: 'A.C. Héroes de Cavite',
    descripcion:
        'Asociación cultural dedicada a la defensa y difusión de la historia '
        'y cultura hispana. Organiza conferencias, ciclos de charlas y '
        'actividades educativas en Madrid y otras ciudades de España.',
    tipo: 'asociacion',
    pais: 'España',
    ciudad: 'Madrid',
    telefono: '641 39 68 08',
    web: 'https://heroesdecavite.es',
    verificada: true,
    activa: true,
    createdAt: DateTime(2025, 1, 1),
  ),
  Entidad(
    id: 'ent-2',
    nombre: 'MUCAIN — Museo Carrera de Indias',
    descripcion:
        'Innovador espacio virtual inaugurado en 2021 para dar a conocer '
        'la importancia de la Carrera de Indias, verdadero nexo del mundo '
        'hispánico.',
    tipo: 'museo',
    pais: 'España',
    ciudad: 'Madrid',
    web: 'https://mucain.com',
    verificada: true,
    activa: true,
    createdAt: DateTime(2025, 1, 1),
  ),
  Entidad(
    id: 'ent-3',
    nombre: 'Parlamento Global Hispano',
    descripcion:
        'Organización que representa y moviliza al mundo hispanohablante — '
        '600 millones de personas — como fuerza civilizatoria, económica '
        'y política coherente.',
    tipo: 'asociacion',
    pais: 'España',
    ciudad: 'Madrid',
    web: 'https://www.appgh.net',
    linkedinUrl: 'https://linkedin.com/company/parlamento-global-hispano',
    verificada: true,
    activa: true,
    createdAt: DateTime(2024, 1, 1),
  ),
];

final mockVenues = [
  Venue(
    id: 'venue-1',
    nombre: 'Centro Cívico Zigia 28',
    direccion: 'C/ Zigia 28',
    ciudad: 'Madrid',
    pais: 'España',
    urlMapa: 'https://maps.google.com/?q=Calle+Zigia+28+Madrid',
    web: 'http://www.zigia28.es',
  ),
  Venue(
    id: 'venue-2',
    nombre: 'Centro Municipal de Mayores Antonio Somalo',
    direccion: 'Avda. Labradores 24, 28760 Tres Cantos',
    ciudad: 'Tres Cantos',
    pais: 'España',
    urlMapa: 'https://maps.google.com/?q=Avenida+Labradores+24+Tres+Cantos',
  ),
  Venue(
    id: 'venue-3',
    nombre: 'Ateneo de Madrid',
    direccion: 'C/ del Prado 21',
    ciudad: 'Madrid',
    pais: 'España',
    urlMapa: 'https://maps.google.com/?q=Ateneo+de+Madrid',
    web: 'https://www.ateneodemadrid.com',
  ),
];

final _cesarPerezGuevara = Ponente(
  id: 'pon-1',
  nombre: 'César',
  apellido: 'Pérez Guevara',
  cargo: 'Historiador y coordinador de Visiones',
  organizacion: 'Parlamento Global Hispano',
  bio: 'Historiador y coordinador del ciclo Visiones de la Civilización Hispana. '
      'Especialista en patrimonio hispano y divulgación histórica.',
  fotoUrl: 'asset:assets/ponentes/cesar_perez_guevara.jpg',
  createdAt: DateTime(2025, 1, 1),
);

final _ricardoFernandez = Ponente(
  id: 'pon-2',
  nombre: 'Ricardo',
  apellido: 'Fernández',
  cargo: 'Presidente de MUCAIN',
  organizacion: 'MUCAIN',
  bio: 'Presidente del Museo de la Carrera de Indias. Especialista en la '
      'historia del comercio transatlántico hispano.',
  createdAt: DateTime(2025, 1, 1),
);

final _rafaCodes = Ponente(
  id: 'pon-3',
  nombre: 'Rafa',
  apellido: 'Codes',
  cargo: 'Escritor y divulgador',
  bio: 'Escritor y divulgador especializado en historia de España '
      'y el mundo hispano.',
  createdAt: DateTime(2025, 1, 1),
);

final _armandoJimenez = Ponente(
  id: 'pon-4',
  nombre: 'Armando',
  apellido: 'Jiménez San Vicente',
  cargo: 'Investigador en Stanford University',
  organizacion: 'Stanford University',
  bio: 'Investigador en Stanford especializado en historia del derecho '
      'y pensamiento político hispano. Experto en la Escuela de Salamanca.',
  createdAt: DateTime(2025, 1, 1),
);

final _alfonsoCardena = Ponente(
  id: 'pon-5',
  nombre: 'Alfonso',
  apellido: 'Cardeña',
  cargo: 'Coordinador HdC Villa-Madrid',
  organizacion: 'A.C. Héroes de Cavite',
  bio: 'Coordinador de la delegación de Héroes de Cavite en Madrid.',
  createdAt: DateTime(2025, 1, 1),
);

final _almirante = Ponente(
  id: 'pon-6',
  nombre: 'José Ángel',
  apellido: 'Sande Cortizo',
  cargo: 'Almirante (R)',
  organizacion: 'Armada Española',
  bio: 'Almirante en la reserva. Experto en historia naval española '
      'y las campañas militares del siglo XVIII.',
  createdAt: DateTime(2025, 1, 1),
);

final _porConfirmar = Ponente(
  id: 'pon-7',
  nombre: 'Por',
  apellido: 'Confirmar',
  cargo: 'Pendiente de confirmación',
  createdAt: DateTime(2025, 1, 1),
);

final mockPonentes = [
  _cesarPerezGuevara,
  _ricardoFernandez,
  _rafaCodes,
  _armandoJimenez,
  _alfonsoCardena,
  _almirante,
];

Ponente _conRol(Ponente p, String rol, int orden) => Ponente(
  id: p.id, nombre: p.nombre, apellido: p.apellido,
  cargo: p.cargo, organizacion: p.organizacion,
  bio: p.bio, fotoUrl: p.fotoUrl,
  linkedinUrl: p.linkedinUrl, web: p.web,
  createdAt: p.createdAt,
  rolEnEvento: rol, ordenEnEvento: orden,
);

final mockEventos = [
  Evento(
    id: 'evt-vis-1',
    organizadorId: 'org-3',
    entidadId: 'ent-3',
    nombre: 'El Patrimonio de la Humanidad Hispano',
    descripcion:
        'El mundo hispano tiene 90 sitios Patrimonio de la Humanidad '
        'reconocidos por la UNESCO. El doble que Francia. El triple que el '
        'Reino Unido. En tres continentes — Europa, América y Asia. '
        'Desde el acueducto de Segovia hasta la Sagrada Família. '
        'Una civilización que no acampó — que construyó para quedarse.',
    pais: 'España',
    ciudad: 'Madrid',
    tienePresencial: true,
    tieneStreaming: true,
    urlOnline: 'https://www.appgh.net/visiones',
    fechaInicio: DateTime(2026, 4, 22),
    horaInicio: '19:00',
    horaFin: '21:00',
    tipo: TipoEvento.conferencia,
    esGratuito: false,
    urlReserva: 'https://www.appgh.net/visiones',
    enlaceWeb: 'https://www.appgh.net/visiones',
    estado: EstadoEvento.publicado,
    visitas: 0,
    createdAt: DateTime(2026, 3, 1),
    venue: mockVenues[2],
    entidadNombre: 'Parlamento Global Hispano',
    entidadVerificada: true,
    ponentes: [_conRol(_cesarPerezGuevara, 'Ponente', 0)],
  ),
  Evento(
    id: 'evt-vis-2',
    organizadorId: 'org-3',
    entidadId: 'ent-3',
    nombre: 'La Carrera de Indias',
    descripcion:
        'Durante tres siglos, entre 1503 y 1778, la Carrera de Indias fue '
        'el sistema logístico más ambicioso que la humanidad había construido. '
        'No fue solo comercio: fue la primera infraestructura global de la historia. '
        'El antecedente directo de lo que hoy llamamos globalización.',
    pais: 'España',
    ciudad: 'Madrid',
    tienePresencial: true,
    tieneStreaming: true,
    urlOnline: 'https://www.appgh.net/visiones',
    fechaInicio: DateTime(2026, 5, 20),
    horaInicio: '19:00',
    horaFin: '21:00',
    tipo: TipoEvento.conferencia,
    esGratuito: false,
    urlReserva: 'https://www.appgh.net/visiones',
    enlaceWeb: 'https://www.appgh.net/visiones',
    estado: EstadoEvento.publicado,
    visitas: 0,
    createdAt: DateTime(2026, 3, 1),
    venue: mockVenues[2],
    entidadNombre: 'Parlamento Global Hispano',
    entidadVerificada: true,
    ponentes: [_conRol(_ricardoFernandez, 'Ponente', 0)],
  ),
  Evento(
    id: 'evt-vis-3',
    organizadorId: 'org-3',
    entidadId: 'ent-3',
    nombre: 'El Galeón de Manila',
    descripcion:
        'En 1565, Andrés de Urdaneta descubrió la ruta del tornaviaje. '
        'Durante 250 años, el Galeón de Manila conectó Asia, América y Europa '
        'en una sola ruta comercial. La seda china llegaba a México. '
        'La plata de Potosí llegaba a China. Tres civilizaciones, un sistema.',
    pais: 'España',
    ciudad: 'Madrid',
    tienePresencial: true,
    tieneStreaming: true,
    urlOnline: 'https://www.appgh.net/visiones',
    fechaInicio: DateTime(2026, 6, 25),
    horaInicio: '19:00',
    horaFin: '21:00',
    tipo: TipoEvento.conferencia,
    esGratuito: false,
    urlReserva: 'https://www.appgh.net/visiones',
    enlaceWeb: 'https://www.appgh.net/visiones',
    estado: EstadoEvento.publicado,
    visitas: 0,
    createdAt: DateTime(2026, 3, 1),
    venue: mockVenues[2],
    entidadNombre: 'Parlamento Global Hispano',
    entidadVerificada: true,
    ponentes: [_conRol(_rafaCodes, 'Ponente', 0)],
  ),
  Evento(
    id: 'evt-vis-4',
    organizadorId: 'org-3',
    entidadId: 'ent-3',
    nombre: 'La Escuela de Salamanca y el Derecho Internacional',
    descripcion:
        'Francisco de Vitoria y los juristas de la Escuela de Salamanca '
        'construyeron los fundamentos del derecho internacional en el siglo XVI. '
        'Hugo Grocio, considerado su padre, bebió directamente de ellos. '
        'El mundo jurídico moderno tiene raíces hispanas que casi nadie conoce.',
    pais: 'España',
    ciudad: 'Madrid',
    tienePresencial: true,
    tieneStreaming: true,
    urlOnline: 'https://www.appgh.net/visiones',
    fechaInicio: DateTime(2026, 7, 23),
    horaInicio: '19:00',
    horaFin: '21:00',
    tipo: TipoEvento.conferencia,
    esGratuito: false,
    urlReserva: 'https://www.appgh.net/visiones',
    enlaceWeb: 'https://www.appgh.net/visiones',
    estado: EstadoEvento.publicado,
    visitas: 0,
    createdAt: DateTime(2026, 3, 1),
    venue: mockVenues[2],
    entidadNombre: 'Parlamento Global Hispano',
    entidadVerificada: true,
    ponentes: [_conRol(_armandoJimenez, 'Ponente', 0)],
  ),
  Evento(
    id: 'evt-vis-5',
    organizadorId: 'org-3',
    entidadId: 'ent-3',
    nombre: 'Las Ciudades Hispanas: Urbanismo a 4.000 Metros',
    descripcion:
        'Tenochtitlán, Cuzco, Potosí, Lima — ciudades de cientos de miles '
        'de habitantes a 4.000 metros de altitud, con universidades, hospitales '
        'y gobierno municipal. La urbanización de América fue el mayor proyecto '
        'de ingeniería civil del siglo XVI.',
    pais: 'España',
    ciudad: 'Madrid',
    tienePresencial: true,
    tieneStreaming: true,
    urlOnline: 'https://www.appgh.net/visiones',
    fechaInicio: DateTime(2026, 9, 17),
    horaInicio: '19:00',
    horaFin: '21:00',
    tipo: TipoEvento.conferencia,
    esGratuito: false,
    urlReserva: 'https://www.appgh.net/visiones',
    enlaceWeb: 'https://www.appgh.net/visiones',
    estado: EstadoEvento.publicado,
    visitas: 0,
    createdAt: DateTime(2026, 3, 1),
    venue: mockVenues[2],
    entidadNombre: 'Parlamento Global Hispano',
    entidadVerificada: true,
    ponentes: [_conRol(_porConfirmar, 'Ponente', 0)],
  ),
  Evento(
    id: 'evt-vis-6',
    organizadorId: 'org-3',
    entidadId: 'ent-3',
    nombre: 'El Español: La Lengua que Construyó un Mundo',
    descripcion:
        '600 millones de hispanohablantes. Segunda lengua más hablada del mundo '
        'en número de hablantes nativos. El español no es solo un idioma — '
        'es la infraestructura de comunicación de una civilización. '
        'Conferencia de cierre del ciclo Visiones, Día de la Hispanidad.',
    pais: 'España',
    ciudad: 'Madrid',
    tienePresencial: true,
    tieneStreaming: true,
    urlOnline: 'https://www.appgh.net/visiones',
    fechaInicio: DateTime(2026, 10, 12),
    horaInicio: '19:00',
    horaFin: '21:00',
    tipo: TipoEvento.conferencia,
    esGratuito: false,
    urlReserva: 'https://www.appgh.net/visiones',
    enlaceWeb: 'https://www.appgh.net/visiones',
    estado: EstadoEvento.publicado,
    visitas: 0,
    createdAt: DateTime(2026, 3, 1),
    venue: mockVenues[2],
    entidadNombre: 'Parlamento Global Hispano',
    entidadVerificada: true,
    ponentes: [_conRol(_cesarPerezGuevara, 'Ponente', 0)],
  ),
  Evento(
    id: 'evt-hdc-1',
    organizadorId: 'org-1',
    entidadId: 'ent-1',
    nombre: 'Balmis e Isabel Zendal: la primera expedición sanitaria global',
    descripcion:
        'La Real Expedición Filantrópica de la Vacuna (1803–1806) fue la primera '
        'misión humanitaria global de la historia. La Corona española llevó la '
        'vacuna contra la viruela a América, Asia y África.',
    pais: 'España',
    ciudad: 'Tres Cantos',
    tienePresencial: true,
    tieneStreaming: false,
    fechaInicio: DateTime(2026, 4, 22),
    horaInicio: '11:30',
    tipo: TipoEvento.conferencia,
    esGratuito: true,
    enlaceWeb: 'https://heroesdecavite.es',
    estado: EstadoEvento.publicado,
    visitas: 0,
    createdAt: DateTime(2026, 4, 1),
    venue: mockVenues[1],
    entidadNombre: 'A.C. Héroes de Cavite',
    entidadVerificada: true,
    ponentes: [
      _conRol(_rafaCodes, 'Ponente', 0),
      _conRol(_alfonsoCardena, 'Moderador', 1),
    ],
  ),
  Evento(
    id: 'evt-hdc-2',
    organizadorId: 'org-1',
    entidadId: 'ent-1',
    nombre: 'España Siglo XVIII: El Caribe y las 13 Colonias de Norteamérica',
    descripcion:
        'Lezo-Cartagena de Indias 1741 y Gálvez-Pensacola 1781. '
        'El papel determinante de España en el nacimiento de los Estados Unidos, '
        'borrado sistemáticamente por la historiografía anglosajona.',
    pais: 'España',
    ciudad: 'Madrid',
    tienePresencial: true,
    tieneStreaming: false,
    fechaInicio: DateTime(2026, 4, 29),
    horaInicio: '19:00',
    tipo: TipoEvento.conferencia,
    esGratuito: true,
    emailContacto: '641396808',
    enlaceWeb: 'https://heroesdecavite.es',
    estado: EstadoEvento.publicado,
    visitas: 0,
    createdAt: DateTime(2026, 4, 1),
    venue: mockVenues[0],
    entidadNombre: 'A.C. Héroes de Cavite',
    entidadVerificada: true,
    ponentes: [
      _conRol(_almirante, 'Ponente', 0),
      _conRol(_alfonsoCardena, 'Moderador', 1),
    ],
  ),
  Evento(
    id: 'evt-mucain-1',
    organizadorId: 'org-2',
    entidadId: 'ent-2',
    nombre: 'Exposición Virtual: El Padrón Real',
    descripcion:
        'El Padrón Real fue el mapa secreto de la Corona española: '
        'la carta náutica maestra custodiada en la Casa de Contratación de Sevilla. '
        'El activo estratégico más valioso del Imperio, ahora en el museo virtual MUCAIN.',
    pais: 'España',
    ciudad: 'Madrid',
    tienePresencial: false,
    tieneStreaming: true,
    urlOnline: 'https://mucain.com/en-los-astilleros/',
    fechaInicio: DateTime(2026, 5, 1),
    fechaFin: DateTime(2026, 7, 31),
    tipo: TipoEvento.exposicion,
    esGratuito: true,
    enlaceWeb: 'https://mucain.com',
    estado: EstadoEvento.publicado,
    visitas: 0,
    createdAt: DateTime(2026, 4, 1),
    venueNombreLibre: 'Museo Virtual MUCAIN',
    entidadNombre: 'MUCAIN — Museo Carrera de Indias',
    entidadVerificada: true,
    ponentes: [],
  ),
];
