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

enum PatronCamiseta {
  liso,              
  franjaHorizontal,  
  bandaDiagonal,     
  mitades,           
  rayasVerticales,   
  rayasHorizontales  
}

class Partido {
  final String deporte;
  final String local;
  final String visita;
  final Map<String, int> contadores;
  final Map<String, bool> switches;
  
  final Color localFondo;
  final Color localTexto;
  final Color visitaFondo;
  final Color visitaTexto;
  
  final Map<String, String> jugadoresLocal;
  final Map<String, String> jugadoresVisita;

  final PatronCamiseta patronLocal;
  final PatronCamiseta patronVisita;

  Map<String, Map<String, int>> stats = {
    'Local': {},
    'Visita': {},
  };
  
  Map<String, List<Map<String, String>>> anotaciones = {
    'Local': [],
    'Visita': [],
  };

  Map<String, List<Map<String, String>>> tarjetas = {
    'Local': [],
    'Visita': [],
  };

  Map<String, List<Map<String, String>>> cambiosList = {
    'Local': [],
    'Visita': [],
  };
  
  List<String> logEventos = [];
  late List<String> ordenEventosActivos;

  Partido({
    required this.deporte, required this.local, required this.visita,
    required this.contadores, required this.switches,
    this.localFondo = kNegro, this.localTexto = kVerdeNeon,
    this.visitaFondo = kNegro, this.visitaTexto = Colors.redAccent,
    this.jugadoresLocal = const {}, this.jugadoresVisita = const {},
    this.patronLocal = PatronCamiseta.liso,
    this.patronVisita = PatronCamiseta.liso,
  }) {
    for (String evento in switches.keys) {
      if (switches[evento] == true) {
        stats['Local']![evento] = 0;
        stats['Visita']![evento] = 0;
      }
    }
    stats['Local']!['CambiosHechos'] = 0;
    stats['Visita']!['CambiosHechos'] = 0;
    stats['Local']!['VentanasHechas'] = 0;
    stats['Visita']!['VentanasHechas'] = 0;
    
    ordenEventosActivos = switches.entries.where((e) => e.value).map((e) => e.key).toList();
    logEventos.add('--- INICIO DEL ENCUENTRO: $local vs $visita ---');
  }

  String obtenerNombreJugador(String equipo, String numero) {
    if (numero == '?') return 'N°?';
    Map<String, String> planilla = equipo == 'Local' ? jugadoresLocal : jugadoresVisita;
    if (planilla.containsKey(numero)) {
      return '$numero ${planilla[numero]}'; 
    }
    return 'N°$numero'; 
  }

  int obtenerPuntaje(String equipo) {
    int total = 0;
    stats[equipo]!.forEach((key, value) {
      String kLower = key.toLowerCase();
      if (kLower.contains('gol') || kLower.contains('carrera') || kLower.contains('pt') || kLower.contains('try')) {
        int multiplicador = 1; 
        RegExp exp = RegExp(r'\((\d+)\s*pt');
        Match? match = exp.firstMatch(key);
        if (match != null) {
          multiplicador = int.parse(match.group(1)!);
        }
        total += (value * multiplicador);
      }
    });
    return total;
  }
}
