import 'package:flutter/material.dart';
import 'package:mi_nueva_app/core/constants.dart';
import 'package:mi_nueva_app/core/globals.dart';
import 'package:mi_nueva_app/core/traductor.dart';
import 'package:mi_nueva_app/core/quantum_storage.dart';
import 'package:mi_nueva_app/models/partido.dart';

class PantallaRegistroEvento extends StatefulWidget {
  final Partido partido;
  final String equipoSeleccionado;

  const PantallaRegistroEvento({super.key, required this.partido, required this.equipoSeleccionado});

  @override
  State<PantallaRegistroEvento> createState() => _PantallaRegistroEventoState();
}

class _PantallaRegistroEventoState extends State<PantallaRegistroEvento> {
  
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
                    Navigator.pop(ctxDialog); // Closes Dialog
                    Navigator.pop(context, {   // Closes Screen with result
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
        color: fondoEq.withOpacity(isDragging ? 0.3 : 0.1),
        border: Border.all(color: isDragging ? textoEq : (fondoEq == Colors.black ? Colors.white24 : fondoEq)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDragging ? [BoxShadow(color: textoEq.withOpacity(0.5), blurRadius: 10)] : [],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Traductor.get(evento).toUpperCase(), 
              textAlign: TextAlign.center, 
              style: TextStyle(color: textoEq, fontWeight: FontWeight.bold, fontSize: 12)
            ),
          ),
        ),
      ),
    );
  }

  @override 
  Widget build(BuildContext context) {
    Color fondoEq = widget.equipoSeleccionado == 'Local' ? widget.partido.localFondo : widget.partido.visitaFondo;
    Color textoEq = widget.equipoSeleccionado == 'Local' ? widget.partido.localTexto : widget.partido.visitaTexto;
    String nombreEq = widget.equipoSeleccionado == 'Local' ? widget.partido.local : widget.partido.visita;
    Color appBarColor = fondoEq == Colors.black ? const Color(0xFF111111) : fondoEq;

    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: Text('${Traductor.get('registro_dp')} ${nombreEq.toUpperCase()}', style: TextStyle(color: textoEq, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)), 
        backgroundColor: appBarColor,
        leading: BackButton(color: textoEq), 
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Text(Traductor.get('mantenga_presionado'), style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.5),
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
                          width: MediaQuery.of(context).size.width / 2.3, 
                          height: 70, 
                          child: _buildCajaEvento(evento, fondoEq, textoEq, true),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: 0.2, child: _buildCajaEvento(evento, fondoEq, textoEq, false)),
                      child: InkWell(
                        onTap: () => _pedirJugador(context, evento, fondoEq, textoEq, nombreEq),
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

