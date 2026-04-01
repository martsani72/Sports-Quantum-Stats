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

class PantallaEstadisticas extends StatelessWidget {
  const PantallaEstadisticas({super.key});

  @override
  Widget build(BuildContext context) {
    int totalPartidos = partidosGuardados.length;
    Map<String, int> partidosPorDeporte = {};
    int totalPuntosLocal = 0;
    int totalPuntosVisita = 0;

    for (var p in partidosGuardados) {
      partidosPorDeporte[p.deporte] = (partidosPorDeporte[p.deporte] ?? 0) + 1;
      totalPuntosLocal += p.obtenerPuntaje('Local');
      totalPuntosVisita += p.obtenerPuntaje('Visita');
    }

    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: Text(Traductor.get('menu_3').toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)),
        backgroundColor: kNegro,
        leading: const BackButton(color: kVerdeNeon),
      ),
      body: totalPartidos == 0
          ? const Center(child: Text('No hay partidos registrados para analizar.', style: TextStyle(color: Colors.white54, fontSize: 14)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildTarjetaDato('TOTAL ENCUENTROS', totalPartidos.toString(), Icons.analytics),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildTarjetaDato('PUNTOS LOCALES', totalPuntosLocal.toString(), Icons.home)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildTarjetaDato('PUNTOS VISITA', totalPuntosVisita.toString(), Icons.flight_land)),
                  ],
                ),
                const SizedBox(height: 30),
                const Text('ENCUENTROS POR DEPORTE', style: TextStyle(color: kVerdeOscuro, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 15),
                
                ...partidosPorDeporte.entries.map((e) => _buildFilaDeporte(Traductor.get(e.key), e.value, totalPartidos)).toList(),
              ],
            ),
    );
  }

  Widget _buildTarjetaDato(String titulo, String valor, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kVerdeOscuro),
      ),
      child: Column(
        children: [
          Icon(icono, color: kVerdeNeon, size: 30),
          const SizedBox(height: 10),
          Text(valor, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(titulo, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFilaDeporte(String deporte, int cantidad, int total) {
    double porcentaje = cantidad / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(deporte.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('$cantidad (${(porcentaje * 100).toStringAsFixed(0)}%)', style: const TextStyle(color: kVerdeNeon, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: porcentaje,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: kCelestePlay,
            minHeight: 6,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }
}
