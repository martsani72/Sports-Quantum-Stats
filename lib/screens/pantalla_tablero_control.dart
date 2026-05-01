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

class PantallaTableroControl extends StatefulWidget {
  final Partido partido;
  const PantallaTableroControl({super.key, required this.partido});
  @override State<PantallaTableroControl> createState() => _PantallaTableroControlState();
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
  
  // CONTROLADORES BASEBALL
  TextEditingController _ctrlBateador = TextEditingController();
  TextEditingController _ctrlLanzador = TextEditingController();
  bool _inicializadoBaseball = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    AdHelper.cargarInterstitialAd();
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
      bool confirmar = await _mostrarDialogo(Traductor.get('finalizar_encuentro_titulo'), Traductor.get('finalizar_encuentro_msj'), Traductor.get('terminar_mayus'));
      if (confirmar) {
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
        int maxC = widget.partido.contadores['Cambios'] ?? 0;
        int maxV = widget.partido.contadores['Ventanas'] ?? 0;
        
        bool primeraVez = true;
        var resActual = resultado;

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
            
            widget.partido.cambiosList[equipoNombre]!.add({
              'minuto': tiempoActual,
              'sale': nombreSale,
              'entra': nombreEntra
            });
            
            String nombreReal = equipoNombre == 'Local' ? widget.partido.local : widget.partido.visita;
            String log = 'MIN $tiempoActual | ${nombreReal.toUpperCase()}: Cambio ($nombreSale x $nombreEntra)';
            
            widget.partido.registrarAccion(
              equipo: equipoNombre,
              tipo: 'cambio',
              evento: 'Cambio',
              datosExtra: {'sale': nombreSale, 'entra': nombreEntra},
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
            ? Text(Traductor.get('no_hay_registros'), style: TextStyle(color: Colors.white54), textAlign: TextAlign.center)
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
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(Traductor.get('cerrar_mayus'), style: TextStyle(color: Colors.grey)))],
      )
    );
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
      _notaX = (MediaQuery.of(context).size.width / 2) - 80; // Centrado horizontal para el botón ancho
      _notaY = 260; // Bajado para que quede sobre Reservas
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
        ),
        body: SafeArea(
          child: Stack(
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
                                          if (widget.partido.deporte.toLowerCase() == 'baseball') _buildInfoJugadorBaseball('Local'),
                                          const SizedBox(height: 5),
                                          Text('${widget.partido.obtenerPuntaje('Local')}', style: TextStyle(color: widget.partido.localTexto, fontSize: 50, fontWeight: FontWeight.bold, height: 1.0)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (widget.partido.deporte.toLowerCase() != 'football americano') ...[
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
                                    // BOTÓN UNDO (QUANTUM)
                                    IconButton(
                                      icon: Icon(Icons.undo, color: widget.partido.historialAcciones.isEmpty ? Colors.white10 : Colors.white38, size: 22),
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
                                        child: IconButton(icon: Icon(_estaCorriendo ? Icons.pause_circle_filled : Icons.play_circle_fill, color: kCelestePlay, size: 30), onPressed: _estaCorriendo ? _pausarTimer : _iniciarTimer, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                      )
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(icon: const Icon(Icons.stop_circle, color: kRojoStop, size: 30), onPressed: _manejarFinPeriodo, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                  ],
                                ),
                                if (widget.partido.deporte.toLowerCase() == 'baseball') ...[
                                  const SizedBox(height: 10),
                                  _buildDiamantesBases(),
                                  _buildContadorBaseballSimplificado(),
                                ],
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
                                          if (widget.partido.deporte.toLowerCase() == 'baseball') _buildInfoJugadorBaseball('Visita'),
                                          const SizedBox(height: 5),
                                          Text('${widget.partido.obtenerPuntaje('Visita')}', style: TextStyle(color: widget.partido.visitaTexto, fontSize: 50, fontWeight: FontWeight.bold, height: 1.0)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (widget.partido.deporte.toLowerCase() != 'football americano') ...[
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
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (widget.partido.deporte.toLowerCase() == 'football americano') ...[
                          const SizedBox(height: 12),
                          _buildPanelFootballAmericano(),
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
                        GestureDetector(onTap: () => _mostrarDetallePopUp('CAMBIOS - ${widget.partido.local}', widget.partido.cambiosList['Local']!, 'cambio'), child: _infoCambios('Local')), 
                        Text(Traductor.get('reservas_mayus'), style: TextStyle(color: kVerdeNeon, fontSize: 10, letterSpacing: 2)), 
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
                  if (widget.partido.deporte.toLowerCase() != 'baseball' && widget.partido.deporte.toLowerCase() != 'football americano') _buildSelectorPosesion(),

                  Container( 
                    padding: const EdgeInsets.all(10), color: const Color(0xFF050505), 
                    child: Row( 
                      children: [ 
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.partido.localFondo.withOpacity(0.35), 
                              padding: const EdgeInsets.symmetric(vertical: 15), 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10), 
                                side: BorderSide(color: widget.partido.localTexto, width: 2)
                              ),
                              elevation: 5,
                            ), 
                            onPressed: () => _abrirRegistro('Local'), 
                            child: Column(children: [Text(Traductor.get('registrar_mayus'), style: TextStyle(color: widget.partido.localTexto.withOpacity(0.7), fontSize: 9, letterSpacing: 1)), Text(widget.partido.local, style: TextStyle(color: widget.partido.localTexto, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)])
                          )
                        ), 
                        const SizedBox(width: 10), 
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.partido.visitaFondo.withOpacity(0.35), 
                              padding: const EdgeInsets.symmetric(vertical: 15), 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10), 
                                side: BorderSide(color: widget.partido.visitaTexto, width: 2)
                              ),
                              elevation: 5,
                            ), 
                            onPressed: () => _abrirRegistro('Visita'), 
                            child: Column(children: [Text(Traductor.get('registrar_mayus'), style: TextStyle(color: widget.partido.visitaTexto.withOpacity(0.7), fontSize: 9, letterSpacing: 1)), Text(widget.partido.visita, style: TextStyle(color: widget.partido.visitaTexto, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)])
                          )
                        ), 
                      ], 
                    ), 
                  )
                ],
              ),

              // BOTÓN DE NOTA FLOTANTE ARRASTRABLE
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
                  child: FloatingActionButton.extended(
                    onPressed: _abrirAnotadorLibre,
                    backgroundColor: kVerdeNeon,
                    elevation: 6,
                    icon: const Icon(Icons.edit_note, color: kNegro, size: 20),
                    label: Text(
                      Traductor.get('anotar_nota'), 
                      style: const TextStyle(color: kNegro, fontSize: 9, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      'Corner', 'Falta', 'Remates', 'Remates al arco', 'Penal', 
      'Line Out', 'Scrum', 'Rebotes', 'Tapones', 'Ponche', 'Castigo'
    ];

    widget.partido.stats['Local']!.forEach((evento, _) { 
      bool esAnotacion = evento.toLowerCase().contains('gol') || 
                         evento.toLowerCase().contains('punto') || 
                         evento.toLowerCase().contains('try') || 
                         evento.toLowerCase().contains('carrera');
      bool esHecho = evento.contains('Hech');
      
      if (!esAnotacion && !esHecho) { 
        int cantLocal = widget.partido.stats['Local']![evento] ?? 0;
        int cantVisita = widget.partido.stats['Visita']![evento] ?? 0;
        bool rapido = eventosRapidos.contains(evento);

        Widget fila = Padding( 
          padding: const EdgeInsets.symmetric(vertical: 8.0), 
          child: Row( 
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [ 
              // Lado Local
              Row(
                children: [
                  SizedBox(
                    width: 45,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4), 
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(5)
                      ), 
                      child: Text('$cantLocal', textAlign: TextAlign.center, style: TextStyle(color: widget.partido.localTexto, fontSize: 15, fontWeight: FontWeight.bold))
                    )
                  ),
                  const SizedBox(width: 5),
                  if (rapido) _buildBotonRapido('Local', evento) else const SizedBox(width: 24),
                ],
              ),

              Expanded(
                child: Text(
                  Traductor.get(evento).toUpperCase(), 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1)
                )
              ),
              
              // Lado Visita
              Row(
                children: [
                  if (rapido) _buildBotonRapido('Visita', evento) else const SizedBox(width: 24),
                  const SizedBox(width: 5),
                  SizedBox(
                    width: 45,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4), 
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(5)
                      ), 
                      child: Text('$cantVisita', textAlign: TextAlign.center, style: TextStyle(color: widget.partido.visitaTexto, fontSize: 15, fontWeight: FontWeight.bold))
                    )
                  ),
                ],
              ),
            ], 
          ), 
        );

        if (rapido) {
          filasRapidas.add(fila);
        } else {
          filasPasivas.add(fila);
        }
      } 
    }); 

    return [
      ...filasRapidas,
      if (filasPasivas.isNotEmpty && filasRapidas.isNotEmpty) 
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(color: Colors.white10, thickness: 1),
        ),
      ...filasPasivas,
    ]; 
  }

  Widget _buildBotonRapido(String equipo, String evento) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.partido.stats[equipo]![evento] = (widget.partido.stats[equipo]![evento] ?? 0) + 1;
          String tiempoActual = _formatearTiempo();
          String nombreReal = equipo == 'Local' ? widget.partido.local : widget.partido.visita;
          widget.partido.logEventos.add('MIN $tiempoActual | ${nombreReal.toUpperCase()}: $evento (EQUIPO)');
          
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
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: kVerdeOscuro.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: kVerdeNeon.withOpacity(0.5))),
        child: const Icon(Icons.add, color: kVerdeNeon, size: 14),
      ),
    );
  }

  Widget _buildSelectorPosesion() {
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
                  Text('${porcentaje.toStringAsFixed(0)}%', style: TextStyle(color: activo ? Colors.white : colorTexto, fontWeight: FontWeight.bold, fontSize: 13)),
                  if (activo) ...[const SizedBox(width: 4), Icon(Icons.timer, color: Colors.white, size: 12)],
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (activo) ...[Icon(Icons.timer, color: Colors.white, size: 12), const SizedBox(width: 4)],
                  Text('${porcentaje.toStringAsFixed(0)}%', style: TextStyle(color: activo ? Colors.white : colorTexto, fontWeight: FontWeight.bold, fontSize: 13)),
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
