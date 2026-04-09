// ignore_for_file: prefer_const_constructors, unused_import, prefer_const_literals_to_create_immutables, use_key_in_widget_constructors, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_nueva_app/core/constants.dart';
import 'package:mi_nueva_app/core/globals.dart';
import 'package:mi_nueva_app/core/traductor.dart';
import 'package:mi_nueva_app/core/quantum_storage.dart';
import 'package:mi_nueva_app/models/partido.dart';
import 'package:mi_nueva_app/models/deporte_config.dart';
import 'package:mi_nueva_app/widgets/widget_icono_quantum.dart';

class PantallaRegistroEvento extends StatefulWidget {
  final Partido partido;
  final String equipoSeleccionado;

  const PantallaRegistroEvento({super.key, required this.partido, required this.equipoSeleccionado});

  @override
  State<PantallaRegistroEvento> createState() => _PantallaRegistroEventoState();
}

class _PantallaRegistroEventoState extends State<PantallaRegistroEvento> {
  
  // Mapper de Arte Quantum (Vectorial o Emoticon)
  dynamic _obtenerArteEvento(String evento) {
    String ev = evento.toLowerCase();
    
    // Fútbol y Deportes de Arco
    if (ev.contains('gol')) return 'goal';
    if (ev.contains('remate')) return 'soccer';
    if (ev.contains('corner')) return 'flag';
    if (ev.contains('asistencia')) return '👟';
    if (ev.contains('falta') || ev.contains('penal')) return 'whistle';
    
    // Rugby
    if (ev.contains('try')) return 'rugby';
    if (ev.contains('conversi')) return 'goal';
    if (ev.contains('drop')) return 'rugby';
    if (ev.contains('scrum')) return '💪';
    if (ev.contains('line out')) return '🙋‍♂️';

    // Basketball
    if (ev.contains('tiro libre') || ev.contains('doble') || ev.contains('triple') || ev.contains('rebote') || ev.contains('tapón')) return 'basketball';
    
    // Genéricos
    if (ev.contains('cambio')) return '🔄';
    
    return null;
  }

  IconData _obtenerIconoEvento(String evento) {
    String ev = evento.toLowerCase();
    if (ev.contains('tarjeta')) return Icons.style;
    if (ev.contains('cambio')) return Icons.sync;
    return Icons.ads_click; 
  }

  void _pedirJugador(BuildContext context, String eventoNombre, Color fondoEq, Color textoEq, String nombreEq) {
    String valorPrimario = '';
    String valorSecundario = '';
    bool editandoSecundario = false; 
    bool esCambio = eventoNombre == 'Cambio';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctxDialog) {
        return StatefulBuilder(
          builder: (BuildContext ctxStateful, StateSetter setStateDialog) {

            void onTeclaPulsada(String tecla) {
              HapticFeedback.selectionClick(); // Feedback táctil al escribir
              setStateDialog(() {
                if (tecla == '<') {
                  if (editandoSecundario && valorSecundario.isNotEmpty) {
                    valorSecundario = valorSecundario.substring(0, valorSecundario.length - 1);
                  } else if (!editandoSecundario && valorPrimario.isNotEmpty) {
                    valorPrimario = valorPrimario.substring(0, valorPrimario.length - 1);
                  }
                } else if (tecla == 'C') {
                  if (editandoSecundario) valorSecundario = '';
                  else valorPrimario = '';
                } else {
                  if (editandoSecundario && valorSecundario.length < 3) {
                    valorSecundario += tecla;
                  } else if (!editandoSecundario && valorPrimario.length < 3) {
                    valorPrimario += tecla;
                  }
                }
              });
            }

            bool puedeConfirmar = !esCambio || (valorPrimario.isNotEmpty && valorSecundario.isNotEmpty);

            return AlertDialog(
              backgroundColor: kNegro, 
              shape: RoundedRectangleBorder(side: BorderSide(color: textoEq, width: 2), borderRadius: BorderRadius.circular(10)),
              title: Column(
                children: [
                  Text(nombreEq.toUpperCase(), style: TextStyle(color: textoEq, fontSize: 12, letterSpacing: 2)),
                  Text('${Traductor.get('registrar_mayus')} $eventoNombre', textAlign: TextAlign.center, style: TextStyle(color: textoEq, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite, 
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNumpadDisplay(esCambio ? Traductor.get('num_sale_rojo') : 'N° JUGADOR', valorPrimario, !editandoSecundario, fondoEq, textoEq, () => setStateDialog(() => editandoSecundario = false)),
                    if (esCambio) ...[
                      const SizedBox(height: 10),
                      _buildNumpadDisplay(Traductor.get('num_entra_verde'), valorSecundario, editandoSecundario, fondoEq, textoEq, () => setStateDialog(() => editandoSecundario = true)),
                    ],
                    const SizedBox(height: 20),
                    _buildNumpadRow(['1','2','3'], onTeclaPulsada),
                    _buildNumpadRow(['4','5','6'], onTeclaPulsada),
                    _buildNumpadRow(['7','8','9'], onTeclaPulsada),
                    _buildNumpadRow(['C','0','<'], onTeclaPulsada),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(Traductor.get('cancelar_mayus'), style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: puedeConfirmar ? textoEq : Colors.grey),
                  onPressed: puedeConfirmar ? () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(ctxDialog); 
                    Navigator.pop(context, {   
                      'evento': eventoNombre, 
                      'jugador': valorPrimario.isEmpty ? '?' : valorPrimario,
                      'jugadorEntra': valorSecundario.isEmpty ? '?' : valorSecundario,
                    }); 
                  } : null,
                  child: Text(Traductor.get('confirmar_mayus'), style: TextStyle(color: puedeConfirmar ? kNegro : Colors.black45, fontWeight: FontWeight.bold)),
                )
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildNumpadDisplay(String label, String value, bool active, Color fondo, Color texto, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: active ? fondo.withOpacity(0.5) : Colors.transparent,
          border: Border.all(color: active ? texto : Colors.white24),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: active ? texto : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(value.isEmpty ? '_' : value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ]
        )
      )
    );
  }

  Widget _buildNumpadRow(List<String> teclas, Function(String) onTecla) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: teclas.map((tecla) => InkWell(
          onTap: () => onTecla(tecla),
          child: Container(
            width: 65, height: 45,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.white12)),
            child: Center(
              child: tecla == '<' ? const Icon(Icons.backspace, color: Colors.redAccent, size: 20) :
                     tecla == 'C' ? const Text('C', style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)) :
                     Text(tecla, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            )
          )
        )).toList(),
      ),
    );
  }

  Widget _buildCajaEvento(String evento, Color fondoEq, Color textoEq, bool isDragging) {
    bool esTarjeta = evento.toLowerCase().contains('tarjeta');
    dynamic arte = _obtenerArteEvento(evento);
    
    return Container(
      decoration: BoxDecoration(
        color: fondoEq.withOpacity(isDragging ? 0.4 : 0.05),
        border: Border.all(
          color: isDragging ? textoEq : (fondoEq == Colors.black ? Colors.white12 : fondoEq.withOpacity(0.2)), 
          width: isDragging ? 2 : 0.8
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDragging ? [BoxShadow(color: textoEq.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          esTarjeta 
            ? WidgetTarjetaFisicaQuantum(
                color: evento.toLowerCase().contains('amarilla') ? Colors.yellowAccent : (evento.toLowerCase().contains('roja') ? Colors.redAccent : Colors.greenAccent),
                numero: '', 
                height: 26,
              )
            : WidgetIconoQuantum(
                tipoArte: arte is String && ['goal', 'whistle', 'soccer', 'rugby', 'flag', 'basketball'].contains(arte) ? arte : null,
                emoticon: arte is String && !['goal', 'whistle', 'soccer', 'rugby', 'flag', 'basketball'].contains(arte) ? arte : null,
                icono: arte == null ? _obtenerIconoEvento(evento) : null,
                color: textoEq, 
                size: 38,
                iconSize: 22
              ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              Traductor.get(evento).toUpperCase(), 
              textAlign: TextAlign.center, 
              style: TextStyle(
                color: isDragging ? textoEq : textoEq.withOpacity(0.9), 
                fontWeight: isDragging ? FontWeight.bold : FontWeight.w600, 
                fontSize: 9.5, 
                letterSpacing: 0.8
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override 
  Widget build(BuildContext context) {
    Color fondoEq = widget.equipoSeleccionado == 'Local' ? widget.partido.localFondo : widget.partido.visitaFondo;
    Color textoEq = widget.equipoSeleccionado == 'Local' ? widget.partido.localTexto : widget.partido.visitaTexto;
    String nombreEq = widget.equipoSeleccionado == 'Local' ? widget.partido.local : widget.partido.visita;
    Color appBarColor = fondoEq == Colors.black ? const Color(0xFF111111) : fondoEq;

    // Detectamos si es PC o pantalla ancha para ajustar columnas
    double width = MediaQuery.of(context).size.width;
    int columnas = width > 600 ? 4 : 2; // En PC mostramos 4 columnas

    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: Text('${Traductor.get('registro_dp')} ${nombreEq.toUpperCase()}', style: TextStyle(color: textoEq, fontSize: 13, fontWeight: FontWeight.bold)), 
        backgroundColor: appBarColor,
        leading: BackButton(color: textoEq), 
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: appBarColor.withOpacity(0.2),
            child: Text(Traductor.get('mantenga_presionado'), textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, letterSpacing: 1)),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnas, 
                crossAxisSpacing: 12, 
                mainAxisSpacing: 12, 
                childAspectRatio: 1.3 // Botones un poco más "cuadrados" y compactos
              ),
              itemCount: widget.partido.ordenEventosActivos.length,
              itemBuilder: (context, index) {
                String evento = widget.partido.ordenEventosActivos[index];
                return DragTarget<int>(
                  onAccept: (draggedIndex) {
                    setState(() {
                      String temp = widget.partido.ordenEventosActivos[index];
                      widget.partido.ordenEventosActivos[index] = widget.partido.ordenEventosActivos[draggedIndex];
                      widget.partido.ordenEventosActivos[draggedIndex] = temp;
                    });
                    QuantumStorage.guardarPartidoActivo(widget.partido); 
                  },
                  builder: (context, candidateData, rejectedData) {
                    return LongPressDraggable<int>(
                      data: index,
                      delay: const Duration(milliseconds: 300), 
                      feedback: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: (width / columnas) - 20, 
                          height: 80, 
                          child: _buildCajaEvento(evento, fondoEq, textoEq, true),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: 0.2, child: _buildCajaEvento(evento, fondoEq, textoEq, false)),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _pedirJugador(context, evento, fondoEq, textoEq, nombreEq);
                        },
                        child: _buildCajaEvento(evento, fondoEq, textoEq, false),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}