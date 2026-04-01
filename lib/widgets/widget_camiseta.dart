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

class WidgetCamiseta extends StatelessWidget {
  final Color fondo;
  final Color detalle;
  final PatronCamiseta patron;

  const WidgetCamiseta({
    super.key, 
    required this.fondo, 
    required this.detalle,
    this.patron = PatronCamiseta.franjaHorizontal, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 55,
      height: 55,
      child: CustomPaint(
        painter: _CamisetaPainter(
          colorPrincipal: fondo, 
          colorSecundario: detalle, 
          patron: patron
        ),
      ),
    );
  }
}

class _CamisetaPainter extends CustomPainter {
  final Color colorPrincipal;
  final Color colorSecundario;
  final PatronCamiseta patron;

  _CamisetaPainter({
    required this.colorPrincipal, 
    required this.colorSecundario, 
    required this.patron
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintPrincipal = Paint()..color = colorPrincipal..style = PaintingStyle.fill;
    final paintSecundario = Paint()..color = colorSecundario..style = PaintingStyle.fill;
    final paintBorde = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1.5;

    double w = size.width;
    double h = size.height;

    Path path = Path();
    path.moveTo(w * 0.15, h * 0.1); 
    path.lineTo(w * 0.35, h * 0.1); 
    path.quadraticBezierTo(w * 0.5, h * 0.28, w * 0.65, h * 0.1); 
    path.lineTo(w * 0.85, h * 0.1); 
    path.lineTo(w * 0.95, h * 0.4); 
    path.lineTo(w * 0.85, h * 0.45); 
    path.lineTo(w * 0.80, h * 0.95); 
    path.lineTo(w * 0.20, h * 0.95); 
    path.lineTo(w * 0.15, h * 0.45); 
    path.lineTo(w * 0.05, h * 0.4); 
    path.close();

    canvas.save();
    canvas.clipPath(path);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paintPrincipal);
    
    switch (patron) {
      case PatronCamiseta.liso:
        break;
        
      case PatronCamiseta.franjaHorizontal:
        canvas.drawRect(Rect.fromLTWH(0, h * 0.42, w, h * 0.25), paintSecundario);
        break;
        
      case PatronCamiseta.bandaDiagonal:
        Path banda = Path();
        banda.moveTo(w * 0.1, 0);
        banda.lineTo(w * 0.4, 0);
        banda.lineTo(w * 0.9, h);
        banda.lineTo(w * 0.6, h);
        banda.close();
        canvas.drawPath(banda, paintSecundario);
        break;
        
      case PatronCamiseta.mitades:
        canvas.drawRect(Rect.fromLTWH(w / 2, 0, w / 2, h), paintSecundario);
        break;
        
      case PatronCamiseta.rayasVerticales:
        for (double i = 0; i < w; i += w / 5) {
          canvas.drawRect(Rect.fromLTWH(i, 0, w / 10, h), paintSecundario);
        }
        break;
        
      case PatronCamiseta.rayasHorizontales:
        for (double i = 0; i < h; i += h / 6) {
          canvas.drawRect(Rect.fromLTWH(0, i, w, h / 12), paintSecundario);
        }
        break;
    }

    canvas.restore(); 
    canvas.drawPath(path, paintBorde);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; 
}
