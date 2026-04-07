// ignore_for_file: prefer_const_constructors, unused_import, prefer_const_literals_to_create_immutables, use_key_in_widget_constructors, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_nueva_app/core/constants.dart';
import 'package:mi_nueva_app/core/globals.dart';
import 'package:mi_nueva_app/core/traductor.dart';
import 'package:mi_nueva_app/core/quantum_storage.dart';
import 'package:mi_nueva_app/models/partido.dart';
import 'package:mi_nueva_app/models/deporte_config.dart';

class PantallaRegistroEvento extends StatefulWidget {
  final Partido partido;
  final String equipoSeleccionado;

  const PantallaRegistroEvento({super.key, required this.partido, required this.equipoSeleccionado});

  @override
  State<PantallaRegistroEvento> createState() => _PantallaRegistroEventoState();
}

class _PantallaRegistroEventoState extends State<PantallaRegistroEvento> {
  
  // Mapeo rápido de iconos por palabra clave para que el periodista identifique visualmente
  IconData _obtenerIconoEvento(String evento) {
    String ev = evento.toLowerCase();
    if (ev.contains('gol') || ev.contains('remate') || ev.contains('tiro')) return Icons.sports_soccer;
    if (ev.contains('tarjeta')) return Icons.style;
    if (ev.contains('cambio')) return Icons.sync;
    if (ev.contains('falta') || ev.contains('penal')) return Icons.gavel;
    if (ev.contains('corner')) return Icons.flag;
    if (ev.contains('rebote')) return Icons.sports_basketball;
    if (ev.contains('try') || ev.contains('conversi')) return Icons.sports_rugby;
    if (ev.contains('ace') || ev.contains('punto')) return Icons.sports_tennis;
    if (ev.contains('asistencia')) return Icons.handshake;
    return Icons.ads_click; // Icono por defecto
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
    return Container(
      decoration: BoxDecoration(
        color: fondoEq.withOpacity(isDragging ? 0.3 : 0.08),
        border: Border.all(color: isDragging ? textoEq : (fondoEq == Colors.black ? Colors.white12 : fondoEq.withOpacity(0.3))),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isDragging ? [BoxShadow(color: textoEq.withOpacity(0.3), blurRadius: 10)] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_obtenerIconoEvento(evento), color: textoEq.withOpacity(0.8), size: 22),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Traductor.get(evento).toUpperCase(), 
                textAlign: TextAlign.center, 
                style: TextStyle(color: textoEq, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)
              ),
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