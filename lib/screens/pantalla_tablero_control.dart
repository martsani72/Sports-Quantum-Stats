// ignore_for_file: prefer_const_constructors, unused_import, prefer_const_literals_to_create_immutables, use_key_in_widget_constructors, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_nueva_app/core/constants.dart';
import 'package:mi_nueva_app/core/globals.dart';
import 'package:mi_nueva_app/core/quantum_storage.dart';
import 'package:mi_nueva_app/core/traductor.dart';

import 'package:mi_nueva_app/models/partido.dart';
import 'package:mi_nueva_app/models/deporte_config.dart';
import 'package:mi_nueva_app/widgets/widget_camiseta.dart';
import 'package:mi_nueva_app/widgets/widget_icono_quantum.dart';
import 'package:mi_nueva_app/screens/pantalla_registro_evento.dart';
import 'package:mi_nueva_app/screens/pantalla_configuraciones.dart';
import 'package:mi_nueva_app/core/ad_helper.dart';
import 'dart:ui';

class PantallaTableroControl extends StatefulWidget {
  final Partido partido;
  const PantallaTableroControl({super.key, required this.partido});
  @override State<PantallaTableroControl> createState() => _PantallaTableroControlState();
}

class PasoTutorial {
  final String titulo;
  final String desc;
  final GlobalKey? key;
  final Widget? icono;
  final bool mostrarFlecha;

  PasoTutorial({required this.titulo, required this.desc, this.key, this.icono, this.mostrarFlecha = true});
}

class _PantallaTableroControlState extends State<PantallaTableroControl> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  int _segundosAcumulados = 0; 
  DateTime? _momentoInicioActual; 
  bool _estaCorriendo = false;
  int _periodoActual = 1;
  late AnimationController _blinkController;
  double _notaX = 0;
  double _notaY = 0;
  bool _notaInicializada = false;
  String? _equipoPosesion; // 'Local' o 'Visita'
  int _shotClock = 24; // Reloj de tiro para Básquet
  
  // CONTROLADORES BASEBALL
  TextEditingController _ctrlBateador = TextEditingController();
  TextEditingController _ctrlLanzador = TextEditingController();
  bool _inicializadoBaseball = false;
  List<String> _ordenStats = [];

  // CLAVES PARA TUTORIAL
  final GlobalKey _keyBody = GlobalKey();
  final GlobalKey _keyPlay = GlobalKey();
  final GlobalKey _keyNext = GlobalKey();
  final GlobalKey _keyUndo = GlobalKey();
  final GlobalKey _keyNote = GlobalKey();
  final GlobalKey _keyPossession = GlobalKey();
  final GlobalKey _keyFinalize = GlobalKey();
  final GlobalKey _keyScore = GlobalKey();
  final GlobalKey _keyBaseball = GlobalKey();
  final GlobalKey _keyFootball = GlobalKey();
  
  bool _mostrarTutorial = false;
  int _pasoTutorialIndex = 0;
  List<PasoTutorial> _listaPasos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    AdHelper.cargarInterstitialAd();
    _inicializarPasosTutorial();

    if (!QuantumStorage.getTutorialVisto()) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _mostrarTutorial = true);
      });
    }
    _cargarOrdenStats();
  }

  void _cargarOrdenStats() {
    String deporte = widget.partido.deporte.toLowerCase();
    List<String>? guardado = QuantumStorage.cargarOrdenStats(deporte);
    
    List<String> statsDisponibles = widget.partido.stats['Local']!.keys
        .where((k) => k != 'CambiosHechos' && k != 'VentanasHechas')
        .toList();

    if (guardado != null && guardado.isNotEmpty) {
      // Filtrar los guardados que ya no existan y añadir los nuevos que no estén en el orden guardado
      List<String> validos = guardado.where((s) => statsDisponibles.contains(s)).toList();
      List<String> nuevos = statsDisponibles.where((s) => !validos.contains(s)).toList();
      _ordenStats = [...validos, ...nuevos];
    } else {
      _ordenStats = statsDisponibles;
    }
  }

  void _inicializarPasosTutorial() {
    String dpt = widget.partido.deporte.toLowerCase();
    
    _listaPasos = [
      PasoTutorial(
        titulo: Traductor.get('tut_1_t'),
        desc: Traductor.get('tut_1_d'),
        mostrarFlecha: false,
        icono: const Icon(Icons.sports, color: kVerdeNeon, size: 40),
      ),
      PasoTutorial(
        titulo: Traductor.get('tut_2_t'),
        desc: Traductor.get('tut_2_d'),
        key: _keyPlay,
        icono: const Icon(Icons.play_circle_fill, color: kCelestePlay, size: 40),
      ),
      PasoTutorial(
        titulo: Traductor.get('tut_resumen_t'),
        desc: Traductor.get('tut_resumen_d'),
        key: _keyScore,
        icono: const Icon(Icons.touch_app, color: kVerdeNeon, size: 40),
      ),
      PasoTutorial(
        titulo: Traductor.get('tut_edicion_t'),
        desc: Traductor.get('tut_edicion_d'),
        icono: const Icon(Icons.edit, color: kVerdeNeon, size: 40),
      ),
      PasoTutorial(
        titulo: Traductor.get('tut_3_t'),
        desc: Traductor.get('tut_3_d'),
        key: _keyNext,
        icono: const Icon(Icons.skip_next, color: Colors.orangeAccent, size: 40),
      ),
      PasoTutorial(
        titulo: Traductor.get('tut_4_t'),
        desc: Traductor.get('tut_4_d'),
        key: _keyUndo,
        icono: const Icon(Icons.undo, color: kVerdeNeon, size: 40),
      ),
    ];

    if (dpt == 'baseball') {
      _listaPasos.add(PasoTutorial(
        titulo: Traductor.get('tut_baseball_t'),
        desc: Traductor.get('tut_baseball_d'),
        key: _keyBaseball,
        icono: const Icon(Icons.grid_3x3, color: kVerdeNeon, size: 40),
      ));
    } else if (dpt == 'football americano') {
      _listaPasos.add(PasoTutorial(
        titulo: Traductor.get('tut_football_t'),
        desc: Traductor.get('tut_football_d'),
        key: _keyFootball,
        icono: const Icon(Icons.linear_scale, color: kVerdeNeon, size: 40),
      ));
    } else {
      _listaPasos.add(PasoTutorial(
        titulo: Traductor.get('tut_6_t'),
        desc: Traductor.get('tut_6_d'),
        key: _keyPossession,
        icono: const Icon(Icons.swap_horiz, color: kVerdeNeon, size: 40),
      ));
    }

    _listaPasos.add(PasoTutorial(
      titulo: Traductor.get('tut_5_t'),
      desc: Traductor.get('tut_5_d'),
      key: _keyNote,
      icono: const Icon(Icons.edit_note, color: kVerdeNeon, size: 40),
    ));

    _listaPasos.add(PasoTutorial(
      titulo: Traductor.get('tut_7_t'),
      desc: Traductor.get('tut_7_d'),
      key: _keyFinalize,
      icono: const Icon(Icons.sports_score, color: kRojoStop, size: 40),
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _guardarEstado();
    }
  }

  void _incrementarOrdenBateo(String equipo) {
    setState(() {
      if (equipo == 'Local') {
        widget.partido.ordenBateoLocal = (widget.partido.ordenBateoLocal % 9) + 1;
      } else {
        widget.partido.ordenBateoVisita = (widget.partido.ordenBateoVisita % 9) + 1;
      }
    });
    _guardarEstado();
  }

  void _guardarEstado() {
    QuantumStorage.guardarPartidoActivo(widget.partido);
  }

  int get _segundosTotales {
    int transcurrido = 0;
    if (_momentoInicioActual != null) {
      transcurrido = DateTime.now().difference(_momentoInicioActual!).inSeconds;
    }
    return _segundosAcumulados + transcurrido;
  }

  void _iniciarTimer() {
    if (_estaCorriendo) return;
    setState(() {
      _estaCorriendo = true;
      _momentoInicioActual = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
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
        if (_equipoPosesion != null) {
          widget.partido.posesionSegundos[_equipoPosesion!] = (widget.partido.posesionSegundos[_equipoPosesion!] ?? 0) + 1;
          
          String pKey = _periodoActual.toString();
          if (!widget.partido.posesionPorPeriodo.containsKey(pKey)) {
            widget.partido.posesionPorPeriodo[pKey] = {'Local': 0, 'Visita': 0};
          }
          widget.partido.posesionPorPeriodo[pKey]![_equipoPosesion!] = (widget.partido.posesionPorPeriodo[pKey]![_equipoPosesion!] ?? 0) + 1;
        }
        
        // LÓGICA SHOT CLOCK BÁSQUET
        if (widget.partido.deporte.toLowerCase().contains('basquet') || widget.partido.deporte.toLowerCase().contains('basket')) {
          if (_estaCorriendo && _shotClock > 0) {
            _shotClock--;
            if (_shotClock == 0) {
              HapticFeedback.heavyImpact(); 
            }
          }
        }
      });
      if (timer.tick % 5 == 0) _guardarEstado(); 
    });
  }

  void _pausarTimer() {
    if (!_estaCorriendo) return;
    _timer?.cancel();
    setState(() {
      _segundosAcumulados = _segundosTotales;
      _momentoInicioActual = null;
      _estaCorriendo = false;
    });
    _guardarEstado();
  }

  String _formatearOrdinal(int num) {
    if (num == 1) return '1er';
    if (num == 2) return '2do';
    if (num == 3) return '3ro';
    if (num == 4) return '4to';
    return '$num';
  }

  Future<void> _manejarFinPeriodo() async {
    _pausarTimer();
    String clavePeriodo = widget.partido.contadores.containsKey('Cuartos') ? 'Cuartos' : (widget.partido.contadores.containsKey('Entradas') ? 'Entradas' : 'Tiempos');
    int maxPeriodos = widget.partido.contadores[clavePeriodo] ?? 1;
    String nombreRef = Traductor.get(clavePeriodo).toUpperCase(); 

    if (_periodoActual < maxPeriodos) {
      bool confirmar = await _mostrarDialogo('${Traductor.get('finalizar_periodo_titulo')} ${_formatearOrdinal(_periodoActual)} $nombreRef?', Traductor.get('finalizar_periodo_msj'), Traductor.get('siguiente_mayus'));
      if (confirmar) {
        setState(() {
          widget.partido.logEventos.add('--- FIN DEL ${_formatearOrdinal(_periodoActual)} $nombreRef ---');
          _periodoActual++;
          _equipoPosesion = null; 
          _segundosAcumulados = 0;
          _momentoInicioActual = null;
        });
        _guardarEstado();
      }
    } else {
      await _mostrarDialogoOpcionesFinales();
    }
  }

  Future<void> _mostrarDialogoOpcionesFinales() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kRojoStop), borderRadius: BorderRadius.circular(10)),
        title: Text(Traductor.get('finalizar_encuentro_titulo'), style: const TextStyle(color: kRojoStop, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(Traductor.get('opciones_finalizar_encuentro'), style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(Traductor.get('cancelar_mayus'), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon),
            onPressed: () {
              Navigator.of(context).pop();
              _avanzarTiempoExtra();
            },
            child: Text(Traductor.get('tiempo_extra_mayus'), style: const TextStyle(color: kNegro, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRojoStop),
            onPressed: () {
              Navigator.of(context).pop();
              _ejecutarFinalizarPartido();
            },
            child: Text(Traductor.get('terminar_mayus'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  void _avanzarTiempoExtra() {
    String clavePeriodo = widget.partido.contadores.containsKey('Cuartos') ? 'Cuartos' : (widget.partido.contadores.containsKey('Entradas') ? 'Entradas' : 'Tiempos');
    String nombreRef = Traductor.get(clavePeriodo).toUpperCase(); 
    setState(() {
      widget.partido.contadores[clavePeriodo] = (widget.partido.contadores[clavePeriodo] ?? 1) + 1;
      widget.partido.logEventos.add('--- FIN DEL ${_formatearOrdinal(_periodoActual)} $nombreRef ---');
      _periodoActual++;
      _equipoPosesion = null; 
      _segundosAcumulados = 0;
      _momentoInicioActual = null;
    });
    _guardarEstado();
  }

  Future<void> _confirmarFinalizarDirecto() async {
    _pausarTimer();
    bool confirmar = await _mostrarDialogo(Traductor.get('finalizar_encuentro_titulo'), Traductor.get('confirmar_finalizar_directo'), Traductor.get('terminar_mayus'));
    if (confirmar) {
      _ejecutarFinalizarPartido();
    }
  }

  void _ejecutarFinalizarPartido() {
    setState(() {
      widget.partido.logEventos.add('--- FIN DEL PARTIDO ---');
      if (!partidosGuardados.contains(widget.partido)) {
        partidosGuardados.add(widget.partido);
        QuantumStorage.guardarPartidos(partidosGuardados);
      }
    });
    QuantumStorage.borrarPartidoActivo();
    AdHelper.mostrarInterstitialAd(onAdClosed: () { Navigator.popUntil(context, (route) => route.isFirst); }); 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Traductor.get('encuentro_finalizado_bitacora'), style: TextStyle(color: kVerdeNeon)), backgroundColor: kNegro));
  }

  Future<bool> _mostrarDialogo(String titulo, String mensaje, String btnAccion) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro, shape: RoundedRectangleBorder(side: const BorderSide(color: kRojoStop), borderRadius: BorderRadius.circular(10)),
        title: Text(titulo, style: const TextStyle(color: kRojoStop, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(mensaje, style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(Traductor.get('cancelar_mayus'), style: TextStyle(color: Colors.grey))),
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
    return await _mostrarDialogo(Traductor.get('abandonar_titulo'), Traductor.get('abandonar_msj'), Traductor.get('salir_todas_formas'));
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
            hintText: Traductor.get('nota_hint'),
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: kVerdeOscuro)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kVerdeNeon)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(Traductor.get('cancelar_mayus'), style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon),
            onPressed: () {
              if (notaController.text.trim().isNotEmpty) {
                String log = 'MIN $tiempoActual | 📝 NOTA: ${notaController.text.trim()}';
                setState(() {
                  widget.partido.registrarAccion(
                    equipo: 'Local', // O neutral
                    tipo: 'nota',
                    evento: 'Nota',
                    log: log
                  );
                });
                _guardarEstado();
              }
              Navigator.pop(context);
            },
            child: Text(Traductor.get('guardar_mayus'), style: TextStyle(color: kNegro, fontWeight: FontWeight.bold)),
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
        await _manejarVentanaCambios(equipoNombre, resultado);
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

          // LÓGICA AUTOMÁTICA FOOTBALL AMERICANO: resetear down al anotar
          if (widget.partido.deporte.toLowerCase() == 'football americano') {
            if (eventoMin.contains('touchdown') || eventoMin.contains('field goal') || eventoMin.contains('safety')) {
              widget.partido.downActual = 1;
              widget.partido.yardsParaPrimer = 10;
              // Cambia posesión al equipo que recibe tras el score
              widget.partido.posesionLocal = equipoNombre != 'Local';
            }
          }

          String nombreReal = equipoNombre == 'Local' ? widget.partido.local : widget.partido.visita;
          String log = 'MIN $tiempoActual | ${nombreReal.toUpperCase()}: $eventoRegistrado ($nombreActor)';
          
          widget.partido.registrarAccion(
            equipo: equipoNombre,
            tipo: eventoMin.contains('tarjeta') ? 'tarjeta' : (eventoMin.contains('gol') || eventoMin.contains('try') || eventoMin.contains('punto') ? 'anotacion' : 'stat'),
            evento: eventoRegistrado,
            datosExtra: {'jugador': jugadorNum, 'actor': nombreActor},
            log: log
          );
        });
        _guardarEstado();
      }
    }
  }

  Future<void> _manejarVentanaCambios(String equipoNombre, Map<String, dynamic> primerCambio) async {
    int maxC = widget.partido.contadores['Cambios'] ?? 0;
    int maxV = widget.partido.contadores['Ventanas'] ?? 0;
    
    bool primeraVez = true;
    var resActual = primerCambio;

    while (true) {
      int hechosC = widget.partido.stats[equipoNombre]!['CambiosHechos'] ?? 0;
      int hechasV = widget.partido.stats[equipoNombre]!['VentanasHechas'] ?? 0;

      if (primeraVez) {
        if (maxV > 0 && hechasV >= maxV) {
          bool confirmar = await _mostrarDialogo(Traductor.get('limite_ventanas_titulo'), Traductor.get('limite_ventanas_msj_1') + '$hechasV/$maxV' + Traductor.get('limite_ventanas_msj_2'), Traductor.get('si_mayus'));
          if (!confirmar) return; 
        }
        if (maxC > 0 && hechosC >= maxC) {
          bool confirmar = await _mostrarDialogo(Traductor.get('limite_cambios_titulo'), Traductor.get('limite_cambios_msj_1') + '$hechosC/$maxC' + Traductor.get('limite_cambios_msj_2'), Traductor.get('si_mayus'));
          if (!confirmar) return;
        }
      } else {
        if (maxC > 0 && hechosC >= maxC) {
          bool confirmar = await _mostrarDialogo(Traductor.get('limite_cambios_titulo'), Traductor.get('limite_cambios_msj_1') + '$hechosC/$maxC' + Traductor.get('limite_cambios_msj_2'), Traductor.get('si_mayus'));
          if (!confirmar) break; 
        }
      }

      setState(() {
        widget.partido.stats[equipoNombre]!['CambiosHechos'] = hechosC + 1;
        if (widget.partido.stats[equipoNombre]!.containsKey('Cambio')) {
           widget.partido.stats[equipoNombre]!['Cambio'] = (widget.partido.stats[equipoNombre]!['Cambio'] ?? 0) + 1;
        }
        if (primeraVez && maxV > 0) {
          widget.partido.stats[equipoNombre]!['VentanasHechas'] = hechasV + 1;
        }
        
        String jugSale = resActual['jugador'] ?? '';
        String jugEntra = resActual['jugadorEntra'] ?? '';
        String nombreSale = widget.partido.obtenerNombreJugador(equipoNombre, jugSale);
        String nombreEntra = widget.partido.obtenerNombreJugador(equipoNombre, jugEntra);
        
        String tiempoActual = _formatearTiempo();
        String actionId = DateTime.now().millisecondsSinceEpoch.toString();

        widget.partido.cambiosList[equipoNombre]!.add({
          'id': actionId,
          'minuto': tiempoActual,
          'sale': nombreSale,
          'entra': nombreEntra,
          'jugadorSaleNum': jugSale,
          'jugadorEntraNum': jugEntra
        });
        
        String nombreReal = equipoNombre == 'Local' ? widget.partido.local : widget.partido.visita;
        String log = 'MIN $tiempoActual | ${nombreReal.toUpperCase()}: Cambio ($nombreSale x $nombreEntra)';
        
        widget.partido.registrarAccion(
          id: actionId,
          equipo: equipoNombre,
          tipo: 'cambio',
          evento: 'Cambio',
          datosExtra: {'sale': nombreSale, 'entra': nombreEntra, 'jugadorSaleNum': jugSale, 'jugadorEntraNum': jugEntra},
          log: log
        );
      });
      _guardarEstado();

      primeraVez = false; 

      bool? otroCambio = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: kNegro,
          shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
          title: Text(Traductor.get('cambio_registrado'), style: TextStyle(color: kVerdeNeon, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text(Traductor.get('quiere_otro_cambio'), style: const TextStyle(color: Colors.white, fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(Traductor.get('no_mayus'), style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon),
              onPressed: () => Navigator.pop(context, true), 
              child: Text(Traductor.get('si_mayus'), style: TextStyle(color: kNegro, fontWeight: FontWeight.bold))
            ),
          ]
        )
      );

      if (otroCambio == null || !otroCambio) break; 

      var datosExtra = await _pedirDatosCambioExtra(equipoNombre);
      if (datosExtra == null) break; 
      
      resActual = datosExtra; 
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
                  Text(Traductor.get('registrar_cambio_extra'), textAlign: TextAlign.center, style: TextStyle(color: textoEq, fontSize: 16, fontWeight: FontWeight.bold)),
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
                              Text(Traductor.get('num_sale_rojo'), style: TextStyle(color: !editandoSecundario ? textoEq : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
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
                              Text(Traductor.get('num_entra_verde'), style: TextStyle(color: editandoSecundario ? textoEq : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
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
                TextButton(onPressed: () => Navigator.pop(context, null), child: Text(Traductor.get('cancelar_mayus'), style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: puedeConfirmar ? textoEq : Colors.grey),
                  onPressed: puedeConfirmar ? () {
                    Navigator.pop(context, {
                      'evento': 'Cambio', 
                      'jugador': valorPrimario,
                      'jugadorEntra': valorSecundario,
                    }); 
                  } : null,
                  child: Text(Traductor.get('confirmar_mayus'), style: TextStyle(color: puedeConfirmar ? kNegro : Colors.black45, fontWeight: FontWeight.bold)),
                )
              ],
            );
          }
        );
      }
    );
  }



  void _mostrarDetallePopUp(String titulo, List<dynamic> datos, String tipo, {String? equipoFijo}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon, width: 2), borderRadius: BorderRadius.circular(15)),
        title: Column(
          children: [
            Text(titulo, style: const TextStyle(color: kVerdeNeon, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            if (equipoFijo != null) 
              Text((equipoFijo == 'Local' ? widget.partido.local : widget.partido.visita).toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kVerdeNeon.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, color: kVerdeNeon, size: 12),
                  const SizedBox(width: 5),
                  Text(Traductor.get('mantenga_presionado_editar') ?? 'MANTÉN PRESIONADO PARA EDITAR', style: const TextStyle(color: kVerdeNeon, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: datos.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(Traductor.get('no_hay_registros'), style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (equipoFijo != null) 
                      _buildListaDetalle(datos, tipo, equipoFijo)
                    else ...[
                      // Grupo Local
                      _buildHeaderEquipoPopUp(widget.partido.local, widget.partido.localTexto),
                      _buildListaDetalle(datos.where((e) => e['equipo'] == 'Local').toList(), tipo, 'Local'),
                      
                      const SizedBox(height: 20),
                      
                      // Grupo Visita
                      _buildHeaderEquipoPopUp(widget.partido.visita, widget.partido.visitaTexto),
                      _buildListaDetalle(datos.where((e) => e['equipo'] == 'Visita').toList(), tipo, 'Visita'),
                    ]
                  ],
                ),
              )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(Traductor.get('cerrar_mayus'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          )
        ],
      )
    );
  }

  Widget _buildHeaderEquipoPopUp(String nombre, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(left: BorderSide(color: color, width: 3))
      ),
      child: Text(nombre.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildListaDetalle(List<dynamic> items, String tipo, String eq) {
    if (items.isEmpty) return const Padding(padding: EdgeInsets.all(10), child: Text('-', style: TextStyle(color: Colors.white24)));
    
    IconData iconoDeporte = DeporteConfig.datos[widget.partido.deporte]?['icono'] ?? Icons.sports;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
      itemBuilder: (context, i) {
        var d = items[i];
        
        String min = d['minuto']?.toString() ?? "";
        if (min.isEmpty && d['log'] != null) {
          min = d['log'].split('|')[0].replaceAll('MIN ', '').trim();
        }

        String displayJugador = "";
        if (tipo == 'cambio') {
          String numSale = d['jugadorSaleNum']?.toString() ?? "";
          String numEntra = d['jugadorEntraNum']?.toString() ?? "";
          if (numSale.isNotEmpty && numEntra.isNotEmpty) {
            displayJugador = "${widget.partido.obtenerNombreJugador(eq, numSale)} x ${widget.partido.obtenerNombreJugador(eq, numEntra)}";
          } else {
            displayJugador = "${d['sale'] ?? ''} x ${d['entra'] ?? ''}";
          }
        } else {
          String num = d['jugador']?.toString() ?? d['datosExtra']?['jugador']?.toString() ?? "";
          if (num.isNotEmpty && num != 'N/A') {
            displayJugador = widget.partido.obtenerNombreJugador(eq, num);
          } else {
            displayJugador = d['nombreCompleto']?.toString() ?? d['datosExtra']?['actor']?.toString() ?? Traductor.get('jugador_n_a');
          }
        }

        Widget rowContent;
        if (tipo == 'cambio') {
          rowContent = Row(
            children: [
              Text('MIN $min', style: const TextStyle(color: kVerdeNeon, fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 14), const SizedBox(width: 5), Expanded(child: Text(d['sale'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis))]),
                    Row(children: [const Icon(Icons.arrow_upward, color: Colors.green, size: 14), const SizedBox(width: 5), Expanded(child: Text(d['entra'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis))]),
                  ],
                ),
              ),
              const Icon(Icons.edit, color: kVerdeNeon, size: 14, shadows: [Shadow(color: kVerdeNeon, blurRadius: 10)]),
            ],
          );
        } else if (tipo == 'tarjeta') {
          Color colorT = _obtenerColorTarjeta(d['tipo']?.toString() ?? '');
          rowContent = Row(
            children: [
              Text('MIN $min', style: const TextStyle(color: kVerdeNeon, fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(width: 12),
              Container(width: 10, height: 14, decoration: BoxDecoration(color: colorT, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(child: Text(displayJugador, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)),
              const Icon(Icons.edit, color: kVerdeNeon, size: 14, shadows: [Shadow(color: kVerdeNeon, blurRadius: 10)]),
            ],
          );
        } else {
          rowContent = Row(
            children: [
              Text('MIN $min', style: const TextStyle(color: kVerdeNeon, fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(width: 12),
              Icon(iconoDeporte, color: Colors.white38, size: 14),
              const SizedBox(width: 10),
              Expanded(child: Text(displayJugador, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)),
              const Icon(Icons.edit, color: kVerdeNeon, size: 14, shadows: [Shadow(color: kVerdeNeon, blurRadius: 10)]),
            ],
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () {
            HapticFeedback.heavyImpact();
            Navigator.pop(context); 
            _mostrarOpcionesEdicion(d, tipo);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: rowContent,
          ),
        );
      },
    );
  }

  void _mostrarOpcionesEdicion(dynamic d, String tipo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: Text(Traductor.get('opciones').toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tipo == 'cambio') ...[
              ListTile(
                leading: const Icon(Icons.arrow_downward, color: Colors.redAccent),
                title: Text(Traductor.get('editar_salida') ?? 'EDITAR SALIDA', style: const TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _editarRegistro(d, tipo, esEntra: false); },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.green),
                title: Text(Traductor.get('editar_entrada') ?? 'EDITAR ENTRADA', style: const TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _editarRegistro(d, tipo, esEntra: true); },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.edit, color: kVerdeNeon),
                title: Text(Traductor.get('editar_jugador') ?? 'EDITAR JUGADOR', style: const TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _editarRegistro(d, tipo); },
              ),
            ],
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.delete, color: kRojoStop),
              title: Text(Traductor.get('eliminar_registro') ?? 'ELIMINAR REGISTRO', style: const TextStyle(color: kRojoStop)),
              onTap: () { Navigator.pop(context); _eliminarRegistro(d, tipo); },
            ),
          ],
        ),
      )
    );
  }

  void _eliminarRegistro(dynamic d, String tipo) {
    String? id = d['id'];
    if (id == null) return;

    setState(() {
      int idx = widget.partido.historialAcciones.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        var accion = widget.partido.historialAcciones[idx];
        String equipo = accion['equipo'];
        String evento = accion['evento'];
        String tReal = accion['tipo'] ?? tipo; // Usar el tipo real guardado

        // Decrementar contadores
        String keyStat = tReal == 'cambio' ? 'CambiosHechos' : evento;
        if (widget.partido.stats[equipo]!.containsKey(keyStat)) {
          widget.partido.stats[equipo]![keyStat] = (widget.partido.stats[equipo]![keyStat] ?? 1) - 1;
        }

        // Remover de bitácora
        widget.partido.logEventos.remove(accion['log']);
        widget.partido.historialAcciones.removeAt(idx);

        // Remover de listas específicas según el tipo real
        if (tReal == 'anotacion') widget.partido.anotaciones[equipo]?.removeWhere((e) => e['id'] == id);
        if (tReal == 'tarjeta') widget.partido.tarjetas[equipo]?.removeWhere((e) => e['id'] == id);
        if (tReal == 'cambio') widget.partido.cambiosList[equipo]?.removeWhere((e) => e['id'] == id);
      }
    });
    _guardarEstado();
  }

  void _editarRegistro(dynamic d, String tipo, {bool esEntra = false}) async {
    String? id = d['id'];
    if (id == null) return;

    int idx = widget.partido.historialAcciones.indexWhere((e) => e['id'] == id);
    if (idx == -1) return;
    var accion = widget.partido.historialAcciones[idx];
    String equipo = accion['equipo'];
    String evento = accion['evento'];
    String tReal = accion['tipo'] ?? tipo; // Usar el tipo real guardado

    String? nuevoNum = await _obtenerNumeroConTeclado(equipo, evento);
    if (nuevoNum == null || nuevoNum == "CANCEL") return;

    setState(() {
      String nuevoNombreComp = widget.partido.obtenerNombreJugador(equipo, nuevoNum);
      
      if (tReal == 'cambio') {
        var list = widget.partido.cambiosList[equipo]!;
        int itemIdx = list.indexWhere((e) => e['id'] == id);
        if (itemIdx != -1) {
          if (esEntra) {
            list[itemIdx]['entra'] = nuevoNombreComp;
            list[itemIdx]['jugadorEntraNum'] = nuevoNum;
          } else {
            list[itemIdx]['sale'] = nuevoNombreComp;
            list[itemIdx]['jugadorSaleNum'] = nuevoNum;
          }
          String s = list[itemIdx]['sale']!;
          String e = list[itemIdx]['entra']!;
          String nombreReal = equipo == 'Local' ? widget.partido.local : widget.partido.visita;
          String nuevoLog = 'MIN ${list[itemIdx]['minuto']} | ${nombreReal.toUpperCase()}: Cambio ($s x $e)';
          
          int logIdx = widget.partido.logEventos.indexOf(accion['log']);
          if (logIdx != -1) widget.partido.logEventos[logIdx] = nuevoLog;
          
          accion['log'] = nuevoLog;
          accion['datosExtra']['sale'] = s;
          accion['datosExtra']['entra'] = e;
        }
      } else {
        if (tReal == 'anotacion') {
          var item = widget.partido.anotaciones[equipo]?.firstWhere((e) => e['id'] == id);
          if (item != null) {
            item['jugador'] = nuevoNum;
            item['nombreCompleto'] = nuevoNombreComp;
          }
        } else if (tReal == 'tarjeta') {
          var item = widget.partido.tarjetas[equipo]?.firstWhere((e) => e['id'] == id);
          if (item != null) {
            item['jugador'] = nuevoNum;
            item['nombreCompleto'] = nuevoNombreComp;
          }
        }

        // Actualizar Log
        String nombreReal = equipo == 'Local' ? widget.partido.local : widget.partido.visita;
        String minText = accion['minuto'] ?? accion['log'].split('|')[0].trim().replaceFirst("MIN ", "");
        String nuevoLog = 'MIN $minText | ${nombreReal.toUpperCase()}: $evento ($nuevoNombreComp)';
        
        int logIdx = widget.partido.logEventos.indexOf(accion['log']);
        if (logIdx != -1) widget.partido.logEventos[logIdx] = nuevoLog;
        
        accion['log'] = nuevoLog;
        accion['datosExtra']['jugador'] = nuevoNum;
        accion['datosExtra']['actor'] = nuevoNombreComp;
      }
    });
    _guardarEstado();
  }

  @override void dispose() { 
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel(); 
    _blinkController.dispose();
    _ctrlBateador.dispose();
    _ctrlLanzador.dispose();
    super.dispose(); 
  }

  Color _obtenerColorTarjeta(String tipo) {
    if (tipo.toLowerCase().contains('roja')) return Colors.red;
    if (tipo.toLowerCase().contains('amarilla')) return kAmarilloTarjeta;
    if (tipo.toLowerCase().contains('verde')) return Colors.green;
    return Colors.white;
  }

  // Corregir Bateador/Lanzador según equipo y rol central de Partido
  String _obtenerRolEquipo(String equipo) {
    bool esLocal = equipo == 'Local';
    return esLocal ? widget.partido.rolLocal : (widget.partido.rolLocal == 'Bateador' ? 'Lanzador' : 'Bateador');
  }

  @override 
  Widget build(BuildContext context) {
    String clavePeriodo = widget.partido.contadores.containsKey('Cuartos') ? 'Cuartos' : (widget.partido.contadores.containsKey('Entradas') ? 'Entradas' : 'Tiempos');
    String nombrePeriodo = Traductor.get(clavePeriodo).toUpperCase(); 

    if (!_notaInicializada) {
      _notaX = (MediaQuery.of(context).size.width / 2) - 80; 
      _notaY = 260; 
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
          title: Text('TABLERO ${widget.partido.deporte.toUpperCase()}', style: const TextStyle(color: kVerdeNeon, fontSize: 12, letterSpacing: 2)),
          centerTitle: true,
          actions: [
            IconButton(
              key: _keyFinalize,
              icon: const Icon(Icons.sports_score, color: kRojoStop),
              onPressed: _confirmarFinalizarDirecto,
              tooltip: 'Finalizar Encuentro',
            ),
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white54, size: 20),
              onPressed: () => setState(() { _pasoTutorialIndex = 0; _mostrarTutorial = true; }),
            )
          ],
        ),
        body: SafeArea(
          child: Stack(
            key: _keyBody,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12, width: 1)), color: Color(0xFF0A0A0A)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    key: _keyScore,
                                    onTap: () => _mostrarDetallePopUp(Traductor.get('anotaciones_mayus') ?? 'ANOTACIONES', widget.partido.anotaciones['Local'] ?? [], 'anotacion', equipoFijo: 'Local'),
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
                                          Text(widget.partido.local.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          if (widget.partido.deporte.toLowerCase() == 'baseball') _buildInfoJugadorBaseball('Local'),
                                          const SizedBox(height: 5),
                                          Text('${widget.partido.obtenerPuntaje('Local')}', style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold, height: 1.0)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (widget.partido.deporte.toLowerCase() != 'football americano') ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => _mostrarDetallePopUp(Traductor.get('tarjetas_mayus') ?? 'TARJETAS', widget.partido.tarjetas['Local'] ?? [], 'tarjeta', equipoFijo: 'Local'),
                                      child: SizedBox(
                                        height: 40,
                                        child: Wrap(
                                          alignment: WrapAlignment.center, spacing: 4, runSpacing: 4,
                                          children: widget.partido.tarjetas['Local']!.take(6).map((t) => _buildMiniTarjetaFisica(t)).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            Column(
                              children: [
                                Text('VS', style: const TextStyle(color: Colors.white24, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Text('${_formatearOrdinal(_periodoActual)} $nombrePeriodo', style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                                Text(_formatearTiempo(), style: const TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      key: _keyUndo,
                                      icon: Icon(Icons.undo, color: widget.partido.historialAcciones.isEmpty ? Colors.white24 : kVerdeNeon, size: 22),
                                      onPressed: widget.partido.historialAcciones.isEmpty ? null : () {
                                        HapticFeedback.vibrate();
                                        setState(() => widget.partido.deshacerUltimaAccion());
                                        _guardarEstado();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    AnimatedBuilder(
                                      animation: _blinkController,
                                      builder: (context, child) => Opacity(
                                        opacity: _estaCorriendo ? 1.0 : _blinkController.value,
                                        child: IconButton(key: _keyPlay, icon: Icon(_estaCorriendo ? Icons.pause_circle_filled : Icons.play_circle_fill, color: kCelestePlay, size: 30), onPressed: _estaCorriendo ? _pausarTimer : _iniciarTimer, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                      )
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(key: _keyNext, icon: const Icon(Icons.skip_next, color: Colors.orangeAccent, size: 30), onPressed: _manejarFinPeriodo, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                  ],
                                ),
                                if (widget.partido.deporte.toLowerCase() == 'baseball') ...[
                                  const SizedBox(height: 10),
                                  Container(key: _keyBaseball, child: _buildDiamantesBases()),
                                  _buildContadorBaseballSimplificado(),
                                ],
                              ],
                            ),
                            
                            Expanded(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _mostrarDetallePopUp(Traductor.get('anotaciones_mayus') ?? 'ANOTACIONES', widget.partido.anotaciones['Visita'] ?? [], 'anotacion', equipoFijo: 'Visita'),
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
                                          Text(widget.partido.visita.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          if (widget.partido.deporte.toLowerCase() == 'baseball') _buildInfoJugadorBaseball('Visita'),
                                          const SizedBox(height: 5),
                                          Text('${widget.partido.obtenerPuntaje('Visita')}', style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold, height: 1.0)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (widget.partido.deporte.toLowerCase() != 'football americano') ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => _mostrarDetallePopUp(Traductor.get('tarjetas_mayus') ?? 'TARJETAS', widget.partido.tarjetas['Visita'] ?? [], 'tarjeta', equipoFijo: 'Visita'),
                                      child: SizedBox(
                                        height: 40,
                                        child: Wrap(
                                          alignment: WrapAlignment.center, spacing: 4, runSpacing: 4,
                                          children: widget.partido.tarjetas['Visita']!.take(6).map((t) => _buildMiniTarjetaFisica(t)).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (widget.partido.deporte.toLowerCase() == 'football americano') ...[
                          const SizedBox(height: 12),
                          Container(key: _keyFootball, child: _buildPanelFootballAmericano()),
                        ],
                      ],
                    ),
                  ),

                  Container( 
                    margin: const EdgeInsets.only(top: 5), padding: const EdgeInsets.symmetric(vertical: 4), 
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kVerdeOscuro, width: 2))), 
                    child: Row( 
                      mainAxisAlignment: MainAxisAlignment.spaceAround, 
                      children: [ 
                        GestureDetector(onTap: () => _mostrarDetallePopUp(Traductor.get('cambios_mayus') ?? 'CAMBIOS', widget.partido.cambiosList['Local'] ?? [], 'cambio', equipoFijo: 'Local'), child: _infoCambios('Local')), 
                        Text(Traductor.get('reservas_mayus'), style: TextStyle(color: kVerdeNeon, fontSize: 10, letterSpacing: 2)), 
                        GestureDetector(onTap: () => _mostrarDetallePopUp(Traductor.get('cambios_mayus') ?? 'CAMBIOS', widget.partido.cambiosList['Visita'] ?? [], 'cambio', equipoFijo: 'Visita'), child: _infoCambios('Visita')), 
                      ], 
                    ), 
                  ),
                  
                  Expanded( 
                    child: ReorderableListView(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), 
                      buildDefaultDragHandles: false, // Evita el tirador por defecto que se duplica
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Material(
                              elevation: 0,
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              child: child!,
                            );
                          },
                          child: child,
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final String item = _ordenStats.removeAt(oldIndex);
                          _ordenStats.insert(newIndex, item);
                        });
                        QuantumStorage.guardarOrdenStats(widget.partido.deporte.toLowerCase(), _ordenStats);
                      },
                      children: _generarListaEstadisticasUnificada()
                    ), 
                  ),
                  if (widget.partido.deporte.toLowerCase() != 'baseball' && widget.partido.deporte.toLowerCase() != 'football americano') Container(key: _keyPossession, child: _buildSelectorPosesion()),
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
                      double maxWidth = MediaQuery.of(context).size.width - 60;
                      double maxHeight = MediaQuery.of(context).size.height - 100;
                      if (_notaX < 0) _notaX = 0;
                      if (_notaY < 80) _notaY = 80; 
                      if (_notaX > maxWidth) _notaX = maxWidth;
                      if (_notaY > maxHeight) _notaY = maxHeight;
                    });
                  },
                  onTap: _abrirAnotadorLibre,
                  child: Container(
                    key: _keyNote,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kVerdeNeon,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_note, color: kNegro, size: 18),
                        const SizedBox(width: 4),
                        Text(Traductor.get('nota_mayus'), style: const TextStyle(color: kNegro, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              if (_mostrarTutorial) _buildOverlayTutorial(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayTutorial() {
    if (_listaPasos.isEmpty) return const SizedBox.shrink();
    if (_pasoTutorialIndex >= _listaPasos.length) return const SizedBox.shrink();

    final paso = _listaPasos[_pasoTutorialIndex];
    GlobalKey? keyActual = paso.key;
    bool mostrarFlecha = paso.mostrarFlecha;
    Widget? iconoPaso = paso.icono;
    String titulo = paso.titulo;
    String desc = paso.desc;

    Offset pos = Offset.zero;
    Size size = Size.zero;
    if (keyActual != null && keyActual.currentContext != null) {
      final RenderBox box = keyActual.currentContext!.findRenderObject() as RenderBox;
      final RenderBox bodyBox = _keyBody.currentContext!.findRenderObject() as RenderBox;
      
      // Calculamos la posición relativa al cuerpo (Stack)
      pos = bodyBox.globalToLocal(box.localToGlobal(Offset.zero));
      size = box.size;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_pasoTutorialIndex < _listaPasos.length - 1) {
            _pasoTutorialIndex++;
          } else {
            _mostrarTutorial = false;
            QuantumStorage.setTutorialVisto(true);
          }
        });
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Fondo Oscuro Sólido
            Container(color: Colors.black.withOpacity(0.6)),
            
            // Foco de luz
            if (keyActual != null)
              Positioned(
                left: pos.dx - 5,
                top: pos.dy - 5,
                child: Container(
                  width: size.width + 10,
                  height: size.height + 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kVerdeNeon, width: 3),
                  ),
                ),
              ),

            // Flecha
            if (keyActual != null && mostrarFlecha)
              Positioned(
                left: pos.dx + (size.width / 2) - 20,
                top: pos.dy > MediaQuery.of(context).size.height / 2 ? pos.dy - 60 : pos.dy + size.height + 15,
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0, end: 10),
                  builder: (context, double val, child) => Padding(
                    padding: EdgeInsets.only(top: pos.dy > MediaQuery.of(context).size.height / 2 ? 10 - val : val),
                    child: Icon(
                      pos.dy > MediaQuery.of(context).size.height / 2 ? Icons.keyboard_double_arrow_down : Icons.keyboard_double_arrow_up,
                      color: kVerdeNeon,
                      size: 40,
                    ),
                  ),
                ),
              ),

            // Cartel Informativo
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F0F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kVerdeNeon.withOpacity(0.3), width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 30, spreadRadius: 5)]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (iconoPaso != null) ...[
                      iconoPaso,
                      const SizedBox(height: 20),
                    ],
                    Text(titulo, textAlign: TextAlign.center, style: const TextStyle(color: kVerdeNeon, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.5)),
                    const SizedBox(height: 15),
                    Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontWeight: FontWeight.w400)),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${Traductor.get('tut_paso')} ${_pasoTutorialIndex + 1} ${Traductor.get('tut_de')} ${_listaPasos.length}", style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Text(Traductor.get('tut_siguiente'), style: TextStyle(color: kVerdeNeon.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 5),
                              Icon(Icons.arrow_forward_ios, color: kVerdeNeon.withOpacity(0.8), size: 10),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            // Botón Salir
            Positioned(
              top: 20,
              right: 20,
              child: SafeArea(
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _mostrarTutorial = false;
                      QuantumStorage.setTutorialVisto(true);
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.white38),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoCambios(String equipo) {
    int maxC = widget.partido.contadores['Cambios'] ?? 0;
    int maxV = widget.partido.contadores['Ventanas'] ?? 0;
    int hechosC = widget.partido.stats[equipo]?['CambiosHechos'] ?? 0;
    int hechasV = widget.partido.stats[equipo]?['VentanasHechas'] ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.swap_horizontal_circle, color: kVerdeNeon.withOpacity(0.5), size: 14),
        const SizedBox(width: 4),
        Text('$hechosC/$maxC', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        if (maxV > 0) ...[
          const SizedBox(width: 4),
          Text('V: $hechasV/$maxV', style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ],
        const SizedBox(width: 6),
        const Icon(Icons.remove_red_eye, color: Colors.white70, size: 12),
      ],
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
        WidgetTarjetaFisicaQuantum(
          color: colorTarjeta, 
          numero: numJugador,
          height: 24,
        ),
        if (mostrarTimer) ...[
          const SizedBox(height: 2),
          Text(textoTimer, style: TextStyle(color: colorTarjeta, fontSize: 8, fontWeight: FontWeight.bold))
        ]
      ],
    );
  }

  List<Widget> _generarListaEstadisticasUnificada() { 
    List<Widget> filasRapidas = []; 
    List<Widget> filasPasivas = []; 
    
    final List<String> eventosRapidos = [
      'Gol', 'Try (5 pts)', 'Conversión (2 pts)', 'Penal (3 pts)', 'Drop (3 pts)',
      'Tiro Libre (1 pt)', 'Doble (2 pts)', 'Triple (3 pts)', 'Touchdown (6 pts)',
      'Field Goal (3 pts)', 'Extra Point (1 pt)', 'Safety (2 pts)', 'Carrera', 'Home Run',
      'Corner', 'Falta', 'Remates', 'Remates al arco', 'Penal', 'Falta Personal', 'Falta Técnica',
      'Hit', 'Error', 'Out', 'Base por Bolas', 'Two-Point Conv. (2 pts)', 'Sack', 'Intercepción', 'Fumble Recuperado', 'Punt',
      'Line Out', 'Scrum', 'Rebotes', 'Tapones', 'Ponche', 'Castigo', 'Asistencia', 'Tarjeta Amarilla', 'Tarjeta Roja', 'Tarjeta Verde', 'Cambio'
    ];

    int currentIdx = 0;
    for (String evento in _ordenStats) {
      if (evento == 'CambiosHechos' || evento == 'VentanasHechas') continue;
      
      final int dragIndex = currentIdx;
      currentIdx++;

      int cantLocal = widget.partido.stats['Local']![evento] ?? 0;
      int cantVisita = widget.partido.stats['Visita']![evento] ?? 0;
      // Ahora todos los stats en el tablero son "rápidos" (tienen el botón +)
      bool rapido = true;

        Widget fila = Container( 
          key: ValueKey(evento),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1)
          ),
          child: Row( 
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [ 
              // Lado Local
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4), 
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(6)
                      ), 
                      child: Text('$cantLocal', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                    )
                  ),
                  const SizedBox(width: 6),
                  if (rapido) _buildBotonRapido('Local', evento) else const SizedBox(width: 36),
                ],
              ),

              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        Traductor.get(evento).toUpperCase(), 
                        textAlign: TextAlign.center, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(width: 6),
                    // BOTÓN OJO (DETALLE)
                    GestureDetector(
                      onTap: () {
                        var items = widget.partido.historialAcciones
                            .where((e) => e['evento'] == evento)
                            .toList();
                        _mostrarDetallePopUp(Traductor.get(evento).toUpperCase(), items, 'stat');
                      },
                      child: const Icon(Icons.visibility, color: kVerdeNeon, size: 14),
                    ),
                    const SizedBox(width: 8),
                    // TIRADOR DE ARRASTRE
                    ReorderableDragStartListener(
                      index: dragIndex,
                      child: const Icon(Icons.drag_indicator, color: kVerdeNeon, size: 16),
                    ),
                  ],
                )
              ),

              // Lado Visita
              Row(
                children: [
                  if (rapido) _buildBotonRapido('Visita', evento) else const SizedBox(width: 36),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4), 
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(6)
                      ), 
                      child: Text('$cantVisita', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                    )
                  ),
                ],
              ),
            ], 
          ), 
        );

        filasRapidas.add(fila);
    }

    return filasRapidas; 
  }

  Widget _buildShotClock() {
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        bool critico = _shotClock <= 5 && _shotClock > 0;
        bool agotado = _shotClock == 0;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: agotado ? kRojoStop : (critico ? Colors.orange : kVerdeNeon.withOpacity(0.3)),
              width: 2
            ),
            boxShadow: (critico || agotado) ? [
              BoxShadow(color: (agotado ? kRojoStop : Colors.orange).withOpacity(0.3), blurRadius: 10, spreadRadius: 1)
            ] : []
          ),
          child: Row(
            children: [
              // Botón 14s (Izquierda)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _shotClock = 14);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('RESET', style: TextStyle(color: Colors.white24, fontSize: 8)),
                          Text('14', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Contador Central
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  border: Border.symmetric(vertical: BorderSide(color: Colors.white10, width: 1))
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_shotClock',
                        style: TextStyle(
                          color: agotado 
                            ? kRojoStop.withOpacity(_blinkController.value) 
                            : (critico ? Colors.orange : kVerdeNeon),
                          fontSize: 32,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace'
                        ),
                      ),
                      Text(
                        Traductor.get('reloj_tiro').toUpperCase(),
                        style: TextStyle(
                          color: agotado ? kRojoStop : (critico ? Colors.orange : Colors.white24),
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botón 24s (Derecha)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _shotClock = 24);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('RESET', style: TextStyle(color: Colors.white24, fontSize: 8)),
                          Text('24', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildBotonRapido(String equipo, String evento) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: kVerdeOscuro.withOpacity(0.4), 
          shape: BoxShape.circle, 
          border: Border.all(color: kVerdeNeon.withOpacity(0.6), width: 1.5),
        ),
        child: const Icon(Icons.add, color: kVerdeNeon, size: 16),
      ),
      onPressed: () async {
        debugPrint("QUANTUM: Presionado + para $equipo - $evento");
        HapticFeedback.mediumImpact();
        
        if (evento == 'Cambio') {
          var res = await _pedirDatosCambioExtra(equipo);
          if (res != null) {
            await _manejarVentanaCambios(equipo, res);
          }
        } else {
          _mostrarDialogoSelectorJugador(equipo, evento);
        }
      },
    );
  }

  Future<String?> _obtenerNumeroConTeclado(String equipo, String evento) async {
    String numero = "";
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: kVerdeNeon, width: 2), 
              borderRadius: BorderRadius.circular(20)
            ),
            child: Container(
              padding: const EdgeInsets.all(15),
              width: 220,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Traductor.get(evento).toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  Text(equipo == 'Local' ? widget.partido.local.toUpperCase() : widget.partido.visita.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(height: 10),
                  Container(
                    height: 50,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                    child: Text(numero.isEmpty ? "#" : numero, style: const TextStyle(color: kVerdeNeon, fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.5,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (int i = 1; i <= 9; i++) _buildBotonTeclado("$i", (v) => setDialogState(() => numero += v)),
                      _buildBotonTeclado("C", (v) => setDialogState(() => numero = ""), color: kRojoStop.withOpacity(0.2), textColor: kRojoStop),
                      _buildBotonTeclado("0", (v) => setDialogState(() => numero += v)),
                      _buildBotonTeclado("OK", (v) => Navigator.pop(context, numero), color: kVerdeNeon.withOpacity(0.2), textColor: kVerdeNeon),
                    ],
                  ),
                  const SizedBox(height: 5),
                  TextButton(
                    onPressed: () => Navigator.pop(context, "CANCEL"), 
                    child: Text(Traductor.get('cancelar_mayus'), style: const TextStyle(color: Colors.white24, fontSize: 12))
                  ),
                ],
              ),
            ),
          );
        }
      )
    );
  }

  void _mostrarDialogoSelectorJugador(String equipo, String evento) async {
    final result = await _obtenerNumeroConTeclado(equipo, evento);
    if (result != null && result != "CANCEL") {
      _ejecutarRegistroAccion(equipo, evento, result);
    }
  }

  Widget _buildBotonTeclado(String texto, Function(String) onTap, {Color? color, Color? textColor}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(texto);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color ?? Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (textColor ?? Colors.white).withOpacity(0.1))
        ),
        child: Center(
          child: Text(texto, style: TextStyle(color: textColor ?? Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _ejecutarRegistroAccion(String equipo, String evento, String numeroJugador) {
    setState(() {
      // INCREMENTAR STAT
      String keyStat = evento == 'Cambio' ? 'CambiosHechos' : evento;
      widget.partido.stats[equipo]![keyStat] = (widget.partido.stats[equipo]![keyStat] ?? 0) + 1;
      
      // LÓGICA DE PUNTOS SEGÚN EVENTO
      int puntos = 0;
      if (evento.contains('Gol')) puntos = 1;
      else if (evento.contains('Try')) puntos = 5;
      else if (evento.contains('Conversión')) puntos = 2;
      else if (evento.contains('Penal (3 pts)')) puntos = 3;
      else if (evento.contains('Drop')) puntos = 3;
      else if (evento.contains('Tiro Libre')) puntos = 1;
      else if (evento.contains('Doble')) puntos = 2;
      else if (evento.contains('Triple')) puntos = 3;
      else if (evento.contains('Touchdown')) puntos = 6;
      else if (evento.contains('Field Goal')) puntos = 3;
      else if (evento.contains('Extra Point')) puntos = 1;
      else if (evento.contains('Safety')) puntos = 2;
      else if (evento.contains('Carrera')) puntos = 1;
      else if (evento.contains('Home Run')) puntos = 1;

      String actionId = DateTime.now().millisecondsSinceEpoch.toString();

      if (puntos > 0) {
        String tiempoAct = _formatearTiempo();
        widget.partido.anotaciones[equipo]!.add({
          'id': actionId,
          'tipo': evento,
          'minuto': tiempoAct,
          'jugador': numeroJugador.isEmpty ? 'N/A' : numeroJugador,
          'nombreCompleto': numeroJugador.isEmpty ? 'N/A' : widget.partido.obtenerNombreJugador(equipo, numeroJugador),
          'puntos': puntos.toString()
        });
      }

      // REGISTRAR TARJETAS
      if (evento.contains('Tarjeta')) {
        String tiempoAct = _formatearTiempo();
        var nuevaT = {
          'id': actionId,
          'tipo': evento,
          'minuto': tiempoAct,
          'jugador': numeroJugador.isEmpty ? 'N/A' : numeroJugador,
          'nombreCompleto': numeroJugador.isEmpty ? 'N/A' : widget.partido.obtenerNombreJugador(equipo, numeroJugador),
        };
        if (widget.partido.deporte.toLowerCase() == 'rugby' && evento.contains('Amarilla')) {
          nuevaT['segundosRestantes'] = ((widget.partido.contadores['Min. Amarilla'] ?? 10) * 60).toString();
        }
        widget.partido.tarjetas[equipo]!.add(nuevaT);
      }

      // REGISTRAR CAMBIOS
      if (evento == 'Cambio') {
        String tiempoAct = _formatearTiempo();
        widget.partido.cambiosList[equipo]!.add({
          'id': actionId,
          'tipo': 'Cambio',
          'minuto': tiempoAct,
          'jugador': numeroJugador.isEmpty ? 'N/A' : numeroJugador,
          'nombreCompleto': numeroJugador.isEmpty ? 'N/A' : widget.partido.obtenerNombreJugador(equipo, numeroJugador),
        });
      }

      // LOG FINAL
      String nombreEq = equipo == 'Local' ? widget.partido.local : widget.partido.visita;
      String tiempoAct = _formatearTiempo();
      String logText = 'MIN $tiempoAct | ${nombreEq.toUpperCase()}: $evento';
      String nombreActor = numeroJugador.isEmpty ? 'N/A' : widget.partido.obtenerNombreJugador(equipo, numeroJugador);
      if (numeroJugador.isNotEmpty) {
        logText += ' ($nombreActor)';
      }
      
      String tipoAccion = evento.toLowerCase().contains('tarjeta') 
          ? 'tarjeta' 
          : (puntos > 0 ? 'anotacion' : 'stat');

      widget.partido.registrarAccion(
        id: actionId,
        equipo: equipo, 
        tipo: tipoAccion, 
        evento: evento, 
        datosExtra: {'jugador': numeroJugador, 'actor': nombreActor},
        log: logText
      );
      
      // LÓGICA AUTOMÁTICA BASEBALL
      if (widget.partido.deporte.toLowerCase() == 'baseball') {
        if (evento == 'Hit' || evento == 'Home Run' || evento == 'Error') {
          widget.partido.balls = 0;
          widget.partido.strikes = 0;
          _incrementarOrdenBateo(widget.partido.rolLocal == 'Bateador' ? 'Local' : 'Visita');
        } else if (evento == 'Out' || evento == 'Ponche') {
          _incrementarOut();
        }
      }
    });
    _guardarEstado();
  }

  Widget _buildSelectorPosesion() {
    if (widget.partido.deporte.toLowerCase().contains('basquet') || widget.partido.deporte.toLowerCase().contains('basket')) {
      return _buildShotClock();
    }

    String pKey = _periodoActual.toString();
    int tLocal = widget.partido.posesionPorPeriodo[pKey]?['Local'] ?? 0;
    int tVisita = widget.partido.posesionPorPeriodo[pKey]?['Visita'] ?? 0;
    int total = tLocal + tVisita;
    
    double pLocal = total == 0 ? 50 : (tLocal / total) * 100;
    double pVisita = total == 0 ? 50 : (tVisita / total) * 100;

    Color colorL = (widget.partido.localFondo.computeLuminance() < 0.1) ? widget.partido.localTexto : widget.partido.localFondo;
    Color colorV = (widget.partido.visitaFondo.computeLuminance() < 0.1) ? widget.partido.visitaTexto : widget.partido.visitaFondo;

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        bool sinSeleccion = _equipoPosesion == null;
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              // Toggle Directo Local <-> Visita
              if (_equipoPosesion == 'Local') _equipoPosesion = 'Visita';
              else if (_equipoPosesion == 'Visita') _equipoPosesion = 'Local';
              else _equipoPosesion = 'Local'; // Por defecto si estaba en pausa
            });
          },
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            HapticFeedback.lightImpact();
            setState(() {
              if (details.primaryVelocity! > 0) _equipoPosesion = 'Visita';
              else if (details.primaryVelocity! < 0) _equipoPosesion = 'Local';
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5), // Ancho total
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05), 
              borderRadius: BorderRadius.circular(30),
              // GLOW EFECTO QUANTUM SIEMPRE VISIBLE SI NO ES PAUSA
              boxShadow: !sinSeleccion ? [
                BoxShadow(
                  color: (_equipoPosesion == 'Local' ? colorL : colorV).withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2
                )
              ] : [],
              border: Border.all(
                color: sinSeleccion 
                  ? kVerdeNeon.withOpacity(_blinkController.value * 0.7) 
                  : (_equipoPosesion == 'Local' ? colorL : colorV).withOpacity(0.5),
                width: 1.5
              ),
            ),
            child: Row(
              children: [
                _buildItemPosesion('Local', widget.partido.local, pLocal, colorL, widget.partido.localTexto),
                
                // BOTÓN DE PAUSA CENTRAL
                GestureDetector(
                  onTap: () {
                    HapticFeedback.vibrate();
                    setState(() {
                      _equipoPosesion = null; // Activa la pausa
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sinSeleccion ? kVerdeNeon.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sinSeleccion ? Icons.play_arrow : Icons.pause, 
                          color: sinSeleccion 
                              ? kVerdeNeon.withOpacity(_blinkController.value) 
                              : Colors.white.withOpacity(0.3), 
                          size: 14
                        ),
                        Text(
                          'POSESIÓN', 
                          style: TextStyle(
                            color: sinSeleccion 
                                ? kVerdeNeon.withOpacity(_blinkController.value) 
                                : Colors.white.withOpacity(0.15), 
                            fontSize: 7, 
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 0.5
                          )
                        ),
                      ],
                    ),
                  ),
                ),

                _buildItemPosesion('Visita', widget.partido.visita, pVisita, colorV, widget.partido.visitaTexto),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildItemPosesion(String equipo, String nombre, double porcentaje, Color colorFondo, Color colorTexto) {
    bool activo = _equipoPosesion == equipo;
    bool esLocal = equipo == 'Local';

    return Expanded(
      child: IgnorePointer( // El toque lo maneja el padre
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: activo ? colorFondo.withOpacity(0.8) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: activo ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) : null,
          ),
          child: esLocal 
            ? Row(
                children: [
                  Expanded(child: Text(nombre.toUpperCase(), overflow: TextOverflow.ellipsis, style: TextStyle(color: activo ? Colors.white : Colors.white54, fontSize: 9, fontWeight: activo ? FontWeight.bold : FontWeight.normal, letterSpacing: 1))),
                  const SizedBox(width: 5),
                  Text('${porcentaje.toStringAsFixed(0)}%', style: TextStyle(color: activo ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
                  if (activo) ...[const SizedBox(width: 4), Icon(Icons.timer, color: Colors.white, size: 12)],
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (activo) ...[Icon(Icons.timer, color: Colors.white, size: 12), const SizedBox(width: 4)],
                  Text('${porcentaje.toStringAsFixed(0)}%', style: TextStyle(color: activo ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 5),
                  Expanded(child: Text(nombre.toUpperCase(), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: TextStyle(color: activo ? Colors.white : Colors.white54, fontSize: 9, fontWeight: activo ? FontWeight.bold : FontWeight.normal, letterSpacing: 1))),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildDiamantesYContadoresBaseball() {
    return const SizedBox.shrink(); // Obsoleto, se movió al header
  }

  Widget _buildContadorBaseballSimplificado() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // GRUPO BALLS - STRIKES
        _buildItemContadorTactil('balls', '${widget.partido.balls}', kCelestePlay, _incrementarBall),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('-', style: TextStyle(color: Colors.white24, fontSize: 20)),
        ),
        _buildItemContadorTactil('strikes', '${widget.partido.strikes}', kRojoStop, _incrementarStrike),
        
        // DIVISOR
        Container(margin: const EdgeInsets.symmetric(horizontal: 15), width: 1, height: 25, color: Colors.white12),

        // CONTADOR OUTS
        _buildItemContadorTactil('outs', '${widget.partido.outs}', kDorado, _incrementarOut),
      ],
    );
  }

  Widget _buildItemContadorTactil(String etiqueta, String valor, Color color, VoidCallback accion) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        accion();
      },
      child: Column(
        children: [
          Text(Traductor.get(etiqueta), style: const TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold)),
          Text(valor, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildContadorIndividual(String etiqueta, int valor, int max, VoidCallback accion) {
    return Column(
      children: [
        Text(Traductor.get(etiqueta.toLowerCase()), style: const TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 1)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            accion();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: kVerdeNeon.withOpacity(0.3))
            ),
            child: Row(
              children: [
                Text('$valor', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('/$max', style: const TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDiamantesBases() {
    return SizedBox(
      width: 100,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 2da Base (Arriba)
          Positioned(top: 0, child: _buildBaseDiamond(2)),
          // 3era Base (Izquierda)
          Positioned(left: 10, top: 25, child: _buildBaseDiamond(3)),
          // 1era Base (Derecha)
          Positioned(right: 10, top: 25, child: _buildBaseDiamond(1)),
        ],
      ),
    );
  }

  Widget _buildBaseDiamond(int num) {
    bool ocupada = widget.partido.bases[num] ?? false;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          widget.partido.bases[num] = !ocupada;
        });
        _guardarEstado();
      },
      child: Transform.rotate(
        angle: 45 * 3.1415927 / 180,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: ocupada ? kDorado : Colors.black,
            border: Border.all(color: ocupada ? Colors.white : Colors.white24, width: 1.5),
            boxShadow: ocupada ? [BoxShadow(color: kDorado.withOpacity(0.5), blurRadius: 8)] : []
          ),
        ),
      ),
    );
  }

  Widget _buildInfoJugadorBaseball(String equipo) {
    bool esLocal = equipo == 'Local';
    String rolActual = esLocal ? widget.partido.rolLocal : (widget.partido.rolLocal == 'Bateador' ? 'Lanzador' : 'Bateador');
    String idActual = rolActual == 'Bateador' ? widget.partido.idBateadorActual : widget.partido.idLanzadorActual;
    
    if (widget.partido.deporte.toLowerCase() == 'baseball' && !_inicializadoBaseball) {
      _ctrlBateador.text = widget.partido.idBateadorActual;
      _ctrlLanzador.text = widget.partido.idLanzadorActual;
      _inicializadoBaseball = true;
    }

    TextEditingController ctrl = rolActual == 'Bateador' ? _ctrlBateador : _ctrlLanzador;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(Traductor.get(rolActual.toLowerCase()), style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                if (rolActual == 'Lanzador') ...[
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (esLocal) widget.partido.lanzamientosLocal++;
                        else widget.partido.lanzamientosVisita++;
                      });
                      _guardarEstado();
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.sports_baseball, color: Colors.white38, size: 12),
                        const SizedBox(width: 2),
                        Text('${esLocal ? widget.partido.lanzamientosLocal : widget.partido.lanzamientosVisita}', style: const TextStyle(color: kVerdeNeon, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
                if (rolActual == 'Bateador') ...[
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _incrementarOrdenBateo(equipo);
                    },
                    child: Row(
                      children: [
                        Text(Traductor.get('orden'), style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 2),
                        Text('${esLocal ? widget.partido.ordenBateoLocal : widget.partido.ordenBateoVisita}', style: const TextStyle(color: kVerdeNeon, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 45, // Reducido de 60 a 45
            child: TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                border: InputBorder.none,
                hintText: '#',
                hintStyle: TextStyle(color: Colors.white10)
              ),
              onChanged: (val) {
                setState(() {
                  if (rolActual == 'Bateador') widget.partido.idBateadorActual = val;
                  else widget.partido.idLanzadorActual = val;
                });
                _guardarEstado();
              },
            ),
          ),
          Text(
            widget.partido.obtenerNombreJugador(equipo, idActual).split(' ').skip(1).join(' '),
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 8) // Reducido de 9 a 8
          )
        ],
      ),
    );
  }

  void _incrementarStrike() {
    setState(() {
      widget.partido.strikes++;
      // Aumentar lanzamientos automáticamente con un Strike
      if (widget.partido.rolLocal == 'Lanzador') widget.partido.lanzamientosLocal++;
      else widget.partido.lanzamientosVisita++;
      
      if (widget.partido.strikes >= 3) {
        // AUTOMACIÓN: PONCHE (Delegamos a _incrementarOut)
        _incrementarOut();
        String eqDefensa = widget.partido.rolLocal == 'Lanzador' ? 'Local' : 'Visita';
        String nombreReal = eqDefensa == 'Local' ? widget.partido.local : widget.partido.visita;
        String tiempoAct = _formatearTiempo();
        String log = 'MIN $tiempoAct | ${nombreReal.toUpperCase()}: Ponche (Out)';
        
        widget.partido.registrarAccion(
          equipo: eqDefensa,
          tipo: 'stat',
          evento: 'Ponche',
          log: log
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡OUT! PONCHE REGISTRADO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: kRojoStop));
      }
    });
    _guardarEstado();
  }

  void _incrementarBall() {
    setState(() {
      widget.partido.balls++;
      // Aumentar lanzamientos automáticamente con una Ball
      if (widget.partido.rolLocal == 'Lanzador') widget.partido.lanzamientosLocal++;
      else widget.partido.lanzamientosVisita++;

      if (widget.partido.balls >= 4) {
        // AUTOMACIÓN: BASE POR BOLAS
        _incrementarOrdenBateo(widget.partido.rolLocal == 'Bateador' ? 'Local' : 'Visita');
        widget.partido.balls = 0;
        widget.partido.strikes = 0;
        String eqBateo = widget.partido.rolLocal == 'Bateador' ? 'Local' : 'Visita';
        String nombreReal = eqBateo == 'Local' ? widget.partido.local : widget.partido.visita;
        String tiempoAct = _formatearTiempo();
        String log = 'MIN $tiempoAct | ${nombreReal.toUpperCase()}: Base por Bolas (Walk)';
        
        widget.partido.registrarAccion(
          equipo: eqBateo,
          tipo: 'stat',
          evento: 'Base por Bolas',
          log: log
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡BASE POR BOLAS REGISTRADA!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: kCelestePlay));
      }
    });
    _guardarEstado();
  }

  void _incrementarOut() {
    setState(() {
      widget.partido.outs++;
      widget.partido.balls = 0;
      widget.partido.strikes = 0;
      _incrementarOrdenBateo(widget.partido.rolLocal == 'Bateador' ? 'Local' : 'Visita');
      if (widget.partido.outs >= 3) {
        _confirmarCambioRoles();
      }
    });
    _guardarEstado();
  }

  void _confirmarCambioRoles() async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: Text(Traductor.get('confirmar_cambio_roles'), style: const TextStyle(color: kVerdeNeon, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(Traductor.get('no_mayus'), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon),
            onPressed: () => Navigator.pop(context, true),
            child: Text(Traductor.get('si_mayus'), style: const TextStyle(color: kNegro, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );

    if (confirmar == true) {
      setState(() {
        widget.partido.rolLocal = (widget.partido.rolLocal == 'Bateador' ? 'Lanzador' : 'Bateador');
        widget.partido.balls = 0;
        widget.partido.strikes = 0;
        widget.partido.outs = 0;
        widget.partido.bases = {1: false, 2: false, 3: false};
        widget.partido.logEventos.add('--- CAMBIO DE ROLES: EL EQUIPO BATEADOR CAMBIA ---');
      });
      _guardarEstado();
    }
  }
  // ─────────────────────────────────────────────────────────────
  //  PANEL EXCLUSIVO FOOTBALL AMERICANO — DOWN & DISTANCE
  // ─────────────────────────────────────────────────────────────

  static const List<String> _downLabels = ['1ro', '2do', '3ro', '4to'];

  Widget _buildPanelFootballAmericano() {
    final p = widget.partido;
    Color colorPosesion = p.posesionLocal
        ? ((p.localFondo.computeLuminance() < 0.1) ? p.localTexto : p.localFondo)
        : ((p.visitaFondo.computeLuminance() < 0.1) ? p.visitaTexto : p.visitaFondo);

    String equipoBalonNombre = p.posesionLocal ? p.local : p.visita;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorPosesion.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FILA 1: POSESIÓN Y DOWN/DISTANCIA (TODO EN UNA FILA PARA AHORRAR ESPACIO)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Local button
              Flexible(
                flex: 2,
                child: GestureDetector(
                  onTap: () { if (!p.posesionLocal) { setState(() => p.posesionLocal = true); _guardarEstado(); } },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: p.posesionLocal ? colorPosesion.withOpacity(0.8) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: p.posesionLocal ? colorPosesion : Colors.white12),
                    ),
                    child: Center(child: Text(p.local.toUpperCase(), style: TextStyle(color: p.posesionLocal ? Colors.white : Colors.white38, fontSize: 8, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),

              // Down Display
              GestureDetector(
                onTap: () { setState(() { p.downActual = (p.downActual % 4) + 1; if (p.downActual == 1) p.yardsParaPrimer = 10; }); _guardarEstado(); },
                child: Column(
                  children: [
                    Text(_downLabels[p.downActual - 1], style: TextStyle(color: colorPosesion, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    const Text('DOWN', style: TextStyle(color: Colors.white24, fontSize: 6, letterSpacing: 1)),
                  ],
                ),
              ),

              const Text(' & ', style: TextStyle(color: Colors.white12, fontSize: 14)),

              // Yards Display
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(onTap: () { if (p.yardsParaPrimer > 1) setState(() => p.yardsParaPrimer--); _guardarEstado(); }, child: const Icon(Icons.remove, color: Colors.white24, size: 14)),
                  const SizedBox(width: 4),
                  Column(
                    children: [
                      Text('${p.yardsParaPrimer}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      const Text('YDS', style: TextStyle(color: Colors.white24, fontSize: 6)),
                    ],
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(onTap: () { if (p.yardsParaPrimer < 99) setState(() => p.yardsParaPrimer++); _guardarEstado(); }, child: const Icon(Icons.add, color: Colors.white24, size: 14)),
                ],
              ),

              const SizedBox(width: 8),

              // Visita button
              Flexible(
                flex: 2,
                child: GestureDetector(
                  onTap: () { if (p.posesionLocal) { setState(() => p.posesionLocal = false); _guardarEstado(); } },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: !p.posesionLocal ? colorPosesion.withOpacity(0.8) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: !p.posesionLocal ? colorPosesion : Colors.white12),
                    ),
                    child: Center(child: Text(p.visita.toUpperCase(), style: TextStyle(color: !p.posesionLocal ? Colors.white : Colors.white38, fontSize: 8, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // FILA 2: BARRA DE CAMPO Y YARDA ACTUAL
          Row(
            children: [
              const Text('🏈', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 6),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanUpdate: (details) {
                        double yard = (details.localPosition.dx / constraints.maxWidth) * 100;
                        setState(() => p.posicionCampo = yard.clamp(1, 99).toInt());
                        _guardarEstado();
                      },
                      onTapDown: (details) {
                        double yard = (details.localPosition.dx / constraints.maxWidth) * 100;
                        setState(() => p.posicionCampo = yard.clamp(1, 99).toInt());
                        _guardarEstado();
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (p.posicionCampo.clamp(1, 99)) / 100, // Ajustado a 100 para coincidir con el touch
                          minHeight: 12, // Un poco más alta para que sea más fácil de tocar
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(colorPosesion.withOpacity(0.6)),
                        ),
                      ),
                    );
                  }
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(onTap: () { if (p.posicionCampo > 1) setState(() => p.posicionCampo--); _guardarEstado(); }, child: const Icon(Icons.chevron_left, color: Colors.white38, size: 16)),
              Text('Yd ${p.posicionCampo}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              GestureDetector(onTap: () { if (p.posicionCampo < 99) setState(() => p.posicionCampo++); _guardarEstado(); }, child: const Icon(Icons.chevron_right, color: Colors.white38, size: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
