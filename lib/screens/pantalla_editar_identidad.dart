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

class PantallaEditarIdentidad extends StatefulWidget {
  const PantallaEditarIdentidad({super.key});

  @override
  State<PantallaEditarIdentidad> createState() => _PantallaEditarIdentidadState();
}

class _PantallaEditarIdentidadState extends State<PantallaEditarIdentidad> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _medioCtrl;
  late TextEditingController _redesCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: perfilUsuario['nombre']);
    _medioCtrl = TextEditingController(text: perfilUsuario['medio']);
    _redesCtrl = TextEditingController(text: perfilUsuario['redSocial']);
  }

  void _guardarPerfil() {
    setState(() {
      perfilUsuario['nombre'] = _nombreCtrl.text.trim();
      perfilUsuario['medio'] = _medioCtrl.text.trim();
      perfilUsuario['redSocial'] = _redesCtrl.text.trim();
    });
    QuantumStorage.guardarPerfil(perfilUsuario);
    FocusScope.of(context).unfocus(); 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Identidad guardada con éxito', style: TextStyle(color: kVerdeNeon)), backgroundColor: kNegro));
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: const Text('IDENTIDAD Y FIRMA', style: TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)),
        backgroundColor: kNegro,
        leading: const BackButton(color: kVerdeNeon),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DATOS DEL CRONISTA / ANALISTA', style: TextStyle(color: kVerdeOscuro, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 15),
            
            TextField(
              controller: _nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Tu Nombre / Apodo', labelStyle: TextStyle(color: Colors.white54), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kVerdeNeon))),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _medioCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Medio / Organización (Ej: ESPN, Radio Mitre)', labelStyle: TextStyle(color: Colors.white54), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kVerdeNeon))),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _redesCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Usuario en Redes (Ej: @MartinDatos)', labelStyle: TextStyle(color: Colors.white54), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kVerdeNeon))),
            ),
            
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: kVerdeOscuro)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text('INCLUIR FIRMA AUTOMÁTICA EN REPORTES', style: TextStyle(color: kVerdeNeon, fontSize: 12, fontWeight: FontWeight.bold))),
                  Switch(
                    value: perfilUsuario['usarFirma'],
                    activeColor: kVerdeNeon,
                    onChanged: (val) {
                      setState(() => perfilUsuario['usarFirma'] = val);
                    },
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon, minimumSize: const Size(double.infinity, 55)),
              icon: const Icon(Icons.save, color: kNegro),
              label: const Text('GUARDAR IDENTIDAD', style: TextStyle(color: kNegro, fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: _guardarPerfil,
            ),
          ],
        ),
      ),
    );
  }
}
