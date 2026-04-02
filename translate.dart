import 'dart:io';

void main() {
  final folder = Directory('lib/screens');
  final replacements = {
    r"'ELEGIR COLOR'": "Traductor.get('elegir_color')",
    r"'ELEGIR DISEÑO'": "Traductor.get('elegir_diseno')",
    r"'PLANILLA DE EQUIPOS'": "Traductor.get('planilla_equipos')",
    r"'EQUIPO LOCAL'": "Traductor.get('equipo_local')",
    r"'EQUIPO VISITA'": "Traductor.get('equipo_visita')",
    r"'BORRAR'": "Traductor.get('borrar')",
    r"'ATRÁS'": "Traductor.get('atras')",
    r"'CARGAR'": "Traductor.get('cargar')",
    r"'TIEMPO AMARILLA'": "Traductor.get('tiempo_amarilla')",
    r"'2 MIN'": "Traductor.get('dos_min')",
    r"'10 MIN'": "Traductor.get('diez_min')",
    r"'NUEVO EVENTO'": "Traductor.get('nuevo_evento')",
    r"'AGREGAR'": "Traductor.get('agregar')",
    r"'INICIAR ENCUENTRO'": "Traductor.get('iniciar_encuentro')",
    r"'GUARDAR PARÁMETROS'": "Traductor.get('guardar_parametros')",
    r"'Parámetros guardados como plantilla'": "Traductor.get('parametros_plantilla')",
    r"'DEPORTE POR DEFECTO'": "Traductor.get('deporte_defecto')",
    r"'AJUSTES DE TRABAJO'": "Traductor.get('ajustes_trabajo')",
    r"'GESTIÓN DE DATOS'": "Traductor.get('gestion_datos')",
    r"'No hay partidos en el historial para exportar'": "Traductor.get('no_hay_partidos_exportar')",
    r"'Error al exportar'": "Traductor.get('error_exportar')",
    r"'No hay plantillas personalizadas aún.'": "Traductor.get('no_hay_plantillas')",
    r"'Plantilla de '": "Traductor.get('plantilla_de')",
    r"'No hay partidos registrados para analizar.'": "Traductor.get('no_hay_partidos_analizar')",
    r"'ENCUENTROS POR DEPORTE'": "Traductor.get('encuentros_por_deporte')",
    r"'No hay encuentros registrados aún.'": "Traductor.get('no_hay_encuentros')",
    r"'Resultado: '": "Traductor.get('resultado_str')",
    r"'Identidad guardada con éxito'": "Traductor.get('identidad_guardada')",
    r"'IDENTIDAD Y FIRMA'": "Traductor.get('identidad_firma')",
    r"'DATOS DEL CRONISTA / ANALISTA'": "Traductor.get('datos_cronista')",
    r"'INCLUIR FIRMA AUTOMÁTICA EN REPORTES'": "Traductor.get('incluir_firma')",
    r"'GUARDAR IDENTIDAD'": "Traductor.get('guardar_identidad')",
    r"'CONFIRMAR'": "Traductor.get('confirmar_mayus')",
    r"'CANCELAR'": "Traductor.get('cancelar_mayus')",
    r"'Mantén presionado un botón para moverlo'": "Traductor.get('mantenga_presionado')",
    r"'REGISTRAR'": "Traductor.get('registrar_mayus')",
    r"'Error al exportar el archivo'": "Traductor.get('error_exportar_archivo')",
    r"'REPORTE DEL PARTIDO'": "Traductor.get('reporte_partido')",
    r"'Bitácora copiada al portapapeles'": "Traductor.get('bitacora_copiada')",
    r"'BITÁCORA DE EVENTOS'": "Traductor.get('bitacora_eventos')",
    r"'Encuentro finalizado y bitácora generada en Guardados'": "Traductor.get('encuentro_finalizado_bitacora')",
    r"'GUARDAR'": "Traductor.get('guardar_mayus')",
    r"'CAMBIO REGISTRADO'": "Traductor.get('cambio_registrado')",
    r"'¿Quiere realizar otro cambio en esta mesma ventana?'": "Traductor.get('quiere_otro_cambio')",
    r"'¿Quiere realizar otro cambio en esta misma ventana?'": "Traductor.get('quiere_otro_cambio')",
    r"'SÍ'": "Traductor.get('si_mayus')",
    r"'NO'": "Traductor.get('no_mayus')",
    r"'REGISTRAR CAMBIO EXTRA'": "Traductor.get('registrar_cambio_extra')",
    r"'N° SALE \(Rojo\)'": "Traductor.get('num_sale_rojo')",
    r"'N° ENTRA \(Verde\)'": "Traductor.get('num_entra_verde')",
    r"'No hay registros aún.'": "Traductor.get('no_hay_registros')",
    r"'CERRAR'": "Traductor.get('cerrar_mayus')",
    r"'TABLERO '": "Traductor.get('tablero_espacio')",
    r"'RESERVAS'": "Traductor.get('reservas_mayus')",
    r"'MINUTO A MINUTO '": "Traductor.get('minuto_a_minuto')",
    // Interpolations and vars
    r"'REGISTRO: \$\{nombreEq.toUpperCase\(\)\}'": "Traductor.get('registro_dp') + ' \${nombreEq.toUpperCase()}'",
    r"'REGISTRAR \$eventoNombre'": "Traductor.get('registrar_mayus') + ' \$eventoNombre'",
    r"'MIN \$\{d\['minuto'\]\}'": "'MIN \${d['minuto']}'"
  };

  for (final file in folder.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      
      replacements.forEach((original, translated) {
        content = content.replaceAll(RegExp(original), translated);
      });
      
      // Fix const constraints
      content = content.replaceAll(RegExp(r'const\s+(?=Text\([^)]*Traductor\.get)'), '');
      content = content.replaceAll(RegExp(r'const\s+(?=SnackBar\([^)]*Traductor\.get)'), '');
      content = content.replaceAll(RegExp(r'const\s+(?=Center\([^)]*Traductor\.get)'), '');
      content = content.replaceAll(RegExp(r'const\s+(?=Align\([^)]*Traductor\.get)'), '');
      content = content.replaceAll(RegExp(r'const\s+(?=Column\([^)]*Traductor\.get)'), '');
      content = content.replaceAll(RegExp(r'const\s+(?=Padding\([^)]*Traductor\.get)'), '');
      
      file.writeAsStringSync(content);
    }
  }
  
  print('Translation strings replaced in dart.');
}
