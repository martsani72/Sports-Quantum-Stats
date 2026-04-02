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
import 'package:mi_nueva_app/assets_data.dart';

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
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0, left: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // The Logo - Colored and Sharpened to remove soft glow
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            kVerdeNeon, 
                            BlendMode.modulate,
                          ),
                          child: Image.memory(getLogoBytes(), height: 60),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SPORTS', 
                          style: TextStyle(
                            color: kVerdeNeon.withOpacity(0.9), 
                            fontSize: 18, 
                            letterSpacing: 10, 
                            fontWeight: FontWeight.w400,
                            // Removed shadows for more minimalist look
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'QUANTUM STATS', 
                      style: TextStyle(
                        color: kVerdeNeon, 
                        fontSize: 38, 
                        fontWeight: FontWeight.w900, 
                        height: 1.0,
                        letterSpacing: -1,
                        // Removed shadows for more minimalist look
                      )
                    ),
                    // Shared Underline - No shadows
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 120,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: kVerdeNeon,
                      ),
                    )
                  ],
                ),
              ),
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
          decoration: BoxDecoration(
            color: kNegro,
            border: Border.all(color: kVerdeNeon.withOpacity(0.5), width: 1.5), 
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: kVerdeNeon.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: kVerdeNeon.withOpacity(0.1),
                blurRadius: 5,
              )
            ]
          ),
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
