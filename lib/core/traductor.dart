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

class Traductor {
  static final Map<String, Map<String, String>> _diccionario = {
    'Español': {
      'menu_1': '1 - Iniciar un encuentro',
      'menu_2': '2 - Encuentros Personalizados',
      'menu_3': '3 - Estadísticas',
      'menu_4': '4 - Configuraciones',
      'menu_5': '5 - Mi cuenta',
      'menu_6': '6 - Encuentros guardados',
      'en_construccion': 'Sección en construcción',
      'titulo_config': 'CONFIGURACIONES',
      'preferencias': 'PREFERENCIAS',
      'idioma': 'Idioma',
      'idioma_app': 'IDIOMA DE LA APP',
      'Fútbol': 'Fútbol',
      'Rugby': 'Rugby',
      'Basketball': 'Básquet',
      'Baseball': 'Béisbol',
      'Football Americano': 'Fútbol Americano',
      'parametros': 'PARÁMETROS',
      'eventos_reg': 'EVENTOS REGISTRABLES',
      'modo_edicion': 'MODO EDICIÓN HABILITADO',
      'jugadores_colores': 'EQUIPOS Y COLORES',
      'planilla': 'PLANILLA',
      'confirmar': 'OK',
      'editar': 'EDITAR',
      'cancelar': 'CANCELAR',
      'agregar_estadistica': 'AGREGAR ESTADÍSTICA PERSONALIZADA',
    },
    'English': {
      'menu_1': '1 - Start a match',
      'menu_2': '2 - Custom Matches',
      'menu_3': '3 - Statistics',
      'menu_4': '4 - Settings',
      'menu_5': '5 - My Account',
      'menu_6': '6 - Saved Matches',
      'en_construccion': 'Under construction',
      'titulo_config': 'SETTINGS',
      'preferencias': 'PREFERENCES',
      'idioma': 'Language',
      'idioma_app': 'APP LANGUAGE',
      'Fútbol': 'Soccer',
      'Rugby': 'Rugby',
      'Basketball': 'Basketball',
      'Baseball': 'Baseball',
      'Football Americano': 'American Football',
      'parametros': 'PARAMETERS',
      'eventos_reg': 'TRACKABLE EVENTS',
      'modo_edicion': 'EDIT MODE ENABLED',
      'jugadores_colores': 'TEAMS & COLORS',
      'planilla': 'ROSTER',
      'confirmar': 'CONFIRM',
      'editar': 'EDIT',
      'cancelar': 'CANCEL',
      'agregar_estadistica': 'ADD CUSTOM STATISTIC',
    },
    'Português': {
      'menu_1': '1 - Iniciar uma partida',
      'menu_2': '2 - Partidas Personalizadas',
      'menu_3': '3 - Estatísticas',
      'menu_4': '4 - Configurações',
      'menu_5': '5 - Minha Conta',
      'menu_6': '6 - Partidas Salvas',
      'en_construccion': 'Em construção',
      'titulo_config': 'CONFIGURAÇÕES',
      'preferencias': 'PREFERÊNCIAS',
      'idioma': 'Idioma',
      'idioma_app': 'IDIOMA DO APP',
      'Fútbol': 'Futebol',
      'Rugby': 'Rugby',
      'Basketball': 'Basquete',
      'Baseball': 'Beisebol',
      'Football Americano': 'Futebol Americano',
      'parametros': 'PARÂMETROS',
      'eventos_reg': 'EVENTOS REGISTRÁVEIS',
      'modo_edicion': 'MODO DE EDIÇÃO ATIVADO',
      'jugadores_colores': 'EQUIPES E CORES',
      'planilla': 'ESCALAÇÃO',
      'confirmar': 'OK',
      'editar': 'EDITAR',
      'cancelar': 'CANCELAR',
      'agregar_estadistica': 'ADICIONAR ESTATÍSTICA',
    }
  };

  static String get(String clave) {
    String idiomaActual = perfilUsuario['idioma'] ?? 'Español';
    return _diccionario[idiomaActual]?[clave] ?? clave;
  }
}
