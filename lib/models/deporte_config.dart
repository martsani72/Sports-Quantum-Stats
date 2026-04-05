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

class DeporteConfig {
  static final Map<String, Map<String, dynamic>> datos = {
    'Fútbol': {
      'icono': Icons.sports_soccer,
      'contadores': {'Tiempos': 2, 'Minutos': 45, 'Cambios': 5, 'Ventanas': 3},
      'limites': {'Tiempos': 9, 'Minutos': 99, 'Cambios': 9, 'Ventanas': 9},
      'switches': {'Gol': true, 'Remates': true, 'Remates al arco': true, 'Asistencia': true, 'Corner': true, 'Falta': true, 'Tarjeta Amarilla': true, 'Tarjeta Roja': true, 'Tarjeta Verde': true, 'Cambio': true},
    },
    'Rugby': {
      'icono': Icons.sports_rugby,
      'contadores': {'Tiempos': 2, 'Minutos': 40, 'Cambios': 8, 'Min. Amarilla': 10},
      'limites': {'Tiempos': 4, 'Minutos': 99, 'Cambios': 15, 'Min. Amarilla': 10},
      'switches': {'Try (5 pts)': true, 'Conversión (2 pts)': true, 'Penal (3 pts)': true, 'Drop (3 pts)': true, 'Penal': true, 'Line Out': true, 'Tarjeta Amarilla': true, 'Tarjeta Roja': true, 'Scrum': true, 'Cambio': true},
    },
    'Basketball': {
      'icono': Icons.sports_basketball,
      'contadores': {'Cuartos': 4, 'Minutos': 10, 'Tiempos Muertos': 6},
      'limites': {'Cuartos': 9, 'Minutos': 99, 'Tiempos Muertos': 9},
      'switches': {'Tiro Libre (1 pt)': true, 'Doble (2 pts)': true, 'Triple (3 pts)': true, 'Rebotes': true, 'Tapones': true, 'Falta Personal': true, 'Falta Técnica': true, 'Cambio': true},
    },
    'Baseball': {
      'icono': Icons.sports_baseball,
      'contadores': {'Entradas': 9},
      'limites': {'Entradas': 99},
      'switches': {'Carrera': true, 'Hit': true, 'Error': true, 'Ponche': true, 'Home Run': true, 'Cambio': true},
    },
    'Football Americano': {
      'icono': Icons.sports_football,
      'contadores': {'Cuartos': 4, 'Minutos': 15, 'Tiempos Muertos': 6},
      'limites': {'Cuartos': 9, 'Minutos': 99, 'Tiempos Muertos': 9},
      'switches': {'Touchdown (6 pts)': true, 'Field Goal (3 pts)': true, 'Extra Point (1 pt)': true, 'Safety (2 pts)': true, 'Castigo': true, 'Cambio': true},
    },
  };
}
