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
                label: Text(Traductor.get('iniciar_encuentro'), style: TextStyle(color: kNegro, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PantallaTableroControl(partido: partido))),
              ),
              const SizedBox(height: 20),
              
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: kVerdeOscuro, width: 2), minimumSize: const Size(double.infinity, 60)),
                icon: const Icon(Icons.bookmark_add, color: kVerdeNeon),
                label: Text(Traductor.get('guardar_parametros'), style: TextStyle(color: kVerdeNeon, fontSize: 16)),
                onPressed: () {
                  if (!parametrosGuardados.contains(partido)) parametrosGuardados.add(partido);
                  Navigator.popUntil(context, (route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Traductor.get('parametros_plantilla'), style: TextStyle(color: kVerdeNeon)), backgroundColor: kNegro));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
