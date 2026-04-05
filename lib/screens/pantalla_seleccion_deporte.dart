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
