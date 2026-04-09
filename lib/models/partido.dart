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
import 'package:mi_nueva_app/models/deporte_config.dart';

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
  
  List<Map<String, dynamic>> historialAcciones = [];
  List<String> logEventos = [];
  late List<String> ordenEventosActivos;
  
  Map<String, int> posesionSegundos = {
    'Local': 0,
    'Visita': 0,
  };
  
  Map<String, Map<String, int>> posesionPorPeriodo = {};

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

  Map<String, dynamic> toMap() {
    return {
      'deporte': deporte,
      'local': local,
      'visita': visita,
      'contadores': contadores,
      'switches': switches,
      'localFondo': localFondo.value,
      'localTexto': localTexto.value,
      'visitaFondo': visitaFondo.value,
      'visitaTexto': visitaTexto.value,
      'jugadoresLocal': jugadoresLocal,
      'jugadoresVisita': jugadoresVisita,
      'patronLocal': patronLocal.index,
      'patronVisita': patronVisita.index,
      'stats': stats,
      'anotaciones': anotaciones,
      'tarjetas': tarjetas,
      'cambiosList': cambiosList,
      'logEventos': logEventos,
      'ordenEventosActivos': ordenEventosActivos,
      'posesionSegundos': posesionSegundos,
      'posesionPorPeriodo': posesionPorPeriodo,
      'historialAcciones': historialAcciones,
    };
  }

  factory Partido.fromMap(Map<String, dynamic> map) {
    var p = Partido(
      deporte: map['deporte'],
      local: map['local'],
      visita: map['visita'],
      contadores: Map<String, int>.from(map['contadores']),
      switches: Map<String, bool>.from(map['switches']),
      localFondo: Color(map['localFondo']),
      localTexto: Color(map['localTexto']),
      visitaFondo: Color(map['visitaFondo']),
      visitaTexto: Color(map['visitaTexto']),
      jugadoresLocal: Map<String, String>.from(map['jugadoresLocal']),
      jugadoresVisita: Map<String, String>.from(map['jugadoresVisita']),
      patronLocal: PatronCamiseta.values[map['patronLocal']],
      patronVisita: PatronCamiseta.values[map['patronVisita']],
    );
    // Overwrite default values after constructor
    p.stats = (map['stats'] as Map).map((k, v) => MapEntry(k as String, Map<String, int>.from(v as Map)));
    p.anotaciones = (map['anotaciones'] as Map).map((k, v) => MapEntry(k as String, (v as List).map((e) => Map<String, String>.from(e as Map)).toList()));
    p.tarjetas = (map['tarjetas'] as Map).map((k, v) => MapEntry(k as String, (v as List).map((e) => Map<String, String>.from(e as Map)).toList()));
    p.cambiosList = (map['cambiosList'] as Map).map((k, v) => MapEntry(k as String, (v as List).map((e) => Map<String, String>.from(e as Map)).toList()));
    p.logEventos = List<String>.from(map['logEventos']);
    p.ordenEventosActivos = List<String>.from(map['ordenEventosActivos']);
    if (map.containsKey('posesionSegundos')) {
      p.posesionSegundos = Map<String, int>.from(map['posesionSegundos']);
    }
    if (map.containsKey('posesionPorPeriodo')) {
      p.posesionPorPeriodo = (map['posesionPorPeriodo'] as Map).map((k, v) => MapEntry(k as String, Map<String, int>.from(v as Map)));
    }
    if (map.containsKey('historialAcciones')) {
      p.historialAcciones = List<Map<String, dynamic>>.from(map['historialAcciones']);
    }
    return p;
  }

  void registrarAccion({
    required String equipo,
    required String tipo, // 'stat', 'anotacion', 'tarjeta', 'cambio', 'nota'
    required String evento, 
    Map<String, String>? datosExtra,
    required String log,
  }) {
    historialAcciones.add({
      'equipo': equipo,
      'tipo': tipo,
      'evento': evento,
      'datosExtra': datosExtra,
      'log': log,
    });
    logEventos.add(log);
  }

  bool deshacerUltimaAccion() {
    if (historialAcciones.isEmpty) return false;

    var ultima = historialAcciones.removeLast();
    String equipo = ultima['equipo'];
    String tipo = ultima['tipo'];
    String evento = ultima['evento'];
    String log = ultima['log'];

    // Remover del log
    logEventos.removeWhere((element) => element == log);

    if (tipo == 'stat' || tipo == 'anotacion' || tipo == 'tarjeta') {
      if (stats[equipo]!.containsKey(evento)) {
        if (stats[equipo]![evento]! > 0) {
          stats[equipo]![evento] = stats[equipo]![evento]! - 1;
        }
      }
    }

    if (tipo == 'anotacion') {
      if (anotaciones[equipo]!.isNotEmpty) {
        anotaciones[equipo]!.removeLast();
      }
    }

    if (tipo == 'tarjeta') {
      if (tarjetas[equipo]!.isNotEmpty) {
        tarjetas[equipo]!.removeLast();
      }
    }

    if (tipo == 'cambio') {
      if (cambiosList[equipo]!.isNotEmpty) {
        cambiosList[equipo]!.removeLast();
      }
      stats[equipo]!['CambiosHechos'] = (stats[equipo]!['CambiosHechos'] ?? 1) - 1;
      // Nota: No restamos 'VentanasHechas' automáticamente porque una ventana puede tener varios cambios.
      // Esto es una limitación aceptable por ahora para no complicar en exceso.
    }

    return true;
  }
}
