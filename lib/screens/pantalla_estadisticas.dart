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
import 'package:mi_nueva_app/screens/pantalla_resumen_partido.dart';

class PantallaEstadisticas extends StatefulWidget {
  const PantallaEstadisticas({super.key});

  @override
  State<PantallaEstadisticas> createState() => _PantallaEstadisticasState();
}

class _PantallaEstadisticasState extends State<PantallaEstadisticas> {
  String _deporteFiltro = 'Fútbol';
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Intentar inicializar con el primer deporte que tenga partidos
    if (partidosGuardados.isNotEmpty) {
      _deporteFiltro = partidosGuardados.first.deporte;
    }
  }

  List<Partido> get _partidosFiltrados {
    return partidosGuardados.where((p) {
      bool coincideDeporte = p.deporte == _deporteFiltro;
      if (_query.isEmpty) return coincideDeporte;

      String q = _query.toLowerCase();
      bool coincideBusqueda = p.local.toLowerCase().contains(q) || 
                              p.visita.toLowerCase().contains(q) || 
                              p.titulo.toLowerCase().contains(q);
      
      return coincideDeporte && coincideBusqueda;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Partido> filtrados = _partidosFiltrados;
    
    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        title: Text(Traductor.get('menu_3').toUpperCase(), style: const TextStyle(color: kVerdeNeon, fontSize: 14, letterSpacing: 2)),
        backgroundColor: const Color(0xFF0A0A0A),
        leading: const BackButton(color: kVerdeNeon),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSelectorDeportes(),
          _buildBarraBusqueda(),
          Expanded(
            child: filtrados.isEmpty 
              ? _buildPantallaVacia()
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    _buildGridMetricas(filtrados),
                    const SizedBox(height: 30),
                    _buildSeccionTopEquipos(filtrados),
                    const SizedBox(height: 30),
                    _buildListaRecientes(filtrados),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorDeportes() {
    List<String> deportesDisponibles = DeporteConfig.datos.keys.toList();
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(color: Color(0xFF0A0A0A), border: Border(bottom: BorderSide(color: Colors.white12))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: deportesDisponibles.length,
        itemBuilder: (context, index) {
          String dep = deportesDisponibles[index];
          bool seleccionado = _deporteFiltro == dep;
          IconData icono = DeporteConfig.datos[dep]!['icono'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
              onTap: () => setState(() => _deporteFiltro = dep),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: seleccionado ? kVerdeNeon : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: seleccionado ? kVerdeNeon : Colors.white.withOpacity(0.05)),
                  boxShadow: seleccionado ? [BoxShadow(color: kVerdeNeon.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)] : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icono, size: 14, color: seleccionado ? kNegro : Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      Traductor.get(dep).toUpperCase(),
                      style: TextStyle(
                        color: seleccionado ? kNegro : Colors.white54, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return Container(
      padding: const EdgeInsets.all(15),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _query = val),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: Traductor.get('buscar_equipo_hint'),
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: kVerdeNeon),
          suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.white24, size: 18), onPressed: () { _searchController.clear(); setState(() => _query = ''); }) : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.03),
          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: kVerdeNeon), borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildGridMetricas(List<Partido> filtrados) {
    // Cálculos
    double avgPosLocal = 0;
    int partidosConPosesion = 0;
    int totalPuntos = 0;
    int totalAcciones = 0;
    int totalTarjetas = 0;
    int victorias = 0;
    bool buscandoEspecifico = _query.isNotEmpty;

    for (var p in filtrados) {
      // Posesión
      int tL = p.posesionSegundos['Local'] ?? 0;
      int tV = p.posesionSegundos['Visita'] ?? 0;
      if (tL + tV > 0) {
        avgPosLocal += (tL / (tL + tV));
        partidosConPosesion++;
      }
      
      // Puntos y Acciones
      totalPuntos += (p.obtenerPuntaje('Local') + p.obtenerPuntaje('Visita'));
      totalAcciones += p.historialAcciones.length;
      totalTarjetas += (p.tarjetas['Local']!.length + p.tarjetas['Visita']!.length);

      // Si busca un equipo específico, calcular victorias para ese equipo
      if (buscandoEspecifico) {
        String q = _query.toLowerCase();
        int pL = p.obtenerPuntaje('Local');
        int pV = p.obtenerPuntaje('Visita');
        if (p.local.toLowerCase().contains(q)) {
          if (pL > pV) victorias++;
        } else if (p.visita.toLowerCase().contains(q)) {
          if (pV > pL) victorias++;
        }
      }
    }

    double posFinal = partidosConPosesion > 0 ? (avgPosLocal / partidosConPosesion) * 100 : 50.0;
    double pntPromedio = filtrados.isNotEmpty ? totalPuntos / filtrados.length : 0;
    double cardRate = filtrados.isNotEmpty ? totalTarjetas / filtrados.length : 0;
    double intensity = filtrados.isNotEmpty ? totalAcciones / (filtrados.length * 90) : 0; // Acciones por minuto sim (Asumiendo 90 min)

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _buildCardMetrica(
          buscandoEspecifico ? Traductor.get('victorias') : Traductor.get('promedio_posesion'), 
          buscandoEspecifico ? '$victorias / ${filtrados.length}' : '${posFinal.toStringAsFixed(0)}%', 
          Icons.query_stats, 
          buscandoEspecifico ? kVerdeNeon : kCelestePlay
        ),
        _buildCardMetrica(
          'PUNTOS / P', 
          pntPromedio.toStringAsFixed(1), 
          Icons.onetwothree, 
          Colors.orangeAccent
        ),
        _buildCardMetrica(
          Traductor.get('indicador_disciplina'), 
          cardRate.toStringAsFixed(1), 
          Icons.style, 
          Colors.redAccent
        ),
        _buildCardMetrica(
          Traductor.get('ritmo_juego'), 
          intensity.toStringAsFixed(2), 
          Icons.speed, 
          kVerdeNeon
        ),
      ],
    );
  }

  Widget _buildCardMetrica(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(valor, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(titulo, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSeccionTopEquipos(List<Partido> filtrados) {
    Map<String, int> conteo = {};
    for (var p in filtrados) {
      conteo[p.local] = (conteo[p.local] ?? 0) + 1;
      conteo[p.visita] = (conteo[p.visita] ?? 0) + 1;
    }
    
    var listaTop = conteo.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var top3 = listaTop.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Traductor.get('top_equipos'), style: const TextStyle(color: kVerdeNeon, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 15),
        if (top3.isEmpty) 
          const Text('No hay equipos suficientes', style: TextStyle(color: Colors.white24, fontSize: 12))
        else
          ...top3.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Colors.white24, size: 16),
                const SizedBox(width: 15),
                Expanded(child: Text(e.key.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                Text('${e.value} rec.', style: const TextStyle(color: kVerdeNeon, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildListaRecientes(List<Partido> filtrados) {
    var ultimos = filtrados.reversed.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REGISTROS RECIENTES', style: const TextStyle(color: kVerdeNeon, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 15),
        ...ultimos.map((p) => ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaResumenPartido(partido: p))),
          contentPadding: EdgeInsets.zero,
          title: Text('${p.local} vs ${p.visita}', style: const TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: Text(p.titulo.isNotEmpty ? p.titulo : p.deporte, style: const TextStyle(color: Colors.white24, fontSize: 11)),
          trailing: Text('${p.obtenerPuntaje('Local')} - ${p.obtenerPuntaje('Visita')}', style: const TextStyle(color: kVerdeNeon, fontWeight: FontWeight.bold, fontSize: 14)),
        )).toList(),
      ],
    );
  }

  Widget _buildPantallaVacia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats, color: Colors.white10, size: 80),
          const SizedBox(height: 20),
          Text(Traductor.get('sin_datos_filtro'), style: const TextStyle(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }
}
