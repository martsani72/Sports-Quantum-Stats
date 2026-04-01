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
