import os

# Archivo de origen
main_file = "lib/main.dart"

with open(main_file, "r", encoding="utf-8") as f:
    lines = f.readlines()

def get_lines(start, end):
    # start and end are 1-based inclusive, matching the line numbers seen in the text
    return "".join(lines[start-1:end])

# Estructura de extracción (archivo, inicio, fin)
extractions = [
    ("lib/core/quantum_storage.dart", 12, 37),
    ("lib/core/globals.dart", 39, 40), # perfilUsuario
    ("lib/core/globals.dart", 159, 160, True), # partidosGuardados, parametrosGuardados (append)
    ("lib/core/traductor.dart", 44, 133),
    ("lib/core/constants.dart", 149, 154),
    ("lib/models/partido.dart", 162, 261),
    ("lib/models/deporte_config.dart", 263, 296),
    ("lib/widgets/widget_camiseta.dart", 2664, 2771),
    ("lib/screens/pantalla_principal.dart", 301, 362),
    ("lib/screens/pantalla_seleccion_deporte.dart", 367, 395),
    ("lib/screens/pantalla_configuracion_dinamica.dart", 400, 869),
    ("lib/screens/pantalla_pre_inicio.dart", 874, 960),
    ("lib/screens/pantalla_tablero_control.dart", 965, 1778),
    ("lib/screens/pantalla_registro_evento.dart", 1783, 2033),
    ("lib/screens/pantalla_encuentros_guardados.dart", 2038, 2072),
    ("lib/screens/pantalla_resumen_partido.dart", 2074, 2199),
    ("lib/screens/pantalla_encuentros_personalizados.dart", 2204, 2240),
    ("lib/screens/pantalla_mi_cuenta.dart", 2245, 2390),
    ("lib/screens/pantalla_editar_identidad.dart", 2392, 2492),
    ("lib/screens/pantalla_estadisticas.dart", 2497, 2590),
    ("lib/screens/pantalla_configuraciones.dart", 2595, 2659)
]

# Cabecera universal de imports para que el tipado no falle
# Incluimos ignorar advertencias para evitar que el linter grite temporalmente
universal_imports = """// ignore_for_file: prefer_const_constructors, unused_import, prefer_const_literals_to_create_immutables
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

"""

os.makedirs("lib/core", exist_ok=True)
os.makedirs("lib/models", exist_ok=True)
os.makedirs("lib/widgets", exist_ok=True)
os.makedirs("lib/screens", exist_ok=True)

for ext in extractions:
    filepath = ext[0]
    start = ext[1]
    end = ext[2]
    append = False
    if len(ext) > 3:
        append = ext[3]
    
    content = get_lines(start, end)
    
    mode = "a" if append else "w"
    with open(filepath, mode, encoding="utf-8") as f:
        if not append:
            f.write(universal_imports)
        f.write(content)
        f.write("\n")

# Ahora recrear lib/main.dart
main_content = universal_imports + get_lines(135, 144) + "\n"
with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(main_content)

print("Refactorización completada mediante Python.")
