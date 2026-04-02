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

class PantallaResumenPartido extends StatelessWidget {
  final Partido partido;
  const PantallaResumenPartido({super.key, required this.partido});

  String _generarFirma() {
    if (perfilUsuario['usarFirma'] == true) {
      String nombre = perfilUsuario['nombre'].toString().trim();
      String medio = perfilUsuario['medio'].toString().trim();
      String redes = perfilUsuario['redSocial'].toString().trim();
      
      if (nombre.isNotEmpty || medio.isNotEmpty || redes.isNotEmpty) {
        String textoFirma = '\n\n---\nReporte generado por ${nombre.isEmpty ? 'Analista' : nombre}';
        if (medio.isNotEmpty) textoFirma += ' para $medio';
        if (redes.isNotEmpty) textoFirma += ' ($redes)';
        textoFirma += ' | App: Sports Quantum Stats';
        return textoFirma;
      }
    }
    return '';
  }

  Future<void> _exportarCSV(BuildContext context) async {
    try {
      StringBuffer csv = StringBuffer();
      
      csv.writeln('TORNEO/APP,Sports Quantum Stats');
      csv.writeln('DEPORTE,${partido.deporte.toUpperCase()}');
      csv.writeln('LOCAL,${partido.local.toUpperCase()},PUNTOS:,${partido.obtenerPuntaje("Local")}');
      csv.writeln('VISITA,${partido.visita.toUpperCase()},PUNTOS:,${partido.obtenerPuntaje("Visita")}');
      csv.writeln('');
      
      csv.writeln('--- ESTADISTICAS GLOBALES ---');
      csv.writeln('EQUIPO,EVENTO,CANTIDAD');
      for (String eq in ['Local', 'Visita']) {
        partido.stats[eq]!.forEach((evento, cant) {
          csv.writeln('$eq,$evento,$cant');
        });
      }
      csv.writeln('');

      csv.writeln('--- MINUTO A MINUTO ---');
      csv.writeln('TIEMPO,EQUIPO,EVENTO_Y_JUGADOR');
      
      for (String linea in partido.logEventos) {
        String lineaLimpia = linea.replaceAll(',', ';'); 
        if (lineaLimpia.contains('|')) {
          List<String> partes = lineaLimpia.split('|');
          csv.writeln('${partes[0].trim()},${partes[1].trim()}');
        } else {
          csv.writeln(lineaLimpia);
        }
      }

      String firma = _generarFirma();
      if (firma.isNotEmpty) {
         csv.writeln('');
         csv.writeln(firma.replaceAll('\n', ' ').replaceAll('--- ', ''));
      }

      List<int> bytes = utf8.encode(csv.toString());
      Uint8List archivoBytes = Uint8List.fromList(bytes);
      String nombreArchivo = 'SQStats_${partido.local}_vs_${partido.visita}.csv'.replaceAll(' ', '_');

      XFile archivoCsv = XFile.fromData(archivoBytes, mimeType: 'text/csv', name: nombreArchivo);
      await Share.shareXFiles([archivoCsv], text: 'Reporte CSV de Estadísticas');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Traductor.get('error_exportar_archivo'), style: TextStyle(color: Colors.redAccent)), backgroundColor: kNegro));
    }
  }

  @override
  Widget build(BuildContext context) {
    String textoResumen = partido.logEventos.join('\n\n') + _generarFirma();

    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: Text(Traductor.get('reporte_partido'), style: TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)), 
        backgroundColor: kNegro, 
        leading: const BackButton(color: kVerdeNeon),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart, color: Colors.greenAccent),
            tooltip: 'Exportar Excel (.CSV)',
            onPressed: () => _exportarCSV(context),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: kCelestePlay),
            tooltip: 'Copiar Texto',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: textoResumen));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Traductor.get('bitacora_copiada'), style: TextStyle(color: kVerdeNeon)), backgroundColor: kNegro));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('${partido.local.toUpperCase()} ${partido.obtenerPuntaje('Local')} - ${partido.obtenerPuntaje('Visita')} ${partido.visita.toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text(Traductor.get(partido.deporte).toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 3)),
            const SizedBox(height: 25),
            
            Align(alignment: Alignment.centerLeft, child: Text(Traductor.get('bitacora_eventos'), style: TextStyle(color: kVerdeOscuro, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFF0A0A0A), border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(
                  child: Text(textoResumen, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13, height: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
