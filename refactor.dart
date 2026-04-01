import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  final lines = file.readAsLinesSync();

  String getLines(int start, int end) {
    return lines.sublist(start - 1, end).join('\n');
  }

  const universalImports = '''// ignore_for_file: prefer_const_constructors, unused_import, prefer_const_literals_to_create_immutables, use_key_in_widget_constructors, deprecated_member_use
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

''';

  final List<Map<String, dynamic>> extractions = [
    {"file": "lib/core/quantum_storage.dart", "start": 12, "end": 37},
    {"file": "lib/core/globals.dart", "start": 39, "end": 40},
    {"file": "lib/core/globals.dart", "start": 159, "end": 160, "append": true},
    {"file": "lib/core/traductor.dart", "start": 44, "end": 133},
    {"file": "lib/core/constants.dart", "start": 149, "end": 154},
    {"file": "lib/models/partido.dart", "start": 162, "end": 261},
    {"file": "lib/models/deporte_config.dart", "start": 263, "end": 296},
    {"file": "lib/widgets/widget_camiseta.dart", "start": 2664, "end": 2771},
    {"file": "lib/screens/pantalla_principal.dart", "start": 301, "end": 362},
    {"file": "lib/screens/pantalla_seleccion_deporte.dart", "start": 367, "end": 395},
    {"file": "lib/screens/pantalla_configuracion_dinamica.dart", "start": 400, "end": 869},
    {"file": "lib/screens/pantalla_pre_inicio.dart", "start": 874, "end": 960},
    {"file": "lib/screens/pantalla_tablero_control.dart", "start": 965, "end": 1778},
    {"file": "lib/screens/pantalla_registro_evento.dart", "start": 1783, "end": 2033},
    {"file": "lib/screens/pantalla_encuentros_guardados.dart", "start": 2038, "end": 2072},
    {"file": "lib/screens/pantalla_resumen_partido.dart", "start": 2074, "end": 2199},
    {"file": "lib/screens/pantalla_encuentros_personalizados.dart", "start": 2204, "end": 2240},
    {"file": "lib/screens/pantalla_mi_cuenta.dart", "start": 2245, "end": 2390},
    {"file": "lib/screens/pantalla_editar_identidad.dart", "start": 2392, "end": 2492},
    {"file": "lib/screens/pantalla_estadisticas.dart", "start": 2497, "end": 2590},
    {"file": "lib/screens/pantalla_configuraciones.dart", "start": 2595, "end": 2659}
  ];

  Directory('lib/core').createSync();
  Directory('lib/models').createSync();
  Directory('lib/widgets').createSync();
  Directory('lib/screens').createSync();

  for (final ext in extractions) {
    final filepath = ext['file'] as String;
    final start = ext['start'] as int;
    final end = ext['end'] as int;
    final append = ext['append'] == true;

    final content = getLines(start, end);
    final f = File(filepath);

    if (append) {
      f.writeAsStringSync(content + '\n', mode: FileMode.append);
    } else {
      f.writeAsStringSync(universalImports + content + '\n');
    }
  }

  final mainContent = universalImports + getLines(135, 144) + '\n';
  File('lib/main.dart').writeAsStringSync(mainContent);

  print('Refactorizacion completada mediante Dart.');
}
