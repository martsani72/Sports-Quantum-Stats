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
