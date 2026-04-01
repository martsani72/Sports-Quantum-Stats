import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =====================================================================
// PERSISTENCIA DE DATOS
// =====================================================================
class QuantumStorage {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static Future<void> guardarPerfil(Map<String, dynamic> perfil) async {
    await prefs.setString('perfil_usuario', jsonEncode(perfil));
  }

  static Map<String, dynamic> cargarPerfil() {
    String? data = prefs.getString('perfil_usuario');
    if (data == null) {
      return {
        'nombre': '',
        'medio': '',
        'redSocial': '',
        'usarFirma': true,
        'deporteDefecto': '',
        'idioma': 'Español' 
      };
    }
    return jsonDecode(data);
  }
}

late Map<String, dynamic> perfilUsuario;

// =====================================================================
// SISTEMA DE IDIOMAS (TRADUCTOR)
// =====================================================================
class Traductor {
  static final Map<String, Map<String, String>> _diccionario = {
    'Español': {
      'menu_1': '1 - Iniciar un encuentro',
      'menu_2': '2 - Encuentros Personalizados',
      'menu_3': '3 - Estadísticas',
      'menu_4': '4 - Configuraciones',
      'menu_5': '5 - Mi cuenta',
      'menu_6': '6 - Encuentros guardados',
      'en_construccion': 'Sección en construcción',
      'titulo_config': 'CONFIGURACIONES',
      'preferencias': 'PREFERENCIAS',
      'idioma': 'Idioma',
      'idioma_app': 'IDIOMA DE LA APP',
      'Fútbol': 'Fútbol',
      'Rugby': 'Rugby',
      'Basketball': 'Básquet',
      'Baseball': 'Béisbol',
      'Football Americano': 'Fútbol Americano',
      'parametros': 'PARÁMETROS',
      'eventos_reg': 'EVENTOS REGISTRABLES',
      'modo_edicion': 'MODO EDICIÓN HABILITADO',
      'jugadores_colores': 'EQUIPOS Y COLORES',
      'planilla': 'PLANILLA',
      'confirmar': 'OK',
      'editar': 'EDITAR',
      'cancelar': 'CANCELAR',
      'agregar_estadistica': 'AGREGAR ESTADÍSTICA PERSONALIZADA',
    },
    'English': {
      'menu_1': '1 - Start a match',
      'menu_2': '2 - Custom Matches',
      'menu_3': '3 - Statistics',
      'menu_4': '4 - Settings',
      'menu_5': '5 - My Account',
      'menu_6': '6 - Saved Matches',
      'en_construccion': 'Under construction',
      'titulo_config': 'SETTINGS',
      'preferencias': 'PREFERENCES',
      'idioma': 'Language',
      'idioma_app': 'APP LANGUAGE',
      'Fútbol': 'Soccer',
      'Rugby': 'Rugby',
      'Basketball': 'Basketball',
      'Baseball': 'Baseball',
      'Football Americano': 'American Football',
      'parametros': 'PARAMETERS',
      'eventos_reg': 'TRACKABLE EVENTS',
      'modo_edicion': 'EDIT MODE ENABLED',
      'jugadores_colores': 'TEAMS & COLORS',
      'planilla': 'ROSTER',
      'confirmar': 'CONFIRM',
      'editar': 'EDIT',
      'cancelar': 'CANCEL',
      'agregar_estadistica': 'ADD CUSTOM STATISTIC',
    },
    'Português': {
      'menu_1': '1 - Iniciar uma partida',
      'menu_2': '2 - Partidas Personalizadas',
      'menu_3': '3 - Estatísticas',
      'menu_4': '4 - Configurações',
      'menu_5': '5 - Minha Conta',
      'menu_6': '6 - Partidas Salvas',
      'en_construccion': 'Em construção',
      'titulo_config': 'CONFIGURAÇÕES',
      'preferencias': 'PREFERÊNCIAS',
      'idioma': 'Idioma',
      'idioma_app': 'IDIOMA DO APP',
      'Fútbol': 'Futebol',
      'Rugby': 'Rugby',
      'Basketball': 'Basquete',
      'Baseball': 'Beisebol',
      'Football Americano': 'Futebol Americano',
      'parametros': 'PARÂMETROS',
      'eventos_reg': 'EVENTOS REGISTRÁVEIS',
      'modo_edicion': 'MODO DE EDIÇÃO ATIVADO',
      'jugadores_colores': 'EQUIPES E CORES',
      'planilla': 'ESCALAÇÃO',
      'confirmar': 'OK',
      'editar': 'EDITAR',
      'cancelar': 'CANCELAR',
      'agregar_estadistica': 'ADICIONAR ESTATÍSTICA',
    }
  };

  static String get(String clave) {
    String idiomaActual = perfilUsuario['idioma'] ?? 'Español';
    return _diccionario[idiomaActual]?[clave] ?? clave;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuantumStorage.init();
  perfilUsuario = QuantumStorage.cargarPerfil();

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PantallaPrincipal(),
  ));
}

// =====================================================================
// ESTÉTICA QUANTUM
// =====================================================================
const Color kNegro = Colors.black;
const Color kVerdeNeon = Color(0xFF00FF41);
const Color kVerdeOscuro = Color(0xFF003B00);
const Color kCelestePlay = Color(0xFF00BFFF); 
const Color kRojoStop = Color(0xFFFF3333);   
const Color kAmarilloTarjeta = Color(0xFFFFEA00);

// =====================================================================
// BASE DE DATOS Y MODELOS
// =====================================================================
List<Partido> partidosGuardados = [];
List<Partido> parametrosGuardados = []; 

enum PatronCamiseta {
  liso,              
  franjaHorizontal,  
  bandaDiagonal,     
  mitades,           
  rayasVerticales,   
  rayasHorizontales  
}

class Partido {
  final String deporte;
  final String local;
  final String visita;
  final Map<String, int> contadores;
  final Map<String, bool> switches;
  
  final Color localFondo;
  final Color localTexto;
  final Color visitaFondo;
  final Color visitaTexto;
  
  final Map<String, String> jugadoresLocal;
  final Map<String, String> jugadoresVisita;

  final PatronCamiseta patronLocal;
  final PatronCamiseta patronVisita;

  Map<String, Map<String, int>> stats = {
    'Local': {},
    'Visita': {},
  };
  
  Map<String, List<Map<String, String>>> anotaciones = {
    'Local': [],
    'Visita': [],
  };

  Map<String, List<Map<String, String>>> tarjetas = {
    'Local': [],
    'Visita': [],
  };

  Map<String, List<Map<String, String>>> cambiosList = {
    'Local': [],
    'Visita': [],
  };
  
  List<String> logEventos = [];
  late List<String> ordenEventosActivos;

  Partido({
    required this.deporte, required this.local, required this.visita,
    required this.contadores, required this.switches,
    this.localFondo = kNegro, this.localTexto = kVerdeNeon,
    this.visitaFondo = kNegro, this.visitaTexto = Colors.redAccent,
    this.jugadoresLocal = const {}, this.jugadoresVisita = const {},
    this.patronLocal = PatronCamiseta.liso,
    this.patronVisita = PatronCamiseta.liso,
  }) {
    for (String evento in switches.keys) {
      if (switches[evento] == true) {
        stats['Local']![evento] = 0;
        stats['Visita']![evento] = 0;
      }
    }
    stats['Local']!['CambiosHechos'] = 0;
    stats['Visita']!['CambiosHechos'] = 0;
    stats['Local']!['VentanasHechas'] = 0;
    stats['Visita']!['VentanasHechas'] = 0;
    
    ordenEventosActivos = switches.entries.where((e) => e.value).map((e) => e.key).toList();
    logEventos.add('--- INICIO DEL ENCUENTRO: $local vs $visita ---');
  }

  String obtenerNombreJugador(String equipo, String numero) {
    if (numero == '?') return 'N°?';
    Map<String, String> planilla = equipo == 'Local' ? jugadoresLocal : jugadoresVisita;
    if (planilla.containsKey(numero)) {
      return '$numero ${planilla[numero]}'; 
    }
    return 'N°$numero'; 
  }

  int obtenerPuntaje(String equipo) {
    int total = 0;
    stats[equipo]!.forEach((key, value) {
      String kLower = key.toLowerCase();
      if (kLower.contains('gol') || kLower.contains('carrera') || kLower.contains('pt') || kLower.contains('try')) {
        int multiplicador = 1; 
        RegExp exp = RegExp(r'\((\d+)\s*pt');
        Match? match = exp.firstMatch(key);
        if (match != null) {
          multiplicador = int.parse(match.group(1)!);
        }
        total += (value * multiplicador);
      }
    });
    return total;
  }
}

class DeporteConfig {
  static final Map<String, Map<String, dynamic>> datos = {
    'Fútbol': {
      'icono': Icons.sports_soccer,
      'contadores': {'Tiempos': 2, 'Minutos': 45, 'Cambios': 5, 'Ventanas': 3},
      'limites': {'Tiempos': 9, 'Minutos': 99, 'Cambios': 9, 'Ventanas': 9},
      'switches': {'Gol': true, 'Remates': true, 'Remates al arco': true, 'Asistencia': true, 'Corner': true, 'Falta': true, 'Tarjeta Amarilla': true, 'Tarjeta Roja': true, 'Tarjeta Verde': true, 'Cambio': true},
    },
    'Rugby': {
      'icono': Icons.sports_rugby,
      'contadores': {'Tiempos': 2, 'Minutos': 40, 'Cambios': 8, 'Min. Amarilla': 10},
      'limites': {'Tiempos': 4, 'Minutos': 99, 'Cambios': 15, 'Min. Amarilla': 10},
      'switches': {'Try (5 pts)': true, 'Conversión (2 pts)': true, 'Penal (3 pts)': true, 'Drop (3 pts)': true, 'Penal': true, 'Line Out': true, 'Tarjeta Amarilla': true, 'Tarjeta Roja': true, 'Scrum': true, 'Cambio': true},
    },
    'Basketball': {
      'icono': Icons.sports_basketball,
      'contadores': {'Cuartos': 4, 'Minutos': 10, 'Tiempos Muertos': 6},
      'limites': {'Cuartos': 9, 'Minutos': 99, 'Tiempos Muertos': 9},
      'switches': {'Tiro Libre (1 pt)': true, 'Doble (2 pts)': true, 'Triple (3 pts)': true, 'Rebotes': true, 'Tapones': true, 'Falta Personal': true, 'Falta Técnica': true, 'Cambio': true},
    },
    'Baseball': {
      'icono': Icons.sports_baseball,
      'contadores': {'Entradas': 9},
      'limites': {'Entradas': 99},
      'switches': {'Carrera': true, 'Hit': true, 'Error': true, 'Ponche': true, 'Home Run': true, 'Cambio': true},
    },
    'Football Americano': {
      'icono': Icons.sports_football,
      'contadores': {'Cuartos': 4, 'Minutos': 15, 'Tiempos Muertos': 6},
      'limites': {'Cuartos': 9, 'Minutos': 99, 'Tiempos Muertos': 9},
      'switches': {'Touchdown (6 pts)': true, 'Field Goal (3 pts)': true, 'Extra Point (1 pt)': true, 'Safety (2 pts)': true, 'Castigo': true, 'Cambio': true},
    },
  };
}

// =====================================================================
// 1. PANTALLA PRINCIPAL
// =====================================================================
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});
  @override State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  @override Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opcionesMenu = [
      {'titulo': Traductor.get('menu_1'), 'icono': Icons.play_arrow, 'ruta': const PantallaSeleccionDeporte()},
      {'titulo': '${Traductor.get('menu_2')} (${parametrosGuardados.length})', 'icono': Icons.dashboard_customize, 'ruta': const PantallaEncuentrosPersonalizados()},
      {'titulo': Traductor.get('menu_3'), 'icono': Icons.bar_chart, 'ruta': const PantallaEstadisticas()},
      {'titulo': Traductor.get('menu_4'), 'icono': Icons.settings, 'ruta': const PantallaConfiguraciones()},
      {'titulo': Traductor.get('menu_5'), 'icono': Icons.person, 'ruta': const PantallaMiCuenta()},
      {'titulo': '${Traductor.get('menu_6')} (${partidosGuardados.length})', 'icono': Icons.save, 'ruta': const PantallaEncuentrosGuardados()}, 
    ];

    return Scaffold(
      backgroundColor: kNegro,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('QUANTUM', style: TextStyle(color: kVerdeOscuro, fontSize: 14, letterSpacing: 8)),
              const Text('REFEREE', style: TextStyle(color: kVerdeNeon, fontSize: 38, fontWeight: FontWeight.bold, shadows: [Shadow(color: kVerdeNeon, blurRadius: 10)])),
              const SizedBox(height: 40),
              ...opcionesMenu.map((op) => _buildBotonMenu(context, op)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonMenu(BuildContext context, Map op) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          if (op['ruta'] != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => op['ruta'])).then((_) => setState((){}));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Traductor.get('en_construccion'))));
          }
        },
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(border: Border.all(color: kVerdeNeon.withOpacity(0.4)), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(op['icono'], color: kVerdeNeon, size: 20),
            const SizedBox(width: 12),
            Text(op['titulo'].toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontWeight: FontWeight.bold, fontSize: 12)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: kVerdeNeon, size: 18),
          ]),
        ),
      ),
    );
  }
}

// =====================================================================
// 2. SELECCIÓN DE DEPORTE
// =====================================================================
class PantallaSeleccionDeporte extends StatelessWidget {
  const PantallaSeleccionDeporte({super.key});
  @override Widget build(BuildContext context) {
    final List<String> deportesKeys = DeporteConfig.datos.keys.toList();
    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(backgroundColor: kNegro, leading: IconButton(icon: const Icon(Icons.arrow_back, color: kVerdeNeon), onPressed: () => Navigator.pop(context))),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: deportesKeys.length,
        itemBuilder: (context, index) {
          String nombreInterno = deportesKeys[index]; 
          var data = DeporteConfig.datos[nombreInterno]!;
          String nombreTraducido = Traductor.get(nombreInterno); 

          return Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: ListTile(
              shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeOscuro), borderRadius: BorderRadius.circular(10)),
              leading: Icon(data['icono'], color: kVerdeNeon),
              title: Text("${index + 1} - ${nombreTraducido.toUpperCase()}", style: const TextStyle(color: kVerdeNeon, fontSize: 13)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaConfiguracionDinamica(nombreDeporte: nombreInterno, configInicial: data))),
            ),
          );
        },
      ),
    );
  }
}

// =====================================================================
// 3. CONFIGURACIÓN DINÁMICA
// =====================================================================
class PantallaConfiguracionDinamica extends StatefulWidget {
  final String nombreDeporte;
  final Map<String, dynamic> configInicial;

  const PantallaConfiguracionDinamica({super.key, required this.nombreDeporte, required this.configInicial});

  @override State<PantallaConfiguracionDinamica> createState() => _PantallaConfiguracionDinamicaState();
}

class _PantallaConfiguracionDinamicaState extends State<PantallaConfiguracionDinamica> {
  bool modoEdicion = false;
  late Map<String, int> contadores;
  late Map<String, int> limites;
  late Map<String, bool> switches;

  final TextEditingController _nombreLocalController = TextEditingController();
  final TextEditingController _jugadoresLocalController = TextEditingController();
  final TextEditingController _nombreVisitaController = TextEditingController();
  final TextEditingController _jugadoresVisitaController = TextEditingController();

  Color _localFondo = const Color(0xFF111111);
  Color _localTexto = kVerdeNeon;
  Color _visitaFondo = const Color(0xFF111111);
  Color _visitaTexto = Colors.redAccent;

  PatronCamiseta _patronLocal = PatronCamiseta.liso;
  PatronCamiseta _patronVisita = PatronCamiseta.liso;

  @override
  void initState() {
    super.initState();
    contadores = Map<String, int>.from(widget.configInicial['contadores']);
    limites = Map<String, int>.from(widget.configInicial['limites']);
    switches = Map<String, bool>.from(widget.configInicial['switches']);
  }

  Map<String, String> _parsearPlanilla(String texto) {
    Map<String, String> resultado = {};
    if (texto.trim().isEmpty) return resultado;
    List<String> lineas = texto.split('\n');
    for (String linea in lineas) {
      linea = linea.trim();
      if (linea.isEmpty) continue;
      int primerEspacio = linea.indexOf(' ');
      if (primerEspacio != -1) {
        String numero = linea.substring(0, primerEspacio).trim();
        String nombre = linea.substring(primerEspacio + 1).trim();
        resultado[numero] = nombre;
      } else {
        resultado[linea] = ''; 
      }
    }
    return resultado;
  }

  Future<Color?> _seleccionarColor(BuildContext context) {
    final List<Color> paleta = [
      Colors.black, const Color(0xFF111111), Colors.white, Colors.grey, 
      Colors.red, Colors.blue, const Color(0xFF001F70), 
      Colors.green, Colors.yellow, const Color(0xFFFFD700), 
      Colors.orange, Colors.purple, Colors.cyan, Colors.pink
    ];
    
    return showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: const Text('ELEGIR COLOR', style: TextStyle(color: kVerdeNeon, fontSize: 14)),
        content: Wrap(
          spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
          children: paleta.map((c) => InkWell(
            onTap: () => Navigator.pop(ctx, c),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: c, border: Border.all(color: Colors.white38), shape: BoxShape.circle),
            )
          )).toList()
        )
      )
    );
  }

  Future<PatronCamiseta?> _seleccionarPatron(BuildContext context) {
    final Map<PatronCamiseta, String> opciones = {
      PatronCamiseta.liso: 'Liso (Ej: All Blacks)',
      PatronCamiseta.franjaHorizontal: 'Franja (Ej: Boca)',
      PatronCamiseta.bandaDiagonal: 'Diagonal (Ej: River)',
      PatronCamiseta.mitades: 'Mitades (Ej: Newell\'s)',
      PatronCamiseta.rayasVerticales: 'Bastones (Ej: Estudiantes)',
      PatronCamiseta.rayasHorizontales: 'Rayas Horiz. (Ej: Pumas)',
    };
    
    return showDialog<PatronCamiseta>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: const Text('ELEGIR DISEÑO', style: TextStyle(color: kVerdeNeon, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: opciones.entries.map((e) => ListTile(
            leading: const Icon(Icons.checkroom, color: Colors.white54),
            title: Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 13)),
            onTap: () => Navigator.pop(ctx, e.key),
          )).toList()
        )
      )
    );
  }

  Widget _buildSelectorPatron(String titulo, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: Colors.white10, border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(5)),
            child: const Icon(Icons.checkroom, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(color: Colors.white54, fontSize: 10))
        ],
      ),
    );
  }

  void _mostrarPopUpJugadores() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: kNegro,
              shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon, width: 2), borderRadius: BorderRadius.circular(12)),
              title: const Text('PLANILLA DE EQUIPOS', textAlign: TextAlign.center, style: TextStyle(color: kVerdeNeon, fontSize: 16, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EQUIPO LOCAL', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                      const SizedBox(height: 5),
                      TextField(controller: _nombreLocalController, style: TextStyle(color: _localTexto, fontWeight: FontWeight.bold), decoration: _inputDecoration('Nombre Local...', _localFondo)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSelectorColor('FONDO', _localFondo, () async { Color? c = await _seleccionarColor(context); if (c != null) setStateDialog(() => _localFondo = c); }),
                          _buildSelectorColor('DETALLE', _localTexto, () async { Color? c = await _seleccionarColor(context); if (c != null) setStateDialog(() => _localTexto = c); }),
                          _buildSelectorPatron('DISEÑO', () async { PatronCamiseta? p = await _seleccionarPatron(context); if (p != null) setStateDialog(() => _patronLocal = p); }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(controller: _jugadoresLocalController, maxLines: null, minLines: 3, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _inputDecoration('Ej:\n10 Messi\n9 Benedetto', Colors.transparent)),
                      
                      const SizedBox(height: 25),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 15),
                      
                      const Text('EQUIPO VISITA', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                      const SizedBox(height: 5),
                      TextField(controller: _nombreVisitaController, style: TextStyle(color: _visitaTexto, fontWeight: FontWeight.bold), decoration: _inputDecoration('Nombre Visita...', _visitaFondo)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSelectorColor('FONDO', _visitaFondo, () async { Color? c = await _seleccionarColor(context); if (c != null) setStateDialog(() => _visitaFondo = c); }),
                          _buildSelectorColor('DETALLE', _visitaTexto, () async { Color? c = await _seleccionarColor(context); if (c != null) setStateDialog(() => _visitaTexto = c); }),
                          _buildSelectorPatron('DISEÑO', () async { PatronCamiseta? p = await _seleccionarPatron(context); if (p != null) setStateDialog(() => _patronVisita = p); }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(controller: _jugadoresVisitaController, maxLines: null, minLines: 3, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _inputDecoration('Lista Jugadores...', Colors.transparent)),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(onPressed: () { _nombreLocalController.clear(); _jugadoresLocalController.clear(); _nombreVisitaController.clear(); _jugadoresVisitaController.clear(); }, child: const Text('BORRAR', style: TextStyle(color: Colors.redAccent, fontSize: 12))),
                Row(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('ATRÁS', style: TextStyle(color: Colors.grey, fontSize: 12))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon),
                      onPressed: () { Navigator.pop(context); setState(() {}); },
                      child: const Text('CARGAR', style: TextStyle(color: kNegro, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                )
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildSelectorColor(String titulo, Color colorActual, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: colorActual, border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(color: Colors.white54, fontSize: 10))
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color fillColor) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.white24),
      filled: true, fillColor: fillColor == Colors.transparent ? Colors.white.withOpacity(0.05) : fillColor.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: kVerdeOscuro)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kVerdeNeon)),
    );
  }

  bool _hayEquiposCargados() => _nombreLocalController.text.isNotEmpty || _nombreVisitaController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    String tituloTraducido = "${Traductor.get('parametros')} ${Traductor.get(widget.nombreDeporte)}";

    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        backgroundColor: kNegro, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kVerdeNeon), onPressed: () => Navigator.pop(context)),
        title: Text(tituloTraducido.toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)),
      ),
      body: Column(
        children: [
          if (modoEdicion)
            Container(width: double.infinity, color: kVerdeOscuro.withOpacity(0.5), padding: const EdgeInsets.symmetric(vertical: 5), child: Text(Traductor.get('modo_edicion'), textAlign: TextAlign.center, style: const TextStyle(color: kVerdeNeon, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2))),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildFilaEspecialJugadores(),
                ...contadores.keys.map((key) {
                  if (key == 'Min. Amarilla') return _buildFilaMinutosAmarilla(key);
                  return _buildFilaNumero(key, contadores[key]!, 0, limites[key]!, (val) => setState(() => contadores[key] = val));
                }),
                const Divider(color: kVerdeOscuro, height: 40),
                Text(Traductor.get('eventos_reg'), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
                const SizedBox(height: 10),
                ...switches.keys.map((key) => _buildFilaSwitch(key, switches[key]!, (val) => setState(() => switches[key] = val))),
                
                if (modoEdicion)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0, bottom: 20.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: BorderSide(color: kVerdeNeon.withOpacity(0.5), width: 1.5), minimumSize: const Size(double.infinity, 50), backgroundColor: kVerdeNeon.withOpacity(0.05)),
                      icon: const Icon(Icons.add_circle_outline, color: kVerdeNeon),
                      label: Text(Traductor.get('agregar_estadistica'), style: const TextStyle(color: kVerdeNeon, fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _agregarEventoPersonalizado,
                    ),
                  ),
              ],
            ),
          ),
          
          _buildBotonesAccion(),
        ],
      ),
    );
  }

  Widget _buildFilaEspecialJugadores() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Traductor.get('jugadores_colores'), style: const TextStyle(color: kVerdeNeon, fontSize: 13, fontWeight: FontWeight.w400)),
            if (modoEdicion)
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: kVerdeOscuro, foregroundColor: kVerdeNeon, minimumSize: const Size(100, 35)), icon: const Icon(Icons.palette, size: 16), label: Text(Traductor.get('planilla'), style: const TextStyle(fontSize: 10)), onPressed: _mostrarPopUpJugadores)
            else
              Text(_hayEquiposCargados() ? 'Listas Cargadas' : 'No definidos', style: TextStyle(color: _hayEquiposCargados() ? kVerdeNeon : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaNumero(String label, int valorActual, int min, int max, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 13, fontWeight: FontWeight.w400)),
            if (modoEdicion)
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: kVerdeOscuro), onPressed: valorActual > min ? () => onChanged(valorActual - 1) : null),
                  SizedBox(width: 30, child: Text('$valorActual', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.add_circle_outline, color: kVerdeNeon), onPressed: valorActual < max ? () => onChanged(valorActual + 1) : null),
                ],
              )
            else
              Padding(padding: const EdgeInsets.only(right: 15.0), child: Text('$valorActual', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
  Widget _buildFilaMinutosAmarilla(String label) {
    int valorActual = contadores[label] ?? 10;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TIEMPO AMARILLA', style: TextStyle(color: kVerdeNeon, fontSize: 13, fontWeight: FontWeight.w400)),
            if (modoEdicion)
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('2 MIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    selected: valorActual == 2,
                    selectedColor: kVerdeNeon,
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: kVerdeOscuro),
                    labelStyle: TextStyle(color: valorActual == 2 ? kNegro : Colors.white),
                    onSelected: (val) { if (val) setState(() => contadores[label] = 2); },
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('10 MIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    selected: valorActual == 10,
                    selectedColor: kVerdeNeon,
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: kVerdeOscuro),
                    labelStyle: TextStyle(color: valorActual == 10 ? kNegro : Colors.white),
                    onSelected: (val) { if (val) setState(() => contadores[label] = 10); },
                  ),
                ],
              )
            else
              Padding(padding: const EdgeInsets.only(right: 15.0), child: Text('$valorActual MIN', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaSwitch(String label, bool valorActual, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label.toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 12, fontWeight: FontWeight.w400))),
            if (modoEdicion)
              Switch(value: valorActual, activeColor: kVerdeNeon, inactiveThumbColor: Colors.grey, inactiveTrackColor: Colors.white10, onChanged: onChanged)
            else
              Padding(padding: const EdgeInsets.only(right: 15.0, top: 10, bottom: 10), child: Text(valorActual ? 'SÍ' : 'NO', style: TextStyle(color: valorActual ? Colors.white : Colors.white38, fontSize: 14, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  void _agregarEventoPersonalizado() {
    TextEditingController nuevoEventoController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: const Text('NUEVO EVENTO', style: TextStyle(color: kVerdeNeon, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nuevoEventoController,
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration('Ej: Ace, Robo, Bloqueo...', kNegro),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(Traductor.get('cancelar'), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon),
            onPressed: () {
              String nuevo = nuevoEventoController.text.trim();
              if (nuevo.isNotEmpty && !switches.containsKey(nuevo)) {
                setState(() {
                  switches[nuevo] = true; 
                });
                Navigator.pop(context);
              }
            },
            child: const Text('AGREGAR', style: TextStyle(color: kNegro, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  Widget _buildBotonesAccion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: kVerdeOscuro, width: 1)), color: kNegro),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(side: BorderSide(color: modoEdicion ? Colors.grey : kVerdeOscuro, width: 2), padding: const EdgeInsets.all(15)),
              onPressed: () => setState(() => modoEdicion = !modoEdicion), 
              child: Text(modoEdicion ? Traductor.get('cancelar') : Traductor.get('editar'), style: TextStyle(color: modoEdicion ? Colors.grey : kVerdeNeon, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon, padding: const EdgeInsets.all(15)),
              onPressed: () {
                if (modoEdicion) {
                  setState(() => modoEdicion = false);
                } else {
                  String nombreLoc = _nombreLocalController.text.trim().isEmpty ? "LOCAL" : _nombreLocalController.text.trim();
                  String nombreVis = _nombreVisitaController.text.trim().isEmpty ? "VISITA" : _nombreVisitaController.text.trim();

                  Map<String, String> planLoc = _parsearPlanilla(_jugadoresLocalController.text);
                  Map<String, String> planVis = _parsearPlanilla(_jugadoresVisitaController.text);

                  Partido nuevoPartido = Partido(
                    deporte: widget.nombreDeporte, local: nombreLoc, visita: nombreVis,
                    contadores: contadores, switches: switches,
                    localFondo: _localFondo, localTexto: _localTexto,
                    visitaFondo: _visitaFondo, visitaTexto: _visitaTexto,
                    jugadoresLocal: planLoc, jugadoresVisita: planVis,
                    patronLocal: _patronLocal, patronVisita: _patronVisita,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaPreInicio(partido: nuevoPartido)));
                }
              }, 
              child: Text(Traductor.get('confirmar'), style: const TextStyle(color: kNegro, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// 4. PRE-INICIO
// =====================================================================
class PantallaPreInicio extends StatelessWidget {
  final Partido partido;
  const PantallaPreInicio({super.key, required this.partido});

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(backgroundColor: kNegro, leading: const BackButton(color: kVerdeNeon)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports, size: 80, color: kVerdeNeon.withOpacity(0.5)),
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                      decoration: BoxDecoration(
                        color: partido.localFondo == Colors.black ? const Color(0xFF111111) : partido.localFondo,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: partido.localTexto.withOpacity(0.5), width: 2),
                        boxShadow: [BoxShadow(color: partido.localFondo.withOpacity(0.3), blurRadius: 10)]
                      ),
                      child: Text(
                        partido.local.toUpperCase(), 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: partido.localTexto, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Text('VS', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                      decoration: BoxDecoration(
                        color: partido.visitaFondo == Colors.black ? const Color(0xFF111111) : partido.visitaFondo,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: partido.visitaTexto.withOpacity(0.5), width: 2),
                        boxShadow: [BoxShadow(color: partido.visitaFondo.withOpacity(0.3), blurRadius: 10)]
                      ),
                      child: Text(
                        partido.visita.toUpperCase(), 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: partido.visitaTexto, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon, minimumSize: const Size(double.infinity, 60)),
                icon: const Icon(Icons.play_circle_filled, color: kNegro, size: 30),
                label: const Text('INICIAR ENCUENTRO', style: TextStyle(color: kNegro, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PantallaTableroControl(partido: partido))),
              ),
              const SizedBox(height: 20),
              
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: kVerdeOscuro, width: 2), minimumSize: const Size(double.infinity, 60)),
                icon: const Icon(Icons.bookmark_add, color: kVerdeNeon),
                label: const Text('GUARDAR PARÁMETROS', style: TextStyle(color: kVerdeNeon, fontSize: 16)),
                onPressed: () {
                  if (!parametrosGuardados.contains(partido)) parametrosGuardados.add(partido);
                  Navigator.popUntil(context, (route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parámetros guardados como plantilla', style: TextStyle(color: kVerdeNeon)), backgroundColor: kNegro));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// 5. TABLERO DE CONTROL 
// =====================================================================
class PantallaTableroControl extends StatefulWidget {
  final Partido partido;
  const PantallaTableroControl({super.key, required this.partido});
  @override State<PantallaTableroControl> createState() => _PantallaTableroControlState();
}

class _PantallaTableroControlState extends State<PantallaTableroControl> with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _segundosTotales = 0;
  bool _estaCorriendo = false;
  int _periodoActual = 1;
  late AnimationController _blinkController;
  double _notaX = 0;
  double _notaY = 0;
  bool _notaInicializada = false;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  void _iniciarTimer() {
    if (_timer != null && _timer!.isActive) return;
    setState(() => _estaCorriendo = true);
    _blinkController.forward();
    _blinkController.stop();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _segundosTotales++;
        if (widget.partido.deporte.toLowerCase() == 'rugby') {
          for (String equipo in ['Local', 'Visita']) {
            for (var t in widget.partido.tarjetas[equipo]!) {
              if (t['tipo']!.toLowerCase().contains('amarilla') && t.containsKey('segundosRestantes')) {
                int rest = int.parse(t['segundosRestantes']!);
                if (rest > 0) t['segundosRestantes'] = (rest - 1).toString();
              }
            }
          }
        }
      });
    });
  }

  void _pausarTimer() {
    _timer?.cancel();
    setState(() => _estaCorriendo = false);
    _blinkController.repeat(reverse: true);
  }

  Future<void> _manejarFinPeriodo() async {
    _pausarTimer();
    String clavePeriodo = widget.partido.contadores.containsKey('Cuartos') ? 'Cuartos' : (widget.partido.contadores.containsKey('Entradas') ? 'Entradas' : 'Tiempos');
    int maxPeriodos = widget.partido.contadores[clavePeriodo] ?? 1;
    String nombreRef = clavePeriodo.toUpperCase().substring(0, clavePeriodo.length - 1); 

    if (_periodoActual < maxPeriodos) {
      bool confirmar = await _mostrarDialogo('¿FINALIZAR $nombreRef $_periodoActual?', 'El cronómetro se reiniciará para el próximo período.', 'SIGUIENTE');
      if (confirmar) {
        setState(() {
          widget.partido.logEventos.add('--- FIN DEL $nombreRef $_periodoActual ---');
          _periodoActual++;
          _segundosTotales = 0; 
        });
      }
    } else {
      bool confirmar = await _mostrarDialogo('¿FINALIZAR ENCUENTRO?', 'Estás en el último período. ¿Deseas terminar el partido y generar el reporte?', 'TERMINAR');
      if (confirmar) {
        setState(() {
          widget.partido.logEventos.add('--- FIN DEL PARTIDO ---');
          if (!partidosGuardados.contains(widget.partido)) {
            partidosGuardados.add(widget.partido);
          }
        });
        Navigator.popUntil(context, (route) => route.isFirst); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Encuentro finalizado y bitácora generada en Guardados', style: TextStyle(color: kVerdeNeon)), backgroundColor: kNegro));
      }
    }
  }

  Future<bool> _mostrarDialogo(String titulo, String mensaje, String btnAccion) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro, shape: RoundedRectangleBorder(side: const BorderSide(color: kRojoStop), borderRadius: BorderRadius.circular(10)),
        title: Text(titulo, style: const TextStyle(color: kRojoStop, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(mensaje, style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRojoStop),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(btnAccion, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    ) ?? false;
  }

  Future<bool> _confirmarSalida() async {
    _pausarTimer();
    return await _mostrarDialogo('¿ABANDONAR SIN GUARDAR?', 'Si sales ahora perderás este registro en vivo.', 'SALIR DE TODAS FORMAS');
  }

  String _formatearTiempo() {
    int minutos = _segundosTotales ~/ 60;
    int segundos = _segundosTotales % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  Future<void> _abrirAnotadorLibre() async {
    TextEditingController notaController = TextEditingController();
    String tiempoActual = _formatearTiempo();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: [
            const Icon(Icons.mic, color: kVerdeNeon, size: 20),
            const SizedBox(width: 10),
            Text('MINUTO A MINUTO ($tiempoActual)', style: const TextStyle(color: kVerdeNeon, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: notaController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Escribí o dictá el comentario del partido acá...',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: kVerdeOscuro)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kVerdeNeon)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon),
            onPressed: () {
              if (notaController.text.trim().isNotEmpty) {
                setState(() {
                  widget.partido.logEventos.add('MIN $tiempoActual | 📝 NOTA: ${notaController.text.trim()}');
                });
              }
              Navigator.pop(context);
            },
            child: const Text('GUARDAR', style: TextStyle(color: kNegro, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  Future<void> _abrirRegistro(String equipoNombre) async {
    final resultado = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => PantallaRegistroEvento(partido: widget.partido, equipoSeleccionado: equipoNombre))
    );

    if (resultado != null) {
      String eventoRegistrado = resultado['evento'];
      String tiempoActual = _formatearTiempo();
      
      if (eventoRegistrado == 'Cambio') {
        int maxC = widget.partido.contadores['Cambios'] ?? 0;
        int maxV = widget.partido.contadores['Ventanas'] ?? 0;
        
        bool primeraVez = true;
        var resActual = resultado;

        while (true) {
          int hechosC = widget.partido.stats[equipoNombre]!['CambiosHechos'] ?? 0;
          int hechasV = widget.partido.stats[equipoNombre]!['VentanasHechas'] ?? 0;

          if (primeraVez) {
            if (maxV > 0 && hechasV >= maxV) {
              bool confirmar = await _mostrarDialogo('LÍMITE DE VENTANAS AGOTADO', 'El equipo ya no tiene ventanas disponibles ($hechasV/$maxV). ¿Continuar de todas formas?', 'SÍ');
              if (!confirmar) return; 
            }
            if (maxC > 0 && hechosC >= maxC) {
              bool confirmar = await _mostrarDialogo('LÍMITE DE CAMBIOS AGOTADO', 'El equipo ya no tiene cambios disponibles ($hechosC/$maxC). ¿Continuar de todas formas?', 'SÍ');
              if (!confirmar) return;
            }
          } else {
            if (maxC > 0 && hechosC >= maxC) {
              bool confirmar = await _mostrarDialogo('LÍMITE DE CAMBIOS AGOTADO', 'El equipo ya no tiene cambios disponibles ($hechosC/$maxC). ¿Continuar de todas formas?', 'SÍ');
              if (!confirmar) break; 
            }
          }

          setState(() {
            widget.partido.stats[equipoNombre]!['CambiosHechos'] = hechosC + 1;
            if (primeraVez && maxV > 0) {
              widget.partido.stats[equipoNombre]!['VentanasHechas'] = hechasV + 1;
            }
            
            String jugSale = resActual['jugador'] ?? '';
            String jugEntra = resActual['jugadorEntra'] ?? '';
            String nombreSale = widget.partido.obtenerNombreJugador(equipoNombre, jugSale);
            String nombreEntra = widget.partido.obtenerNombreJugador(equipoNombre, jugEntra);
            
            widget.partido.cambiosList[equipoNombre]!.add({
              'minuto': tiempoActual,
              'sale': nombreSale,
              'entra': nombreEntra
            });
            
            String nombreReal = equipoNombre == 'Local' ? widget.partido.local : widget.partido.visita;
            widget.partido.logEventos.add('MIN $tiempoActual | ${nombreReal.toUpperCase()}: Cambio ($nombreSale x $nombreEntra)');
          });

          primeraVez = false; 

          bool? otroCambio = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: kNegro,
              shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
              title: const Text('CAMBIO REGISTRADO', style: TextStyle(color: kVerdeNeon, fontSize: 16, fontWeight: FontWeight.bold)),
              content: const Text('¿Quiere realizar otro cambio en esta mesma ventana?', style: TextStyle(color: Colors.white, fontSize: 14)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NO', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon),
                  onPressed: () => Navigator.pop(context, true), 
                  child: const Text('SÍ', style: TextStyle(color: kNegro, fontWeight: FontWeight.bold))
                ),
              ]
            )
          );

          if (otroCambio == null || !otroCambio) break; 

          var datosExtra = await _pedirDatosCambioExtra(equipoNombre);
          if (datosExtra == null) break; 
          
          resActual = datosExtra; 
        }

      } else {
        String jugadorNum = resultado['jugador'] ?? '';
        setState(() {
          if (widget.partido.stats[equipoNombre]!.containsKey(eventoRegistrado)) {
            widget.partido.stats[equipoNombre]![eventoRegistrado] = widget.partido.stats[equipoNombre]![eventoRegistrado]! + 1;
          }

          String eventoMin = eventoRegistrado.toLowerCase();
          String nombreActor = widget.partido.obtenerNombreJugador(equipoNombre, jugadorNum);

         if (eventoMin.contains('tarjeta')) {
            widget.partido.tarjetas[equipoNombre]!.add({
              'minuto': tiempoActual,
              'tipo': eventoRegistrado,
              'jugador': jugadorNum, 
              'nombreCompleto': nombreActor,
              'segundosRestantes': ((widget.partido.contadores['Min. Amarilla'] ?? 10) * 60).toString(),
            });
          }

          if (eventoMin.contains('gol') || eventoMin.contains('carrera') || eventoMin.contains('pt') || eventoMin.contains('try')) {
            widget.partido.anotaciones[equipoNombre]!.add({
              'minuto': tiempoActual,
              'tipo': eventoRegistrado,
              'nombreCompleto': nombreActor
            });
          }

          String nombreReal = equipoNombre == 'Local' ? widget.partido.local : widget.partido.visita;
          widget.partido.logEventos.add('MIN $tiempoActual | ${nombreReal.toUpperCase()}: $eventoRegistrado ($nombreActor)');
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _pedirDatosCambioExtra(String equipoNombre) async {
    String valorPrimario = '';
    String valorSecundario = '';
    bool editandoSecundario = false; 

    Color fondoEq = equipoNombre == 'Local' ? widget.partido.localFondo : widget.partido.visitaFondo;
    Color textoEq = equipoNombre == 'Local' ? widget.partido.localTexto : widget.partido.visitaTexto;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctxDialog) {
        return StatefulBuilder(
          builder: (BuildContext ctxStateful, StateSetter setStateDialog) {

            void onTeclaPulsada(String tecla) {
              setStateDialog(() {
                if (tecla == '<') {
                  if (editandoSecundario && valorSecundario.isNotEmpty) {
                    valorSecundario = valorSecundario.substring(0, valorSecundario.length - 1);
                  } else if (!editandoSecundario && valorPrimario.isNotEmpty) {
                    valorPrimario = valorPrimario.substring(0, valorPrimario.length - 1);
                  }
                } else if (tecla == 'C') {
                  if (editandoSecundario) valorSecundario = '';
                  else valorPrimario = '';
                } else {
                  if (editandoSecundario && valorSecundario.length < 3) {
                    valorSecundario += tecla;
                  } else if (!editandoSecundario && valorPrimario.length < 3) {
                    valorPrimario += tecla;
                  }
                }
              });
            }

            bool puedeConfirmar = valorPrimario.isNotEmpty && valorSecundario.isNotEmpty;

            Widget buildNumpadRow(List<String> teclas) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: teclas.map((tecla) => InkWell(
                    onTap: () => onTeclaPulsada(tecla),
                    child: Container(
                      width: 65, height: 45,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.white12)),
                      child: Center(
                        child: tecla == '<' ? const Icon(Icons.backspace, color: Colors.redAccent, size: 20) :
                               tecla == 'C' ? const Text('C', style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)) :
                               Text(tecla, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      )
                    )
                  )).toList(),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: kNegro, 
              shape: RoundedRectangleBorder(side: BorderSide(color: textoEq, width: 2), borderRadius: BorderRadius.circular(10)),
              title: Column(
                children: [
                  Text(equipoNombre.toUpperCase(), style: TextStyle(color: textoEq, fontSize: 12, letterSpacing: 2)),
                  Text('REGISTRAR CAMBIO EXTRA', textAlign: TextAlign.center, style: TextStyle(color: textoEq, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite, 
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setStateDialog(() => editandoSecundario = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            color: !editandoSecundario ? fondoEq.withOpacity(0.5) : Colors.transparent,
                            border: Border.all(color: !editandoSecundario ? textoEq : Colors.white24),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('N° SALE (Rojo)', style: TextStyle(color: !editandoSecundario ? textoEq : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(valorPrimario.isEmpty ? '_' : valorPrimario, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ]
                          )
                        )
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => setStateDialog(() => editandoSecundario = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            color: editandoSecundario ? fondoEq.withOpacity(0.5) : Colors.transparent,
                            border: Border.all(color: editandoSecundario ? textoEq : Colors.white24),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('N° ENTRA (Verde)', style: TextStyle(color: editandoSecundario ? textoEq : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(valorSecundario.isEmpty ? '_' : valorSecundario, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ]
                          )
                        )
                      ),
                      const SizedBox(height: 20),
                      buildNumpadRow(['1','2','3']),
                      buildNumpadRow(['4','5','6']),
                      buildNumpadRow(['7','8','9']),
                      buildNumpadRow(['C','0','<']),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: puedeConfirmar ? textoEq : Colors.grey),
                  onPressed: puedeConfirmar ? () {
                    Navigator.pop(context, {
                      'evento': 'Cambio', 
                      'jugador': valorPrimario,
                      'jugadorEntra': valorSecundario,
                    }); 
                  } : null,
                  child: Text('CONFIRMAR', style: TextStyle(color: puedeConfirmar ? kNegro : Colors.black45, fontWeight: FontWeight.bold)),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _mostrarDetallePopUp(String titulo, List<Map<String, String>> datos, String tipo) {
    IconData iconoDeporte = DeporteConfig.datos[widget.partido.deporte]!['icono'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: Text(titulo, style: const TextStyle(color: kVerdeNeon, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: SizedBox(
          width: double.maxFinite,
          child: datos.isEmpty
            ? const Text('No hay registros aún.', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center)
            : ListView.separated(
                shrinkWrap: true,
                itemCount: datos.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                itemBuilder: (context, i) {
                  var d = datos[i];
                  
                  if (tipo == 'cambio') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Text('MIN ${d['minuto']}', style: const TextStyle(color: kVerdeNeon, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 16), const SizedBox(width: 5), Text(d['sale']!, style: const TextStyle(color: Colors.white, fontSize: 13))]),
                                Row(children: [const Icon(Icons.arrow_upward, color: Colors.green, size: 16), const SizedBox(width: 5), Text(d['entra']!, style: const TextStyle(color: Colors.white, fontSize: 13))]),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  } 
                  else if (tipo == 'tarjeta') {
                    Color colorT = _obtenerColorTarjeta(d['tipo']!);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Text('MIN ${d['minuto']}', style: const TextStyle(color: kVerdeNeon, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 15),
                          Container(width: 12, height: 18, decoration: BoxDecoration(color: colorT, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(d['nombreCompleto']!, style: const TextStyle(color: Colors.white, fontSize: 14))),
                        ],
                      ),
                    );
                  } 
                  else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Text('MIN ${d['minuto']}', style: const TextStyle(color: kVerdeNeon, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 15),
                          Icon(iconoDeporte, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(d['nombreCompleto']!, style: const TextStyle(color: Colors.white, fontSize: 14))),
                        ],
                      ),
                    );
                  }
                }
              )
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CERRAR', style: TextStyle(color: Colors.grey)))],
      )
    );
  }

  @override void dispose() { 
    _timer?.cancel(); 
    _blinkController.dispose();
    super.dispose(); 
  }

  Color _obtenerColorTarjeta(String tipo) {
    if (tipo.toLowerCase().contains('roja')) return Colors.red;
    if (tipo.toLowerCase().contains('amarilla')) return kAmarilloTarjeta;
    if (tipo.toLowerCase().contains('verde')) return Colors.green;
    return Colors.white;
  }

  @override 
  Widget build(BuildContext context) {
    String clavePeriodo = widget.partido.contadores.containsKey('Cuartos') ? 'Cuartos' : (widget.partido.contadores.containsKey('Entradas') ? 'Entradas' : 'Tiempos');
    String nombrePeriodo = clavePeriodo.toUpperCase().substring(0, clavePeriodo.length - 1); 

    if (!_notaInicializada) {
      _notaX = MediaQuery.of(context).size.width - 80; 
      _notaY = 15; 
      _notaInicializada = true;
    }

    return WillPopScope(
      onWillPop: _confirmarSalida,
      child: Scaffold(
        backgroundColor: kNegro,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: kVerdeNeon), onPressed: () async { if (await _confirmarSalida()) { if (!mounted) return; Navigator.of(context).pop(); } }),
          title: Text('TABLERO ${widget.partido.deporte.toUpperCase()}', style: const TextStyle(color: kVerdeOscuro, fontSize: 12, letterSpacing: 2)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12, width: 1)), color: Color(0xFF0A0A0A)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _mostrarDetallePopUp('ANOTACIONES - ${widget.partido.local.toUpperCase()}', widget.partido.anotaciones['Local']!, 'anotacion'),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(12), 
                                    border: Border.all(color: Colors.white12, width: 1)
                                  ),
                                  child: Column(
                                    children: [
                                      WidgetCamiseta(fondo: widget.partido.localFondo, detalle: widget.partido.localTexto, patron: widget.partido.patronLocal),
                                      const SizedBox(height: 12),
                                      Text(widget.partido.local.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: widget.partido.localTexto, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 5),
                                      Text('${widget.partido.obtenerPuntaje('Local')}', style: TextStyle(color: widget.partido.localTexto, fontSize: 50, fontWeight: FontWeight.bold, height: 1.0)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _mostrarDetallePopUp('TARJETAS - ${widget.partido.local.toUpperCase()}', widget.partido.tarjetas['Local']!, 'tarjeta'),
                                child: SizedBox(
                                  height: 52, 
                                  child: Wrap(
                                    alignment: WrapAlignment.center, spacing: 4, runSpacing: 4,
                                    children: widget.partido.tarjetas['Local']!.take(6).map((t) => _buildMiniTarjetaFisica(t)).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Column(
                          children: [
                            const Text('VS', style: TextStyle(color: Colors.white24, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text('$nombrePeriodo $_periodoActual', style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                            Text(_formatearTiempo(), style: const TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                AnimatedBuilder(
                                  animation: _blinkController,
                                  builder: (context, child) => Opacity(
                                    opacity: _estaCorriendo ? 1.0 : _blinkController.value,
                                    child: IconButton(icon: Icon(_estaCorriendo ? Icons.pause_circle_filled : Icons.play_circle_fill, color: kCelestePlay, size: 30), onPressed: _estaCorriendo ? _pausarTimer : _iniciarTimer, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                  )
                                ),
                                const SizedBox(width: 15),
                                IconButton(icon: const Icon(Icons.stop_circle, color: kRojoStop, size: 30), onPressed: _manejarFinPeriodo, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                              ],
                            )
                          ],
                        ),
                        
                        Expanded(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _mostrarDetallePopUp('ANOTACIONES - ${widget.partido.visita.toUpperCase()}', widget.partido.anotaciones['Visita']!, 'anotacion'),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(12), 
                                    border: Border.all(color: Colors.white12, width: 1)
                                  ),
                                  child: Column(
                                    children: [
                                      WidgetCamiseta(fondo: widget.partido.visitaFondo, detalle: widget.partido.visitaTexto, patron: widget.partido.patronVisita),
                                      const SizedBox(height: 12),
                                      Text(widget.partido.visita.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: widget.partido.visitaTexto, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 5),
                                      Text('${widget.partido.obtenerPuntaje('Visita')}', style: TextStyle(color: widget.partido.visitaTexto, fontSize: 50, fontWeight: FontWeight.bold, height: 1.0)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _mostrarDetallePopUp('TARJETAS - ${widget.partido.visita.toUpperCase()}', widget.partido.tarjetas['Visita']!, 'tarjeta'),
                                child: SizedBox(
                                  height: 52,
                                  child: Wrap(
                                    alignment: WrapAlignment.center, spacing: 4, runSpacing: 4,
                                    children: widget.partido.tarjetas['Visita']!.take(6).map((t) => _buildMiniTarjetaFisica(t)).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container( 
                    margin: const EdgeInsets.only(top: 15), padding: const EdgeInsets.symmetric(vertical: 8), 
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kVerdeOscuro, width: 2))), 
                    child: Row( 
                      mainAxisAlignment: MainAxisAlignment.spaceAround, 
                      children: [ 
                        GestureDetector(onTap: () => _mostrarDetallePopUp('CAMBIOS - ${widget.partido.local}', widget.partido.cambiosList['Local']!, 'cambio'), child: _infoCambios('Local')), 
                        const Text('RESERVAS', style: TextStyle(color: kVerdeOscuro, fontSize: 10, letterSpacing: 2)), 
                        GestureDetector(onTap: () => _mostrarDetallePopUp('CAMBIOS - ${widget.partido.visita}', widget.partido.cambiosList['Visita']!, 'cambio'), child: _infoCambios('Visita')), 
                      ], 
                    ), 
                  ),
                  
                  Expanded( 
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), 
                      children: _generarListaEstadisticasUnificada()
                    ), 
                  ),
                  
                  Container( 
                    padding: const EdgeInsets.all(10), color: const Color(0xFF050505), 
                    child: Row( 
                      children: [ 
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: widget.partido.localFondo == Colors.black ? const Color(0xFF1A1A1A) : widget.partido.localFondo, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: widget.partido.localTexto.withOpacity(0.5)))), 
                            onPressed: () => _abrirRegistro('Local'), 
                            child: Column(children: [Text('REGISTRAR', style: TextStyle(color: widget.partido.localTexto, fontSize: 10)), Text(widget.partido.local, style: TextStyle(color: widget.partido.localTexto, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)])
                          )
                        ), 
                        const SizedBox(width: 10), 
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: widget.partido.visitaFondo == Colors.black ? const Color(0xFF1A1A1A) : widget.partido.visitaFondo, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: widget.partido.visitaTexto.withOpacity(0.5)))), 
                            onPressed: () => _abrirRegistro('Visita'), 
                            child: Column(children: [Text('REGISTRAR', style: TextStyle(color: widget.partido.visitaTexto, fontSize: 10)), Text(widget.partido.visita, style: TextStyle(color: widget.partido.visitaTexto, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)])
                          )
                        ), 
                      ], 
                    ), 
                  )
                ],
              ),

              Positioned(
                left: _notaX,
                top: _notaY,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _notaX += details.delta.dx;
                      _notaY += details.delta.dy;
                    });
                  },
                  child: FloatingActionButton(
                    backgroundColor: kVerdeNeon,
                    elevation: 5,
                    onPressed: _abrirAnotadorLibre,
                    child: const Icon(Icons.edit_note, color: kNegro, size: 30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTarjetaFisica(Map<String, String> tarjeta) {
    Color colorTarjeta = _obtenerColorTarjeta(tarjeta['tipo']!);
    String numJugador = tarjeta['jugador']!;
    bool esAmarilla = tarjeta['tipo']!.toLowerCase().contains('amarilla');
    bool esRugby = widget.partido.deporte.toLowerCase() == 'rugby';
    
    String textoTimer = '';
    bool mostrarTimer = false;
    
    if (esRugby && esAmarilla && tarjeta.containsKey('segundosRestantes')) {
      mostrarTimer = true;
      int restante = int.parse(tarjeta['segundosRestantes']!);
      
      if (restante > 0) {
        int m = restante ~/ 60;
        int s = restante % 60;
        textoTimer = '$m:${s.toString().padLeft(2, '0')}';
      } else {
        textoTimer = 'OK'; 
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16, height: 22, 
          decoration: BoxDecoration(
            color: colorTarjeta,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
            boxShadow: [ BoxShadow(color: colorTarjeta.withOpacity(0.3), blurRadius: 2, spreadRadius: 1) ]
          ),
          child: Center(
            child: Text(
              numJugador,
              style: TextStyle(
                color: colorTarjeta == kAmarilloTarjeta ? kNegro : Colors.white,
                fontSize: 10, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (mostrarTimer) ...[
          const SizedBox(height: 2),
          Text(textoTimer, style: const TextStyle(color: kAmarilloTarjeta, fontSize: 8, fontWeight: FontWeight.bold))
        ]
      ],
    );
  }

  Widget _infoCambios(String equipo) { int maxC = widget.partido.contadores['Cambios'] ?? 0; int maxV = widget.partido.contadores['Ventanas'] ?? 0; int hechosC = widget.partido.stats[equipo]!['CambiosHechos'] ?? 0; int hechasV = widget.partido.stats[equipo]!['VentanasHechas'] ?? 0; String texto = 'C: $hechosC/$maxC'; if (maxV > 0) texto += ' | V: $hechasV/$maxV'; return Text(texto, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)); }
  
  List<Widget> _generarListaEstadisticasUnificada() { 
    List<Widget> filas = []; 
    widget.partido.stats['Local']!.forEach((evento, _) { 
      if (!evento.toLowerCase().contains('gol') && !evento.contains('Hech') && !evento.toLowerCase().contains('punto') && !evento.toLowerCase().contains('try') && !evento.toLowerCase().contains('carrera')) { 
        
        int cantLocal = widget.partido.stats['Local']![evento] ?? 0;
        int cantVisita = widget.partido.stats['Visita']![evento] ?? 0;

        filas.add( 
          Padding( 
            padding: const EdgeInsets.symmetric(vertical: 8.0), 
            child: Row( 
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [ 
                SizedBox(
                  width: 45,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4), 
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(5)), 
                    child: Text('$cantLocal', textAlign: TextAlign.center, style: TextStyle(color: widget.partido.localTexto, fontSize: 15, fontWeight: FontWeight.bold))
                  )
                ),
                Expanded(child: Text(evento.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1))),
                SizedBox(
                  width: 45,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4), 
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(5)), 
                    child: Text('$cantVisita', textAlign: TextAlign.center, style: TextStyle(color: widget.partido.visitaTexto, fontSize: 15, fontWeight: FontWeight.bold))
                  )
                ),
              ], 
            ), 
          ) 
        ); 
      } 
    }); 
    return filas; 
  }
}

// =====================================================================
// 6. REGISTRO ESPECÍFICO DE EVENTOS
// =====================================================================
class PantallaRegistroEvento extends StatefulWidget {
  final Partido partido;
  final String equipoSeleccionado;

  const PantallaRegistroEvento({super.key, required this.partido, required this.equipoSeleccionado});

  @override
  State<PantallaRegistroEvento> createState() => _PantallaRegistroEventoState();
}

class _PantallaRegistroEventoState extends State<PantallaRegistroEvento> {
  
  void _pedirJugador(BuildContext context, String eventoNombre, Color fondoEq, Color textoEq, String nombreEq) {
    String valorPrimario = '';
    String valorSecundario = '';
    bool editandoSecundario = false; 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctxDialog) {
        return StatefulBuilder(
          builder: (BuildContext ctxStateful, StateSetter setStateDialog) {

            void onTeclaPulsada(String tecla) {
              setStateDialog(() {
                if (tecla == '<') {
                  if (editandoSecundario && valorSecundario.isNotEmpty) {
                    valorSecundario = valorSecundario.substring(0, valorSecundario.length - 1);
                  } else if (!editandoSecundario && valorPrimario.isNotEmpty) {
                    valorPrimario = valorPrimario.substring(0, valorPrimario.length - 1);
                  }
                } else if (tecla == 'C') {
                  if (editandoSecundario) valorSecundario = '';
                  else valorPrimario = '';
                } else {
                  if (editandoSecundario && valorSecundario.length < 3) {
                    valorSecundario += tecla;
                  } else if (!editandoSecundario && valorPrimario.length < 3) {
                    valorPrimario += tecla;
                  }
                }
              });
            }

            bool esCambio = eventoNombre == 'Cambio';
            bool puedeConfirmar = esCambio 
                ? (valorPrimario.isNotEmpty && valorSecundario.isNotEmpty)
                : true;

            Widget buildNumpadRow(List<String> teclas) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: teclas.map((tecla) => InkWell(
                    onTap: () => onTeclaPulsada(tecla),
                    child: Container(
                      width: 65, height: 45,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.white12)),
                      child: Center(
                        child: tecla == '<' ? const Icon(Icons.backspace, color: Colors.redAccent, size: 20) :
                               tecla == 'C' ? const Text('C', style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)) :
                               Text(tecla, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      )
                    )
                  )).toList(),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: kNegro, 
              shape: RoundedRectangleBorder(side: BorderSide(color: textoEq, width: 2), borderRadius: BorderRadius.circular(10)),
              title: Column(
                children: [
                  Text(nombreEq.toUpperCase(), style: TextStyle(color: textoEq, fontSize: 12, letterSpacing: 2)),
                  Text('REGISTRAR $eventoNombre', textAlign: TextAlign.center, style: TextStyle(color: textoEq, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite, 
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setStateDialog(() => editandoSecundario = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            color: !editandoSecundario ? fondoEq.withOpacity(0.5) : Colors.transparent,
                            border: Border.all(color: !editandoSecundario ? textoEq : Colors.white24),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(esCambio ? 'N° SALE (Rojo)' : 'N° JUGADOR', style: TextStyle(color: !editandoSecundario ? textoEq : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(valorPrimario.isEmpty ? '_' : valorPrimario, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ]
                          )
                        )
                      ),
                      
                      if (esCambio) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => setStateDialog(() => editandoSecundario = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            decoration: BoxDecoration(
                              color: editandoSecundario ? fondoEq.withOpacity(0.5) : Colors.transparent,
                              border: Border.all(color: editandoSecundario ? textoEq : Colors.white24),
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('N° ENTRA (Verde)', style: TextStyle(color: editandoSecundario ? textoEq : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(valorSecundario.isEmpty ? '_' : valorSecundario, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              ]
                            )
                          )
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      buildNumpadRow(['1','2','3']),
                      buildNumpadRow(['4','5','6']),
                      buildNumpadRow(['7','8','9']),
                      buildNumpadRow(['C','0','<']),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: puedeConfirmar ? textoEq : Colors.grey),
                  onPressed: puedeConfirmar ? () {
                    Navigator.pop(context); 
                    Navigator.pop(context, {
                      'evento': eventoNombre, 
                      'jugador': valorPrimario.isEmpty ? '?' : valorPrimario,
                      'jugadorEntra': valorSecundario.isEmpty ? '?' : valorSecundario,
                    }); 
                  } : null,
                  child: Text('CONFIRMAR', style: TextStyle(color: puedeConfirmar ? kNegro : Colors.black45, fontWeight: FontWeight.bold)),
                )
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildCajaEvento(String evento, Color fondoEq, Color textoEq, bool isDragging) {
    return Container(
      decoration: BoxDecoration(
        color: fondoEq.withOpacity(isDragging ? 0.3 : 0.1),
        border: Border.all(color: isDragging ? textoEq : (fondoEq == Colors.black ? Colors.white24 : fondoEq)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDragging ? [BoxShadow(color: textoEq.withOpacity(0.5), blurRadius: 10)] : [],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              evento.toUpperCase(), 
              textAlign: TextAlign.center, 
              style: TextStyle(color: textoEq, fontWeight: FontWeight.bold, fontSize: 12)
            ),
          ),
        ),
      ),
    );
  }

  @override 
  Widget build(BuildContext context) {
    Color fondoEq = widget.equipoSeleccionado == 'Local' ? widget.partido.localFondo : widget.partido.visitaFondo;
    Color textoEq = widget.equipoSeleccionado == 'Local' ? widget.partido.localTexto : widget.partido.visitaTexto;
    String nombreEq = widget.equipoSeleccionado == 'Local' ? widget.partido.local : widget.partido.visita;
    
    Color appBarColor = fondoEq == Colors.black ? const Color(0xFF111111) : fondoEq;

    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: Text('REGISTRO: ${nombreEq.toUpperCase()}', style: TextStyle(color: textoEq, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)), 
        backgroundColor: appBarColor,
        leading: BackButton(color: textoEq), 
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Text('Mantén presionado un botón para moverlo', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.5),
              itemCount: widget.partido.ordenEventosActivos.length,
              itemBuilder: (context, index) {
                String evento = widget.partido.ordenEventosActivos[index];
                
                return DragTarget<int>(
                  onAccept: (draggedIndex) {
                    setState(() {
                      String temp = widget.partido.ordenEventosActivos[index];
                      widget.partido.ordenEventosActivos[index] = widget.partido.ordenEventosActivos[draggedIndex];
                      widget.partido.ordenEventosActivos[draggedIndex] = temp;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return LongPressDraggable<int>(
                      data: index,
                      delay: const Duration(milliseconds: 300), 
                      feedback: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width / 2.3, 
                          height: 70, 
                          child: _buildCajaEvento(evento, fondoEq, textoEq, true),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.2,
                        child: _buildCajaEvento(evento, fondoEq, textoEq, false),
                      ),
                      child: InkWell(
                        onTap: () => _pedirJugador(context, evento, fondoEq, textoEq, nombreEq),
                        child: _buildCajaEvento(evento, fondoEq, textoEq, false),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// 7. PANTALLA DE ENCUENTROS GUARDADOS Y BITÁCORA TEXTUAL
// =====================================================================
class PantallaEncuentrosGuardados extends StatelessWidget {
  const PantallaEncuentrosGuardados({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(title: Text(Traductor.get('menu_6').toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)), backgroundColor: kNegro, leading: const BackButton(color: kVerdeNeon)),
      body: partidosGuardados.isEmpty
          ? const Center(child: Text('No hay encuentros registrados aún.', style: TextStyle(color: Colors.white54, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: partidosGuardados.length,
              itemBuilder: (context, index) {
                Partido p = partidosGuardados[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Card(
                    color: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeOscuro), borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      leading: Icon(DeporteConfig.datos[p.deporte]!['icono'], color: kVerdeNeon, size: 30),
                      title: Text('${p.local.toUpperCase()} vs ${p.visita.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('Resultado: ${p.obtenerPuntaje('Local')} - ${p.obtenerPuntaje('Visita')}', style: const TextStyle(color: kVerdeNeon, fontSize: 14)),
                      trailing: const Icon(Icons.description, color: Colors.white54),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaResumenPartido(partido: p))),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class PantallaResumenPartido extends StatelessWidget {
  final Partido partido;
  const PantallaResumenPartido({super.key, required this.partido});

  String _generarFirma() {
    if (perfilUsuario['usarFirma'] == true) {
      String nombre = perfilUsuario['nombre'].toString().trim();
      String medio = perfilUsuario['medio'].toString().trim();
      String redes = perfilUsuario['redSocial'].toString().trim();
      
      if (nombre.isNotEmpty || medio.isNotEmpty || redes.isNotEmpty) {
        String textoFirma = '\n\n---\nReporte generado por ${nombre.isEmpty ? 'Analista' : nombre}';
        if (medio.isNotEmpty) textoFirma += ' para $medio';
        if (redes.isNotEmpty) textoFirma += ' ($redes)';
        textoFirma += ' | App: Quantum Referee';
        return textoFirma;
      }
    }
    return '';
  }

  Future<void> _exportarCSV(BuildContext context) async {
    try {
      StringBuffer csv = StringBuffer();
      
      csv.writeln('TORNEO/APP,Quantum Referee');
      csv.writeln('DEPORTE,${partido.deporte.toUpperCase()}');
      csv.writeln('LOCAL,${partido.local.toUpperCase()},PUNTOS:,${partido.obtenerPuntaje("Local")}');
      csv.writeln('VISITA,${partido.visita.toUpperCase()},PUNTOS:,${partido.obtenerPuntaje("Visita")}');
      csv.writeln('');
      
      csv.writeln('--- ESTADISTICAS GLOBALES ---');
      csv.writeln('EQUIPO,EVENTO,CANTIDAD');
      for (String eq in ['Local', 'Visita']) {
        partido.stats[eq]!.forEach((evento, cant) {
          csv.writeln('$eq,$evento,$cant');
        });
      }
      csv.writeln('');

      csv.writeln('--- MINUTO A MINUTO ---');
      csv.writeln('TIEMPO,EQUIPO,EVENTO_Y_JUGADOR');
      
      for (String linea in partido.logEventos) {
        String lineaLimpia = linea.replaceAll(',', ';'); 
        if (lineaLimpia.contains('|')) {
          List<String> partes = lineaLimpia.split('|');
          csv.writeln('${partes[0].trim()},${partes[1].trim()}');
        } else {
          csv.writeln(lineaLimpia);
        }
      }

      String firma = _generarFirma();
      if (firma.isNotEmpty) {
         csv.writeln('');
         csv.writeln(firma.replaceAll('\n', ' ').replaceAll('--- ', ''));
      }

      List<int> bytes = utf8.encode(csv.toString());
      Uint8List archivoBytes = Uint8List.fromList(bytes);
      String nombreArchivo = 'Quantum_${partido.local}_vs_${partido.visita}.csv'.replaceAll(' ', '_');

      XFile archivoCsv = XFile.fromData(archivoBytes, mimeType: 'text/csv', name: nombreArchivo);
      await Share.shareXFiles([archivoCsv], text: 'Reporte CSV de Estadísticas');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al exportar el archivo', style: TextStyle(color: Colors.redAccent)), backgroundColor: kNegro));
    }
  }

  @override
  Widget build(BuildContext context) {
    String textoResumen = partido.logEventos.join('\n\n') + _generarFirma();

    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: const Text('REPORTE DEL PARTIDO', style: TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)), 
        backgroundColor: kNegro, 
        leading: const BackButton(color: kVerdeNeon),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart, color: Colors.greenAccent),
            tooltip: 'Exportar Excel (.CSV)',
            onPressed: () => _exportarCSV(context),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: kCelestePlay),
            tooltip: 'Copiar Texto',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: textoResumen));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitácora copiada al portapapeles', style: TextStyle(color: kVerdeNeon)), backgroundColor: kNegro));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('${partido.local.toUpperCase()} ${partido.obtenerPuntaje('Local')} - ${partido.obtenerPuntaje('Visita')} ${partido.visita.toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text(Traductor.get(partido.deporte).toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 3)),
            const SizedBox(height: 25),
            
            const Align(alignment: Alignment.centerLeft, child: Text('BITÁCORA DE EVENTOS', style: TextStyle(color: kVerdeOscuro, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFF0A0A0A), border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(
                  child: Text(textoResumen, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13, height: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 8. PANTALLA DE ENCUENTROS PERSONALIZADOS (PLANTILLAS)
// =====================================================================
class PantallaEncuentrosPersonalizados extends StatelessWidget {
  const PantallaEncuentrosPersonalizados({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(title: Text(Traductor.get('menu_2').toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)), backgroundColor: kNegro, leading: const BackButton(color: kVerdeNeon)),
      body: parametrosGuardados.isEmpty
          ? const Center(child: Text('No hay plantillas personalizadas aún.', style: TextStyle(color: Colors.white54, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: parametrosGuardados.length,
              itemBuilder: (context, index) {
                Partido p = parametrosGuardados[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Card(
                    color: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(side: const BorderSide(color: kCelestePlay), borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      leading: Icon(DeporteConfig.datos[p.deporte]!['icono'], color: kCelestePlay, size: 30),
                      title: Text('${p.local.toUpperCase()} vs ${p.visita.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('Plantilla de ${Traductor.get(p.deporte)}', style: const TextStyle(color: kCelestePlay, fontSize: 14)),
                      trailing: const Icon(Icons.play_arrow, color: kVerdeNeon),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaPreInicio(partido: p)));
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// =====================================================================
// 9. PANTALLA DE MI CUENTA Y EDICIÓN DE IDENTIDAD
// =====================================================================
class PantallaMiCuenta extends StatefulWidget {
  const PantallaMiCuenta({super.key});

  @override
  State<PantallaMiCuenta> createState() => _PantallaMiCuentaState();
}

class _PantallaMiCuentaState extends State<PantallaMiCuenta> {
  
  void _seleccionarDeporteDefecto() {
    List<String> deportes = ['Ninguno', ...DeporteConfig.datos.keys];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: const Text('DEPORTE POR DEFECTO', style: TextStyle(color: kVerdeNeon, fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: deportes.map((d) => ListTile(
            title: Text(d == 'Ninguno' ? 'Ninguno' : Traductor.get(d).toUpperCase(), style: TextStyle(color: perfilUsuario['deporteDefecto'] == d ? kVerdeNeon : Colors.white, fontSize: 13)),
            trailing: perfilUsuario['deporteDefecto'] == d ? const Icon(Icons.check, color: kVerdeNeon) : null,
            onTap: () {
              setState(() => perfilUsuario['deporteDefecto'] = d == 'Ninguno' ? '' : d);
              QuantumStorage.guardarPerfil(perfilUsuario);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      )
    );
  }

  Future<void> _exportarBaseDeDatos() async {
    if (partidosGuardados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay partidos en el historial para exportar', style: TextStyle(color: Colors.redAccent)), backgroundColor: kNegro));
      return;
    }

    try {
      StringBuffer csv = StringBuffer();
      csv.writeln('APP,Quantum Referee - Backup Global');
      csv.writeln('FECHA EXPORTACION,${DateTime.now().toString()}');
      csv.writeln('');
      
      csv.writeln('DEPORTE,LOCAL,PUNTOS_L,VISITA,PUNTOS_V,TOTAL_EVENTOS_REGISTRADOS');

      for (var p in partidosGuardados) {
        int totalEventos = p.logEventos.length;
        csv.writeln('${p.deporte},${p.local},${p.obtenerPuntaje("Local")},${p.visita},${p.obtenerPuntaje("Visita")},$totalEventos');
      }

      List<int> bytes = utf8.encode(csv.toString());
      Uint8List archivoBytes = Uint8List.fromList(bytes);
      XFile archivoCsv = XFile.fromData(archivoBytes, mimeType: 'text/csv', name: 'Quantum_Backup_Global.csv');
      
      await Share.shareXFiles([archivoCsv], text: 'Backup de todos los partidos');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al exportar', style: TextStyle(color: Colors.redAccent)), backgroundColor: kNegro));
    }
  }

  @override
  Widget build(BuildContext context) {
    String deporteElegido = perfilUsuario['deporteDefecto'] ?? '';
    
    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: Text(Traductor.get('menu_5').toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)),
        backgroundColor: kNegro,
        leading: const BackButton(color: kVerdeNeon),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(10), border: Border.all(color: kVerdeOscuro)),
            child: Row(
              children: [
                const CircleAvatar(radius: 30, backgroundColor: kVerdeOscuro, child: Icon(Icons.person, color: kVerdeNeon, size: 30)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(perfilUsuario['nombre'].toString().isEmpty ? 'Usuario sin nombre' : perfilUsuario['nombre'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(perfilUsuario['medio'].toString().isEmpty ? 'Configurá tu identidad' : '${perfilUsuario['medio']} | ${perfilUsuario['redSocial']}', style: const TextStyle(color: kVerdeNeon, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          const Text('AJUSTES DE TRABAJO', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 10),

          _buildOpcionMenu(
            icono: Icons.badge, 
            titulo: 'Identidad y Firma', 
            subtitulo: 'Configurá tu nombre y firma automática',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaEditarIdentidad())).then((_) => setState((){})),
          ),

          _buildOpcionMenu(
            icono: Icons.sports, 
            titulo: 'Deporte por Defecto', 
            subtitulo: deporteElegido.isEmpty ? 'Elegí con qué deporte arranca la app' : 'Actual: ${Traductor.get(deporteElegido).toUpperCase()}',
            onTap: _seleccionarDeporteDefecto,
          ),

          const SizedBox(height: 20),
          const Text('GESTIÓN DE DATOS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 10),

          _buildOpcionMenu(
            icono: Icons.download_for_offline, 
            titulo: 'Exportar Base de Datos', 
            subtitulo: 'Descargar CSV con todos los partidos jugados',
            onTap: _exportarBaseDeDatos,
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionMenu({required IconData icono, required String titulo, required String subtitulo, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.white.withOpacity(0.05))),
        tileColor: Colors.white.withOpacity(0.02),
        leading: Icon(icono, color: Colors.white70),
        title: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: kVerdeNeon),
        onTap: onTap,
      ),
    );
  }
}

class PantallaEditarIdentidad extends StatefulWidget {
  const PantallaEditarIdentidad({super.key});

  @override
  State<PantallaEditarIdentidad> createState() => _PantallaEditarIdentidadState();
}

class _PantallaEditarIdentidadState extends State<PantallaEditarIdentidad> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _medioCtrl;
  late TextEditingController _redesCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: perfilUsuario['nombre']);
    _medioCtrl = TextEditingController(text: perfilUsuario['medio']);
    _redesCtrl = TextEditingController(text: perfilUsuario['redSocial']);
  }

  void _guardarPerfil() {
    setState(() {
      perfilUsuario['nombre'] = _nombreCtrl.text.trim();
      perfilUsuario['medio'] = _medioCtrl.text.trim();
      perfilUsuario['redSocial'] = _redesCtrl.text.trim();
    });
    QuantumStorage.guardarPerfil(perfilUsuario);
    FocusScope.of(context).unfocus(); 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Identidad guardada con éxito', style: TextStyle(color: kVerdeNeon)), backgroundColor: kNegro));
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: const Text('IDENTIDAD Y FIRMA', style: TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)),
        backgroundColor: kNegro,
        leading: const BackButton(color: kVerdeNeon),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DATOS DEL CRONISTA / ANALISTA', style: TextStyle(color: kVerdeOscuro, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 15),
            
            TextField(
              controller: _nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Tu Nombre / Apodo', labelStyle: TextStyle(color: Colors.white54), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kVerdeNeon))),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _medioCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Medio / Organización (Ej: ESPN, Radio Mitre)', labelStyle: TextStyle(color: Colors.white54), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kVerdeNeon))),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _redesCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Usuario en Redes (Ej: @MartinDatos)', labelStyle: TextStyle(color: Colors.white54), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kVerdeNeon))),
            ),
            
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: kVerdeOscuro)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text('INCLUIR FIRMA AUTOMÁTICA EN REPORTES', style: TextStyle(color: kVerdeNeon, fontSize: 12, fontWeight: FontWeight.bold))),
                  Switch(
                    value: perfilUsuario['usarFirma'],
                    activeColor: kVerdeNeon,
                    onChanged: (val) {
                      setState(() => perfilUsuario['usarFirma'] = val);
                    },
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon, minimumSize: const Size(double.infinity, 55)),
              icon: const Icon(Icons.save, color: kNegro),
              label: const Text('GUARDAR IDENTIDAD', style: TextStyle(color: kNegro, fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: _guardarPerfil,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 10. PANTALLA DE ESTADÍSTICAS GLOBALES
// =====================================================================
class PantallaEstadisticas extends StatelessWidget {
  const PantallaEstadisticas({super.key});

  @override
  Widget build(BuildContext context) {
    int totalPartidos = partidosGuardados.length;
    Map<String, int> partidosPorDeporte = {};
    int totalPuntosLocal = 0;
    int totalPuntosVisita = 0;

    for (var p in partidosGuardados) {
      partidosPorDeporte[p.deporte] = (partidosPorDeporte[p.deporte] ?? 0) + 1;
      totalPuntosLocal += p.obtenerPuntaje('Local');
      totalPuntosVisita += p.obtenerPuntaje('Visita');
    }

    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: Text(Traductor.get('menu_3').toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)),
        backgroundColor: kNegro,
        leading: const BackButton(color: kVerdeNeon),
      ),
      body: totalPartidos == 0
          ? const Center(child: Text('No hay partidos registrados para analizar.', style: TextStyle(color: Colors.white54, fontSize: 14)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildTarjetaDato('TOTAL ENCUENTROS', totalPartidos.toString(), Icons.analytics),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildTarjetaDato('PUNTOS LOCALES', totalPuntosLocal.toString(), Icons.home)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildTarjetaDato('PUNTOS VISITA', totalPuntosVisita.toString(), Icons.flight_land)),
                  ],
                ),
                const SizedBox(height: 30),
                const Text('ENCUENTROS POR DEPORTE', style: TextStyle(color: kVerdeOscuro, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 15),
                
                ...partidosPorDeporte.entries.map((e) => _buildFilaDeporte(Traductor.get(e.key), e.value, totalPartidos)).toList(),
              ],
            ),
    );
  }

  Widget _buildTarjetaDato(String titulo, String valor, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kVerdeOscuro),
      ),
      child: Column(
        children: [
          Icon(icono, color: kVerdeNeon, size: 30),
          const SizedBox(height: 10),
          Text(valor, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(titulo, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFilaDeporte(String deporte, int cantidad, int total) {
    double porcentaje = cantidad / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(deporte.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('$cantidad (${(porcentaje * 100).toStringAsFixed(0)}%)', style: const TextStyle(color: kVerdeNeon, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: porcentaje,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: kCelestePlay,
            minHeight: 6,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// PANTALLA DE CONFIGURACIONES E IDIOMA
// =====================================================================
class PantallaConfiguraciones extends StatefulWidget {
  const PantallaConfiguraciones({super.key});

  @override
  State<PantallaConfiguraciones> createState() => _PantallaConfiguracionesState();
}

class _PantallaConfiguracionesState extends State<PantallaConfiguraciones> {
  
  void _seleccionarIdioma() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: Text(Traductor.get('idioma_app'), style: const TextStyle(color: kVerdeNeon, fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Español', 'English', 'Português'].map((idioma) => ListTile(
            title: Text(idioma, style: TextStyle(color: perfilUsuario['idioma'] == idioma ? kVerdeNeon : Colors.white, fontSize: 13)),
            trailing: perfilUsuario['idioma'] == idioma ? const Icon(Icons.check, color: kVerdeNeon) : null,
            onTap: () {
              setState(() => perfilUsuario['idioma'] = idioma);
              QuantumStorage.guardarPerfil(perfilUsuario); 
              Navigator.pop(context); 
              setState(() {}); 
            },
          )).toList(),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    String idiomaElegido = perfilUsuario['idioma'] ?? 'Español';

    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: Text(Traductor.get('titulo_config'), style: const TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)),
        backgroundColor: kNegro,
        leading: const BackButton(color: kVerdeNeon),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(Traductor.get('preferencias'), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 10),
          
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.white.withOpacity(0.05))),
            tileColor: Colors.white.withOpacity(0.02),
            leading: const Icon(Icons.language, color: Colors.white70),
            title: Text(Traductor.get('idioma'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(idiomaElegido, style: const TextStyle(color: kVerdeNeon, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: kVerdeNeon),
            onTap: _seleccionarIdioma,
          ),
          
        ],
      ),
    );
  }
}

// =====================================================================
// WIDGET CAMISETA REALISTA (Para el Tablero de Control)
// =====================================================================
class WidgetCamiseta extends StatelessWidget {
  final Color fondo;
  final Color detalle;
  final PatronCamiseta patron;

  const WidgetCamiseta({
    super.key, 
    required this.fondo, 
    required this.detalle,
    this.patron = PatronCamiseta.franjaHorizontal, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 55,
      height: 55,
      child: CustomPaint(
        painter: _CamisetaPainter(
          colorPrincipal: fondo, 
          colorSecundario: detalle, 
          patron: patron
        ),
      ),
    );
  }
}

class _CamisetaPainter extends CustomPainter {
  final Color colorPrincipal;
  final Color colorSecundario;
  final PatronCamiseta patron;

  _CamisetaPainter({
    required this.colorPrincipal, 
    required this.colorSecundario, 
    required this.patron
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintPrincipal = Paint()..color = colorPrincipal..style = PaintingStyle.fill;
    final paintSecundario = Paint()..color = colorSecundario..style = PaintingStyle.fill;
    final paintBorde = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1.5;

    double w = size.width;
    double h = size.height;

    Path path = Path();
    path.moveTo(w * 0.15, h * 0.1); 
    path.lineTo(w * 0.35, h * 0.1); 
    path.quadraticBezierTo(w * 0.5, h * 0.28, w * 0.65, h * 0.1); 
    path.lineTo(w * 0.85, h * 0.1); 
    path.lineTo(w * 0.95, h * 0.4); 
    path.lineTo(w * 0.85, h * 0.45); 
    path.lineTo(w * 0.80, h * 0.95); 
    path.lineTo(w * 0.20, h * 0.95); 
    path.lineTo(w * 0.15, h * 0.45); 
    path.lineTo(w * 0.05, h * 0.4); 
    path.close();

    canvas.save();
    canvas.clipPath(path);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paintPrincipal);
    
    switch (patron) {
      case PatronCamiseta.liso:
        break;
        
      case PatronCamiseta.franjaHorizontal:
        canvas.drawRect(Rect.fromLTWH(0, h * 0.42, w, h * 0.25), paintSecundario);
        break;
        
      case PatronCamiseta.bandaDiagonal:
        Path banda = Path();
        banda.moveTo(w * 0.1, 0);
        banda.lineTo(w * 0.4, 0);
        banda.lineTo(w * 0.9, h);
        banda.lineTo(w * 0.6, h);
        banda.close();
        canvas.drawPath(banda, paintSecundario);
        break;
        
      case PatronCamiseta.mitades:
        canvas.drawRect(Rect.fromLTWH(w / 2, 0, w / 2, h), paintSecundario);
        break;
        
      case PatronCamiseta.rayasVerticales:
        for (double i = 0; i < w; i += w / 5) {
          canvas.drawRect(Rect.fromLTWH(i, 0, w / 10, h), paintSecundario);
        }
        break;
        
      case PatronCamiseta.rayasHorizontales:
        for (double i = 0; i < h; i += h / 6) {
          canvas.drawRect(Rect.fromLTWH(0, i, w, h / 12), paintSecundario);
        }
        break;
    }

    canvas.restore(); 
    canvas.drawPath(path, paintBorde);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; 
}