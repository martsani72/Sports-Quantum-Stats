// ignore_for_file: prefer_const_constructors, unused_import, prefer_const_literals_to_create_immutables, use_key_in_widget_constructors, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:mi_nueva_app/core/constants.dart';
import 'package:mi_nueva_app/core/traductor.dart';
import 'package:mi_nueva_app/models/deporte_config.dart';
import 'package:mi_nueva_app/widgets/widget_camiseta.dart';
import 'package:mi_nueva_app/screens/pantalla_configuracion_dinamica.dart';
import 'package:mi_nueva_app/models/partido.dart';

class PantallaDatosEncuentro extends StatefulWidget {
  final String nombreDeporte;
  final Map<String, dynamic> configInicial;

  const PantallaDatosEncuentro({
    super.key, 
    required this.nombreDeporte, 
    required this.configInicial
  });

  @override 
  State<PantallaDatosEncuentro> createState() => _PantallaDatosEncuentroState();
}

class _PantallaDatosEncuentroState extends State<PantallaDatosEncuentro> {
  final TextEditingController _torneoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _tituloController = TextEditingController();

  final TextEditingController _nombreLocalController = TextEditingController();
  final TextEditingController _jugadoresLocalController = TextEditingController();
  final TextEditingController _nombreVisitaController = TextEditingController();
  final TextEditingController _jugadoresVisitaController = TextEditingController();

  Color _localFondo = Colors.blue;
  Color _localTexto = Colors.white;
  Color _visitaFondo = Colors.red;
  Color _visitaTexto = Colors.white;

  PatronCamiseta _patronLocal = PatronCamiseta.liso;
  PatronCamiseta _patronVisita = PatronCamiseta.liso;

  final FocusNode _focusJugadoresLocal = FocusNode();
  final FocusNode _focusJugadoresVisita = FocusNode();
  
  bool _mostrarTooltipLocal = false;
  bool _mostrarTooltipVisita = false;

  @override
  void initState() {
    super.initState();
    // Fecha por defecto: hoy
    DateTime hoy = DateTime.now();
    _fechaController.text = "${hoy.day}/${hoy.month}/${hoy.year}";
    
    _focusJugadoresLocal.addListener(() {
      if (_focusJugadoresLocal.hasFocus) {
        setState(() => _mostrarTooltipLocal = true);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _mostrarTooltipLocal = false);
        });
      }
    });

    _focusJugadoresVisita.addListener(() {
      if (_focusJugadoresVisita.hasFocus) {
        setState(() => _mostrarTooltipVisita = true);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _mostrarTooltipVisita = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _focusJugadoresLocal.dispose();
    _focusJugadoresVisita.dispose();
    _torneoController.dispose();
    _fechaController.dispose();
    _tituloController.dispose();
    _nombreLocalController.dispose();
    _jugadoresLocalController.dispose();
    _nombreVisitaController.dispose();
    _jugadoresVisitaController.dispose();
    super.dispose();
  }

  Map<String, String> _parsearPlanilla(String texto) {
    Map<String, String> resultado = {};
    if (texto.trim().isEmpty) return resultado;
    List<String> lineas = texto.split('\n');
    for (String linea in lineas) {
      linea = linea.trim();
      if (linea.isEmpty) continue;
      int primerEspacio = linea.indexOf(' ');
      if (primerEspacio != -1) {
        String numero = linea.substring(0, primerEspacio).trim();
        String nombre = linea.substring(primerEspacio + 1).trim();
        resultado[numero] = nombre;
      } else {
        resultado[linea] = ''; 
      }
    }
    return resultado;
  }

  Future<Color?> _seleccionarColor(BuildContext context, {bool esDetalle = false}) {
    List<Color> paleta = [
      Colors.black, const Color(0xFF111111), Colors.white, Colors.grey, 
      Colors.red, const Color(0xFF800000), // Maroon
      Colors.blue, const Color(0xFF001F70), // Deep Navy
      const Color(0xFF87CEEB), // Sky Blue
      Colors.green, const Color(0xFF006400), // Dark Green
      const Color(0xFF32CD32), // Lime
      Colors.yellow, const Color(0xFFFFD700), // Gold
      Colors.orange, const Color(0xFFD2691E), // Chocolate/Brown
      Colors.purple, const Color(0xFF4B0082), // Indigo
      Colors.cyan, const Color(0xFF008080), // Teal
      Colors.pink, const Color(0xFFFF1493), // Deep Pink
      const Color(0xFFE0E0E0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];
    return showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kNegro,
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: Text(Traductor.get('elegir_color'), style: TextStyle(color: kVerdeNeon, fontSize: 14)),
        content: Wrap(
          spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
          children: paleta.map((c) => InkWell(
            onTap: () => Navigator.pop(ctx, c),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: c, border: Border.all(color: Colors.white38), shape: BoxShape.circle),
            )
          )).toList()
        )
      )
    );
  }

  Future<PatronCamiseta?> _seleccionarPatron(BuildContext context, Color fondo, Color texto) {
    return showDialog<PatronCamiseta>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
        title: Text(Traductor.get('elegir_diseno').toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 13, letterSpacing: 2)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 15, runSpacing: 15, alignment: WrapAlignment.center,
              children: PatronCamiseta.values.map((patron) => InkWell(
                onTap: () => Navigator.pop(ctx, patron),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                  child: WidgetCamiseta(fondo: fondo, detalle: texto, patron: patron, deporte: widget.nombreDeporte),
                ),
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color fillColor) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.white54),
      filled: true, fillColor: fillColor == Colors.transparent ? Colors.white.withOpacity(0.05) : fillColor.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: kVerdeOscuro)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kVerdeNeon)),
    );
  }

  Widget _buildSelectorColor(String titulo, Color colorActual, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: colorActual, border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(color: Colors.white54, fontSize: 10))
        ],
      ),
    );
  }

  Widget _buildSelectorPatron(String titulo, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: Colors.white10, border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(5)),
            child: const Icon(Icons.checkroom, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(color: Colors.white54, fontSize: 10))
        ],
      ),
    );
  }

  Widget _buildInfoGeneral() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Traductor.get('datos_encuentro'), style: const TextStyle(color: kVerdeNeon, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _torneoController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(Traductor.get('torneo_opcional_hint'), Colors.transparent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _fechaController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration(Traductor.get('fecha_hint'), Colors.transparent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tituloController,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(Traductor.get('titulo_partido_ej_hint'), Colors.transparent),
          )
        ],
      ),
    );
  }

  Widget _buildEquipo(String tipo, TextEditingController nombreCtrl, TextEditingController jugCtrl, FocusNode focusNode, Color fondo, Color texto, PatronCamiseta patron, bool mostrarTooltip, Function(Color) onFondo, Function(Color) onTexto, Function(PatronCamiseta) onPatron) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fondo.withOpacity(0.5), width: 1.5)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${Traductor.get('equipo_mayus')}$tipo", style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nombreCtrl,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(tipo == 'LOCAL' ? Traductor.get('nombre_local_hint') : Traductor.get('nombre_visita_hint'), fondo),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSelectorColor(Traductor.get('fondo_mayus'), fondo, () async { Color? c = await _seleccionarColor(context); if (c != null) onFondo(c); }),
              _buildSelectorColor(Traductor.get('detalle_mayus'), texto, () async { Color? c = await _seleccionarColor(context, esDetalle: true); if (c != null) onTexto(c); }),
              _buildSelectorPatron(Traductor.get('diseno_mayus'), () async { PatronCamiseta? p = await _seleccionarPatron(context, fondo, texto); if (p != null) onPatron(p); }),
              WidgetCamiseta(fondo: fondo, detalle: texto, patron: patron, deporte: widget.nombreDeporte),
            ],
          ),
          const SizedBox(height: 15),
          Stack(
            clipBehavior: Clip.none,
            children: [
              TextField(
                controller: jugCtrl,
                focusNode: focusNode,
                maxLines: null,
                minLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDecoration(Traductor.get('pega_lista_hint'), Colors.transparent)
              ),
              Positioned(
                top: -35,
                left: 10,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: mostrarTooltip ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kVerdeNeon,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: kNegro, size: 14),
                          const SizedBox(width: 5),
                          Text(Traductor.get('copia_lista_whatsapp'), style: const TextStyle(color: kNegro, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _continuar() {
    String nombreLoc = _nombreLocalController.text.trim().isEmpty ? "LOCAL" : _nombreLocalController.text.trim();
    String nombreVis = _nombreVisitaController.text.trim().isEmpty ? "VISITA" : _nombreVisitaController.text.trim();

    Map<String, dynamic> datosEncuentro = {
      'torneo': _torneoController.text.trim(),
      'fecha': _fechaController.text.trim(),
      'titulo': _tituloController.text.trim(),
      'local': nombreLoc,
      'visita': nombreVis,
      'jugadoresLocal': _parsearPlanilla(_jugadoresLocalController.text),
      'jugadoresVisita': _parsearPlanilla(_jugadoresVisitaController.text),
      'localFondo': _localFondo,
      'localTexto': _localTexto,
      'visitaFondo': _visitaFondo,
      'visitaTexto': _visitaTexto,
      'patronLocal': _patronLocal,
      'patronVisita': _patronVisita,
    };

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => PantallaConfiguracionDinamica(
        nombreDeporte: widget.nombreDeporte,
        configInicial: widget.configInicial,
        datosEncuentro: datosEncuentro,
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        backgroundColor: kNegro, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kVerdeNeon), onPressed: () => Navigator.pop(context)),
        title: Text("${Traductor.get('nuevo_partido_de')}${widget.nombreDeporte.toUpperCase()}", style: const TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildInfoGeneral(),
                  _buildEquipo('LOCAL', _nombreLocalController, _jugadoresLocalController, _focusJugadoresLocal, _localFondo, _localTexto, _patronLocal, _mostrarTooltipLocal, (c) => setState(() => _localFondo = c), (c) => setState(() => _localTexto = c), (p) => setState(() => _patronLocal = p)),
                  _buildEquipo('VISITA', _nombreVisitaController, _jugadoresVisitaController, _focusJugadoresVisita, _visitaFondo, _visitaTexto, _patronVisita, _mostrarTooltipVisita, (c) => setState(() => _visitaFondo = c), (c) => setState(() => _visitaTexto = c), (p) => setState(() => _patronVisita = p)),
                ],
              )
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: kVerdeOscuro, width: 1)), color: kNegro),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon, padding: const EdgeInsets.all(15)),
                  onPressed: _continuar, 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(Traductor.get('siguiente_reglas'), style: const TextStyle(color: kNegro, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward, color: kNegro, size: 20)
                    ],
                  ),
                ),
              ),
            )
          ],
        )
      )
    );
  }
}
