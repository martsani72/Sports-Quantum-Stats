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

import 'package:mi_nueva_app/screens/pantalla_principal.dart';
import 'package:mi_nueva_app/screens/pantalla_seleccion_deporte.dart';
import 'package:mi_nueva_app/screens/pantalla_configuracion_dinamica.dart';
import 'package:mi_nueva_app/screens/pantalla_pre_inicio.dart';
import 'package:mi_nueva_app/screens/pantalla_tablero_control.dart';
import 'package:mi_nueva_app/screens/pantalla_registro_evento.dart';
import 'package:mi_nueva_app/screens/pantalla_encuentros_guardados.dart';
import 'package:mi_nueva_app/screens/pantalla_resumen_partido.dart';
import 'package:mi_nueva_app/screens/pantalla_encuentros_personalizados.dart';
import 'package:mi_nueva_app/screens/pantalla_mi_cuenta.dart';
import 'package:mi_nueva_app/screens/pantalla_editar_identidad.dart';
import 'package:mi_nueva_app/screens/pantalla_estadisticas.dart';
import 'package:mi_nueva_app/screens/pantalla_configuraciones.dart';

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
