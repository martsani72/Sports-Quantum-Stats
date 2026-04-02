import 'dart:io';

void main() {
  final file = File('lib/core/traductor.dart');
  var content = file.readAsStringSync();

  final dicExtras = {
    'Español': {
      'Tiempos': 'Tiempos', 'Minutos': 'Minutos', 'Cambios': 'Cambios', 'Ventanas': 'Ventanas',
      'Cuartos': 'Cuartos', 'Tiempos Muertos': 'Tiempos Muertos', 'Entradas': 'Entradas',
      'Gol': 'Gol', 'Remates': 'Remates', 'Remates al arco': 'Remates al arco', 'Asistencia': 'Asistencia',
      'Corner': 'Corner', 'Falta': 'Falta', 'Tarjeta Amarilla': 'Tarjeta Amarilla', 'Tarjeta Roja': 'Tarjeta Roja',
      'Tarjeta Verde': 'Tarjeta Verde', 'Cambio': 'Cambio', 'Try (5 pts)': 'Try (5 pts)',
      'Conversión (2 pts)': 'Conversión (2 pts)', 'Penal (3 pts)': 'Penal (3 pts)', 'Drop (3 pts)': 'Drop (3 pts)',
      'Penal': 'Penal', 'Line Out': 'Line Out', 'Scrum': 'Scrum', 'Tiro Libre (1 pt)': 'Tiro Libre (1 pt)',
      'Doble (2 pts)': 'Doble (2 pts)', 'Triple (3 pts)': 'Triple (3 pts)', 'Rebotes': 'Rebotes', 'Tapones': 'Tapones',
      'Falta Personal': 'Falta Personal', 'Falta Técnica': 'Falta Técnica', 'Carrera': 'Carrera', 'Hit': 'Hit',
      'Error': 'Error', 'Ponche': 'Ponche', 'Home Run': 'Home Run', 'Touchdown (6 pts)': 'Touchdown (6 pts)',
      'Field Goal (3 pts)': 'Field Goal (3 pts)', 'Extra Point (1 pt)': 'Extra Point (1 pt)',
      'Safety (2 pts)': 'Safety (2 pts)', 'Castigo': 'Castigo'
    },
    'English': {
      'Tiempos': 'Halves', 'Minutos': 'Minutes', 'Cambios': 'Substitutions', 'Ventanas': 'Sub Windows',
      'Cuartos': 'Quarters', 'Tiempos Muertos': 'Timeouts', 'Entradas': 'Innings',
      'Gol': 'Goal', 'Remates': 'Shots', 'Remates al arco': 'Shots on Target', 'Asistencia': 'Assist',
      'Corner': 'Corner', 'Falta': 'Foul', 'Tarjeta Amarilla': 'Yellow Card', 'Tarjeta Roja': 'Red Card',
      'Tarjeta Verde': 'Green Card', 'Cambio': 'Substitution', 'Try (5 pts)': 'Try (5 pts)',
      'Conversión (2 pts)': 'Conversion (2 pts)', 'Penal (3 pts)': 'Penalty (3 pts)', 'Drop (3 pts)': 'Drop (3 pts)',
      'Penal': 'Penalty', 'Line Out': 'Line Out', 'Scrum': 'Scrum', 'Tiro Libre (1 pt)': 'Free Throw (1 pt)',
      'Doble (2 pts)': '2-Pointer', 'Triple (3 pts)': '3-Pointer', 'Rebotes': 'Rebounds', 'Tapones': 'Blocks',
      'Falta Personal': 'Personal Foul', 'Falta Técnica': 'Technical Foul', 'Carrera': 'Run', 'Hit': 'Hit',
      'Error': 'Error', 'Ponche': 'Strikeout', 'Home Run': 'Home Run', 'Touchdown (6 pts)': 'Touchdown (6 pts)',
      'Field Goal (3 pts)': 'Field Goal (3 pts)', 'Extra Point (1 pt)': 'Extra Point (1 pt)',
      'Safety (2 pts)': 'Safety (2 pts)', 'Castigo': 'Penalty'
    },
    'Português': {
      'Tiempos': 'Tempos', 'Minutos': 'Minutos', 'Cambios': 'Substituições', 'Ventanas': 'Janelas',
      'Cuartos': 'Quartos', 'Tiempos Muertos': 'Pedidos de Tempo', 'Entradas': 'Entradas',
      'Gol': 'Gol', 'Remates': 'Finalizações', 'Remates al arco': 'Chutes a Gol', 'Asistencia': 'Assistência',
      'Corner': 'Escanteio', 'Falta': 'Falta', 'Tarjeta Amarilla': 'Cartão Amarelo', 'Tarjeta Roja': 'Cartão Vermelho',
      'Tarjeta Verde': 'Cartão Verde', 'Cambio': 'Substituição', 'Try (5 pts)': 'Try (5 pts)',
      'Conversión (2 pts)': 'Conversão (2 pts)', 'Penal (3 pts)': 'Pênalti (3 pts)', 'Drop (3 pts)': 'Drop (3 pts)',
      'Penal': 'Pênalti', 'Line Out': 'Line Out', 'Scrum': 'Scrum', 'Tiro Libre (1 pt)': 'Lance Livre (1 pt)',
      'Doble (2 pts)': 'Cesta de 2', 'Triple (3 pts)': 'Cesta de 3', 'Rebotes': 'Rebotes', 'Tapones': 'Tocos',
      'Falta Personal': 'Falta Pessoal', 'Falta Técnica': 'Falta Técnica', 'Carrera': 'Corrida', 'Hit': 'Hit',
      'Error': 'Erro', 'Ponche': 'Strikeout', 'Home Run': 'Home Run', 'Touchdown (6 pts)': 'Touchdown (6 pts)',
      'Field Goal (3 pts)': 'Field Goal (3 pts)', 'Extra Point (1 pt)': 'Extra Point (1 pt)',
      'Safety (2 pts)': 'Safety (2 pts)', 'Castigo': 'Falta'
    }
  };

  for (var idioma in dicExtras.keys) {
    String addedStr = dicExtras[idioma]!.entries.map((e) => "      '${e.key}': '${e.value}',").join('\n');
    
    // Buscar donde termina el idioma actual en el mapa y agregar las nuevas keys
    if (idioma == 'Español') {
      content = content.replaceFirst("      'usuario_redes': 'Usuario en Redes (Ej: @MartinDatos)'", "      'usuario_redes': 'Usuario en Redes (Ej: @MartinDatos)',\n$addedStr");
    } else if (idioma == 'English') {
      content = content.replaceFirst("      'usuario_redes': 'Social Handles (Ex: @MartinStats)'", "      'usuario_redes': 'Social Handles (Ex: @MartinStats)',\n$addedStr");
    } else if (idioma == 'Português') {
      content = content.replaceFirst("      'usuario_redes': 'Usuário em Redes (Ex: @MartinStats)'", "      'usuario_redes': 'Usuário em Redes (Ex: @MartinStats)',\n$addedStr");
    }
  }

  file.writeAsStringSync(content);
  print('Metrics appended to Traductor');
}
