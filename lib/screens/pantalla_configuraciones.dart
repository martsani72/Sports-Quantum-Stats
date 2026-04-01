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

class PantallaConfiguraciones extends StatefulWidget {
  const PantallaConfiguraciones({super.key});

  @override
  State<PantallaConfiguraciones> createState() => _PantallaConfiguracionesState();
}

class _PantallaConfiguracionesState extends State<PantallaConfiguraciones> {
  
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

    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: Text(Traductor.get('titulo_config'), style: const TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)),
        backgroundColor: kNegro,
        leading: const BackButton(color: kVerdeNeon),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(Traductor.get('preferencias'), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
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
          
        ],
      ),
    );
  }
}
