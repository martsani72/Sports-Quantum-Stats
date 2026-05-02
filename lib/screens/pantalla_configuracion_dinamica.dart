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
import 'package:mi_nueva_app/screens/pantalla_editar_identidad.dart';
import 'package:mi_nueva_app/screens/pantalla_estadisticas.dart';
import 'package:mi_nueva_app/screens/pantalla_configuraciones.dart';

class PantallaConfiguracionDinamica extends StatefulWidget {
  final String nombreDeporte;
  final Map<String, dynamic> configInicial;
  final Map<String, dynamic> datosEncuentro;

  const PantallaConfiguracionDinamica({super.key, required this.nombreDeporte, required this.configInicial, required this.datosEncuentro});

  @override State<PantallaConfiguracionDinamica> createState() => _PantallaConfiguracionDinamicaState();
}

class _PantallaConfiguracionDinamicaState extends State<PantallaConfiguracionDinamica> {
  late Map<String, int> contadores;
  late Map<String, int> limites;
  late Map<String, bool> switches;

  @override
  void initState() {
    super.initState();
    contadores = Map<String, int>.from(widget.configInicial['contadores']);
    limites = Map<String, int>.from(widget.configInicial['limites']);
    switches = Map<String, bool>.from(widget.configInicial['switches']);
  }



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
      body: SafeArea(
        child: Column(
          children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 10),
                ...contadores.keys.map((key) {
                  if (key == 'Min. Amarilla') return _buildFilaMinutosAmarilla(key);
                  return _buildFilaNumero(key, contadores[key]!, 0, limites[key]!, (val) => setState(() => contadores[key] = val));
                }),
                const Divider(color: kVerdeOscuro, height: 40),
                Text(Traductor.get('eventos_reg'), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
                const SizedBox(height: 10),
                ...switches.keys.map((key) => _buildFilaSwitch(key, switches[key]!, (val) => setState(() => switches[key] = val))),
                
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
            Text(Traductor.get(label).toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 13, fontWeight: FontWeight.w400)),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline, color: kVerdeNeon), onPressed: valorActual > min ? () => onChanged(valorActual - 1) : null),
                SizedBox(width: 30, child: Text('$valorActual', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.add_circle_outline, color: kVerdeNeon), onPressed: valorActual < max ? () => onChanged(valorActual + 1) : null),
              ],
            )
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
            Text(Traductor.get('tiempo_amarilla'), style: TextStyle(color: kVerdeNeon, fontSize: 13, fontWeight: FontWeight.w400)),
            Row(
              children: [
                ChoiceChip(
                  label: Text(Traductor.get('dos_min'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  selected: valorActual == 2,
                  selectedColor: kVerdeNeon,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: kVerdeOscuro),
                  labelStyle: TextStyle(color: valorActual == 2 ? kNegro : Colors.white),
                  onSelected: (val) { if (val) setState(() => contadores[label] = 2); },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text(Traductor.get('diez_min'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  selected: valorActual == 10,
                  selectedColor: kVerdeNeon,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: kVerdeOscuro),
                  labelStyle: TextStyle(color: valorActual == 10 ? kNegro : Colors.white),
                  onSelected: (val) { if (val) setState(() => contadores[label] = 10); },
                ),
              ],
            )
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
            Flexible(child: Text(Traductor.get(label).toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 12, fontWeight: FontWeight.w400))),
            Switch(value: valorActual, activeColor: kVerdeNeon, inactiveThumbColor: Colors.grey, inactiveTrackColor: Colors.white10, onChanged: onChanged)
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color fillColor) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.white54),
      filled: true, fillColor: fillColor == Colors.transparent ? Colors.white.withOpacity(0.05) : fillColor.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: kVerdeOscuro)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kVerdeNeon)),
    );
  }

  void _agregarEventoPersonalizado() {
    TextEditingController nuevoEventoController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: Text(Traductor.get('nuevo_evento'), style: TextStyle(color: kVerdeNeon, fontSize: 16, fontWeight: FontWeight.bold)),
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
            child: Text(Traductor.get('agregar'), style: TextStyle(color: kNegro, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  Widget _buildBotonesAccion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: kVerdeOscuro, width: 1)), color: kNegro),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon, padding: const EdgeInsets.all(15)),
          onPressed: () {
            var d = widget.datosEncuentro;

            Partido nuevoPartido = Partido(
              deporte: widget.nombreDeporte, local: d['local'], visita: d['visita'],
              titulo: d['titulo'],
              torneo: d['torneo'],
              fecha: d['fecha'],
              contadores: contadores, switches: switches,
              localFondo: d['localFondo'], localTexto: d['localTexto'],
              visitaFondo: d['visitaFondo'], visitaTexto: d['visitaTexto'],
              jugadoresLocal: d['jugadoresLocal'], jugadoresVisita: d['jugadoresVisita'],
              patronLocal: d['patronLocal'], patronVisita: d['patronVisita'],
            );
            Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaPreInicio(partido: nuevoPartido)));
          }, 
          child: Text(Traductor.get('confirmar'), style: const TextStyle(color: kNegro, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}
