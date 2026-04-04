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
import 'package:mi_nueva_app/screens/pantalla_registro_evento.dart';
import 'package:mi_nueva_app/screens/pantalla_configuraciones.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _guardarEstado();
    }
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
    _blinkController.forward();
    _blinkController.stop();
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
    _blinkController.repeat(reverse: true);
    _guardarEstado();
  }

  Future<void> _manejarFinPeriodo() async {
    _pausarTimer();
    String clavePeriodo = widget.partido.contadores.containsKey('Cuartos') ? 'Cuartos' : (widget.partido.contadores.containsKey('Entradas') ? 'Entradas' : 'Tiempos');
    int maxPeriodos = widget.partido.contadores[clavePeriodo] ?? 1;
    String nombreRef = Traductor.get(clavePeriodo).toUpperCase(); 

    if (_periodoActual < maxPeriodos) {
      bool confirmar = await _mostrarDialogo(Traductor.get('finalizar_periodo_titulo') + nombreRef + ' $_periodoActual?', Traductor.get('finalizar_periodo_msj'), Traductor.get('siguiente_mayus'));
      if (confirmar) {
        setState(() {
          widget.partido.logEventos.add('--- FIN DEL $nombreRef $_periodoActual ---');
          _periodoActual++;
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
          }
        });
        QuantumStorage.borrarPartidoActivo();
        Navigator.popUntil(context, (route) => route.isFirst); 
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
                setState(() {
                  widget.partido.logEventos.add('MIN $tiempoActual | 📝 NOTA: ${notaController.text.trim()}');
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
            widget.partido.logEventos.add('MIN $tiempoActual | ${nombreReal.toUpperCase()}: Cambio ($nombreSale x $nombreEntra)');
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
              content: const Text('¿Quiere realizar otro cambio en esta mesma ventana?', style: TextStyle(color: Colors.white, fontSize: 14)),
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

          String nombreReal = equipoNombre == 'Local' ? widget.partido.local : widget.partido.visita;
          widget.partido.logEventos.add('MIN $tiempoActual | ${nombreReal.toUpperCase()}: $eventoRegistrado ($nombreActor)');
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
    String nombrePeriodo = Traductor.get(clavePeriodo).toUpperCase(); 

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
                        Text(Traductor.get('reservas_mayus'), style: TextStyle(color: kVerdeOscuro, fontSize: 10, letterSpacing: 2)), 
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
                  
                  _buildSelectorPosesion(),
                  Container( 
                    padding: const EdgeInsets.all(10), color: const Color(0xFF050505), 
                    child: Row( 
                      children: [ 
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: widget.partido.localFondo == Colors.black ? const Color(0xFF1A1A1A) : widget.partido.localFondo, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: widget.partido.localTexto.withOpacity(0.5)))), 
                            onPressed: () => _abrirRegistro('Local'), 
                            child: Column(children: [Text(Traductor.get('registrar_mayus'), style: TextStyle(color: widget.partido.localTexto, fontSize: 10)), Text(widget.partido.local, style: TextStyle(color: widget.partido.localTexto, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)])
                          )
                        ), 
                        const SizedBox(width: 10), 
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: widget.partido.visitaFondo == Colors.black ? const Color(0xFF1A1A1A) : widget.partido.visitaFondo, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: widget.partido.visitaTexto.withOpacity(0.5)))), 
                            onPressed: () => _abrirRegistro('Visita'), 
                            child: Column(children: [Text(Traductor.get('registrar_mayus'), style: TextStyle(color: widget.partido.visitaTexto, fontSize: 10)), Text(widget.partido.visita, style: TextStyle(color: widget.partido.visitaTexto, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)])
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
    final List<String> eventosRapidos = ['Corner', 'Falta', 'Remates', 'Remates al arco', 'Penal', 'Line Out', 'Scrum', 'Rebotes', 'Tapones', 'Ponche', 'Castigo'];

    widget.partido.stats['Local']!.forEach((evento, _) { 
      bool esAnotacion = evento.toLowerCase().contains('gol') || evento.toLowerCase().contains('punto') || evento.toLowerCase().contains('try') || evento.toLowerCase().contains('carrera');
      bool esHecho = evento.contains('Hech');
      
      if (!esAnotacion && !esHecho) { 
        int cantLocal = widget.partido.stats['Local']![evento] ?? 0;
        int cantVisita = widget.partido.stats['Visita']![evento] ?? 0;

        bool rapido = eventosRapidos.contains(evento);

        filas.add( 
          Padding( 
            padding: const EdgeInsets.symmetric(vertical: 8.0), 
            child: Row( 
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [ 
                // Local Side
                Row(
                  children: [
                    SizedBox(
                      width: 45,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4), 
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(5)), 
                        child: Text('$cantLocal', textAlign: TextAlign.center, style: TextStyle(color: widget.partido.localTexto, fontSize: 15, fontWeight: FontWeight.bold))
                      )
                    ),
                    const SizedBox(width: 5),
                    if (rapido) _buildBotonRapido('Local', evento),
                  ],
                ),

                Expanded(child: Text(Traductor.get(evento).toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1))),
                
                // Visita Side
                Row(
                  children: [
                    if (rapido) _buildBotonRapido('Visita', evento),
                    const SizedBox(width: 5),
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
              ], 
            ), 
          ) 
        ); 
      } 
    }); 
    return filas; 
  }

  Widget _buildBotonRapido(String equipo, String evento) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.partido.stats[equipo]![evento] = (widget.partido.stats[equipo]![evento] ?? 0) + 1;
          String tiempoActual = _formatearTiempo();
          String nombreReal = equipo == 'Local' ? widget.partido.local : widget.partido.visita;
          widget.partido.logEventos.add('MIN $tiempoActual | ${nombreReal.toUpperCase()}: $evento (EQUIPO)');
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
    int tLocal = widget.partido.posesionSegundos['Local'] ?? 0;
    int tVisita = widget.partido.posesionSegundos['Visita'] ?? 0;
    int total = tLocal + tVisita;
    
    double pLocal = total == 0 ? 50 : (tLocal / total) * 100;
    double pVisita = total == 0 ? 50 : (tVisita / total) * 100;

    // Vibrant colors for the bars/backgrounds
    Color colorL = (widget.partido.localFondo == kNegro || widget.partido.localFondo.value == 0xFF000000) ? widget.partido.localTexto : widget.partido.localFondo;
    Color colorV = (widget.partido.visitaFondo == kNegro || widget.partido.visitaFondo.value == 0xFF000000) ? widget.partido.visitaTexto : widget.partido.visitaFondo;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          _buildItemPosesion('Local', widget.partido.local, pLocal, colorL, widget.partido.localTexto),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('POSESIÓN', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          _buildItemPosesion('Visita', widget.partido.visita, pVisita, colorV, widget.partido.visitaTexto),
        ],
      ),
    );
  }

  Widget _buildItemPosesion(String equipo, String nombre, double porcentaje, Color colorFondo, Color colorTexto) {
    bool activo = _equipoPosesion == equipo;
    bool esLocal = equipo == 'Local';

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _equipoPosesion = activo ? null : equipo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: activo ? colorFondo.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: esLocal 
            ? Row( // Local: [NAME] [Percentage]
                children: [
                  Expanded(child: Text(nombre.toUpperCase(), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1))),
                  const SizedBox(width: 5),
                  Text('${porcentaje.toStringAsFixed(0)}%', style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold, fontSize: 13)),
                  if (activo) ...[const SizedBox(width: 4), Icon(Icons.timer, color: colorTexto, size: 10)],
                ],
              )
            : Row( // Visita: [Percentage] [NAME]
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (activo) ...[Icon(Icons.timer, color: colorTexto, size: 10), const SizedBox(width: 4)],
                  Text('${porcentaje.toStringAsFixed(0)}%', style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 5),
                  Expanded(child: Text(nombre.toUpperCase(), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1))),
                ],
              ),
        ),
      ),
    );
  }
}
