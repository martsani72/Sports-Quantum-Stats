import 'dart:io';

void main() {
  final file = File('lib/core/traductor.dart');
  var content = file.readAsStringSync();

  final dicExtras = {
    'Español': {
      'finalizar_periodo_titulo': '¿FINALIZAR ',
      'finalizar_periodo_msj': 'El cronómetro se reiniciará para el próximo período.',
      'siguiente_mayus': 'SIGUIENTE',
      'finalizar_encuentro_titulo': '¿FINALIZAR ENCUENTRO?',
      'finalizar_encuentro_msj': 'Estás en el último período. ¿Deseas terminar el partido y generar el reporte?',
      'terminar_mayus': 'TERMINAR',
      'abandonar_titulo': '¿ABANDONAR SIN GUARDAR?',
      'abandonar_msj': 'Si sales ahora perderás este registro en vivo.',
      'salir_todas_formas': 'SALIR DE TODAS FORMAS',
      'limite_ventanas_titulo': 'LÍMITE DE VENTANAS AGOTADO',
      'limite_ventanas_msj_1': 'El equipo ya no tiene ventanas disponibles (',
      'limite_ventanas_msj_2': '). ¿Continuar de todas formas?',
      'limite_cambios_titulo': 'LÍMITE DE CAMBIOS AGOTADO',
      'limite_cambios_msj_1': 'El equipo ya no tiene cambios disponibles (',
      'limite_cambios_msj_2': '). ¿Continuar de todas formas?',
      'nota_hint': 'Escribí o dictá el comentario del partido acá...',
    },
    'English': {
      'finalizar_periodo_titulo': 'FINISH ',
      'finalizar_periodo_msj': 'The timer will reset for the next period.',
      'siguiente_mayus': 'NEXT',
      'finalizar_encuentro_titulo': 'FINISH MATCH?',
      'finalizar_encuentro_msj': 'You are in the final period. Do you want to end the match and generate the report?',
      'terminar_mayus': 'FINISH',
      'abandonar_titulo': 'EXIT WITHOUT SAVING?',
      'abandonar_msj': 'If you exit now, you will lose this live record.',
      'salir_todas_formas': 'EXIT ANYWAY',
      'limite_ventanas_titulo': 'SUB WINDOWS LIMIT REACHED',
      'limite_ventanas_msj_1': 'The team has no substitution windows left (',
      'limite_ventanas_msj_2': '). Continue anyway?',
      'limite_cambios_titulo': 'SUBSTITUTIONS LIMIT REACHED',
      'limite_cambios_msj_1': 'The team has no substitutions left (',
      'limite_cambios_msj_2': '). Continue anyway?',
      'nota_hint': 'Type or dictate the match comment here...',
    },
    'Português': {
      'finalizar_periodo_titulo': 'FINALIZAR ',
      'finalizar_periodo_msj': 'O cronômetro será zerado para o próximo período.',
      'siguiente_mayus': 'PRÓXIMO',
      'finalizar_encuentro_titulo': 'FINALIZAR PARTIDA?',
      'finalizar_encuentro_msj': 'Você está no último período. Deseja encerrar a partida e gerar o relatório?',
      'terminar_mayus': 'TERMINAR',
      'abandonar_titulo': 'SAIR SEM SALVAR?',
      'abandonar_msj': 'Se você sair agora, perderá este registro ao vivo.',
      'salir_todas_formas': 'SAIR MESMO ASSIM',
      'limite_ventanas_titulo': 'LIMITE DE JANELAS ATINGIDO',
      'limite_ventanas_msj_1': 'A equipe não tem mais janelas disponíveis (',
      'limite_ventanas_msj_2': '). Continuar mesmo assim?',
      'limite_cambios_titulo': 'LIMITE DE SUBSTITUIÇÕES ATINGIDO',
      'limite_cambios_msj_1': 'A equipe não tem mais substituições disponíveis (',
      'limite_cambios_msj_2': '). Continuar mesmo assim?',
      'nota_hint': 'Escreva ou dite o comentário da partida aqui...',
    }
  };

  for (var idioma in dicExtras.keys) {
    String addedStr = dicExtras[idioma]!.entries.map((e) => "      '${e.key}': '${e.value}',").join('\n');
    
    if (idioma == 'Español') {
      content = content.replaceFirst("      'Castigo': 'Castigo'", "      'Castigo': 'Castigo',\n$addedStr");
    } else if (idioma == 'English') {
      content = content.replaceFirst("      'Castigo': 'Penalty'", "      'Castigo': 'Penalty',\n$addedStr");
    } else if (idioma == 'Português') {
      content = content.replaceFirst("      'Castigo': 'Falta'", "      'Castigo': 'Falta',\n$addedStr");
    }
  }

  file.writeAsStringSync(content);
  print('Popups appended to Traductor');
}
