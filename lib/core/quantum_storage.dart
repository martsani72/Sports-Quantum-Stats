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
import 'package:mi_nueva_app/models/partido.dart';

class QuantumStorage {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static Future<void> guardarPerfil(Map<String, dynamic> perfil) async {
    await prefs.setString('perfil_usuario', jsonEncode(perfil));
  }

  static Map<String, dynamic> cargarPerfil() {
    String? data = prefs.getString('perfil_usuario');
    if (data == null) {
      return {
        'nombre': '',
        'medio': '',
        'redSocial': '',
        'usarFirma': true,
        'deporteDefecto': '',
        'idioma': 'Español' 
      };
    }
    return jsonDecode(data);
  }

  static Future<void> guardarPartidoActivo(Partido partido) async {
    await prefs.setString('partido_activo', jsonEncode(partido.toMap()));
  }

  static Partido? cargarPartidoActivo() {
    String? data = prefs.getString('partido_activo');
    if (data == null) return null;
    try {
      return Partido.fromMap(jsonDecode(data));
    } catch (e) {
      print('Error al cargar partido activo: $e');
      return null;
    }
  }

  static Future<void> borrarPartidoActivo() async {
    await prefs.remove('partido_activo');
  }
}
