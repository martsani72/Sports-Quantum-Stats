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

class PantallaConfiguraciones extends StatefulWidget {
  const PantallaConfiguraciones({super.key});

  @override
  State<PantallaConfiguraciones> createState() => _PantallaConfiguracionesState();
}

class _PantallaConfiguracionesState extends State<PantallaConfiguraciones> {
  
  void _seleccionarDeporteDefecto() {
    List<String> deportes = ['Ninguno', ...DeporteConfig.datos.keys];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: Text(Traductor.get('deporte_defecto'), style: TextStyle(color: kVerdeNeon, fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: deportes.map((d) => ListTile(
            title: Text(d == 'Ninguno' ? 'Ninguno' : Traductor.get(d).toUpperCase(), style: TextStyle(color: perfilUsuario['deporteDefecto'] == d ? kVerdeNeon : Colors.white, fontSize: 13)),
            trailing: perfilUsuario['deporteDefecto'] == d ? const Icon(Icons.check, color: kVerdeNeon) : null,
            onTap: () {
              setState(() => perfilUsuario['deporteDefecto'] = d == 'Ninguno' ? '' : d);
              QuantumStorage.guardarPerfil(perfilUsuario);
              Navigator.pop(context);
              setState((){});
            },
          )).toList(),
        ),
      )
    );
  }

  Future<void> _exportarBaseDeDatos() async {
    if (partidosGuardados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Traductor.get('no_hay_partidos_exportar'), style: TextStyle(color: Colors.redAccent)), backgroundColor: kNegro));
      return;
    }

    try {
      StringBuffer csv = StringBuffer();
      csv.writeln('APP,Sports Quantum Stats - Backup Global');
      csv.writeln('FECHA EXPORTACION,${DateTime.now().toString()}');
      csv.writeln('');
      
      csv.writeln('DEPORTE,LOCAL,PUNTOS_L,VISITA,PUNTOS_V,TOTAL_EVENTOS_REGISTRADOS');

      for (var p in partidosGuardados) {
        int totalEventos = p.logEventos.length;
        csv.writeln('${p.deporte},${p.local},${p.obtenerPuntaje("Local")},${p.visita},${p.obtenerPuntaje("Visita")},$totalEventos');
      }

      List<int> bytes = utf8.encode(csv.toString());
      Uint8List archivoBytes = Uint8List.fromList(bytes);
      XFile archivoCsv = XFile.fromData(archivoBytes, mimeType: 'text/csv', name: 'SQStats_Backup_Global.csv');
      
      await Share.shareXFiles([archivoCsv], text: 'Backup de todos los partidos');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Traductor.get('error_exportar'), style: TextStyle(color: Colors.redAccent)), backgroundColor: kNegro));
    }
  }

  void _seleccionarIdioma() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: Text(Traductor.get('idioma_app'), style: const TextStyle(color: kVerdeNeon, fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Español', 'English', 'Português'].map((idioma) => ListTile(
            title: Text(idioma, style: TextStyle(color: perfilUsuario['idioma'] == idioma ? kVerdeNeon : Colors.white, fontSize: 13)),
            trailing: perfilUsuario['idioma'] == idioma ? const Icon(Icons.check, color: kVerdeNeon) : null,
            onTap: () {
              setState(() => perfilUsuario['idioma'] = idioma);
              QuantumStorage.guardarPerfil(perfilUsuario); 
              Navigator.pop(context); 
              setState(() {}); 
            },
          )).toList(),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    String idiomaElegido = perfilUsuario['idioma'] ?? 'Español';
    String deporteElegido = perfilUsuario['deporteDefecto'] ?? '';

    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: Text(Traductor.get('titulo_config').toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)),
        backgroundColor: kNegro,
        leading: const BackButton(color: kVerdeNeon),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner de Perfil (Migrado de Mi Cuenta)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(10), border: Border.all(color: kVerdeOscuro)),
            child: Row(
              children: [
                const CircleAvatar(radius: 25, backgroundColor: kVerdeOscuro, child: Icon(Icons.person, color: kVerdeNeon, size: 25)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(perfilUsuario['nombre'].toString().isEmpty ? Traductor.get('no_definidos') : perfilUsuario['nombre'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(perfilUsuario['medio'].toString().isEmpty ? Traductor.get('titulo_firma_hint') : '${perfilUsuario['medio']} | ${perfilUsuario['redSocial']}', style: const TextStyle(color: kVerdeNeon, fontSize: 11)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          Text(Traductor.get('ajustes_trabajo').toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 10),

          _buildOpcionMenu(
            icono: Icons.badge, 
            titulo: Traductor.get('identidad_firma'), 
            subtitulo: Traductor.get('perfil_ajustes_identidad'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaEditarIdentidad())).then((_) => setState((){})),
          ),

          _buildOpcionMenu(
            icono: Icons.sports, 
            titulo: Traductor.get('deporte_defecto'), 
            subtitulo: deporteElegido.isEmpty ? Traductor.get('perfil_ajustes_deporte') : '${Traductor.get('perfil_ajustes_deporte_actual')}${Traductor.get(deporteElegido).toUpperCase()}',
            onTap: _seleccionarDeporteDefecto,
          ),

          const SizedBox(height: 30),
          Text(Traductor.get('preferencias').toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 10),
          
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.white.withOpacity(0.05))),
            tileColor: Colors.white.withOpacity(0.02),
            leading: const Icon(Icons.language, color: Colors.white70),
            title: Text(Traductor.get('idioma'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(idiomaElegido, style: const TextStyle(color: kVerdeNeon, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: kVerdeNeon),
            onTap: _seleccionarIdioma,
          ),

          const SizedBox(height: 30),
          Text(Traductor.get('gestion_datos').toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 10),

          _buildOpcionMenu(
            icono: Icons.download_for_offline, 
            titulo: Traductor.get('perfil_exportar_db_titulo'), 
            subtitulo: Traductor.get('perfil_exportar_db_sub'),
            onTap: _exportarBaseDeDatos,
          ),
          
        ],
      ),
    );
  }

  Widget _buildOpcionMenu({required IconData icono, required String titulo, required String subtitulo, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.white.withOpacity(0.05))),
        tileColor: Colors.white.withOpacity(0.02),
        leading: Icon(icono, color: Colors.white70),
        title: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: kVerdeNeon),
        onTap: onTap,
      ),
    );
  }
}
