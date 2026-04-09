import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:mi_nueva_app/core/constants.dart';

class WidgetIconoQuantum extends StatelessWidget {
  final IconData? icono;
  final String? emoticon;
  final String? tipoArte; // 'goal', 'whistle', 'soccer', 'rugby'
  final Color color;
  final double size;
  final double iconSize;

  const WidgetIconoQuantum({
    super.key,
    this.icono,
    this.emoticon,
    this.tipoArte,
    required this.color,
    this.size = 40.0,
    this.iconSize = 20.0,
  }) : assert(icono != null || emoticon != null || tipoArte != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: _buildContenido(),
      ),
    );
  }

  Widget _buildContenido() {
    if (tipoArte != null) {
      return SizedBox(
        width: iconSize * 1.5,
        height: iconSize * 1.5,
        child: CustomPaint(
          painter: _obtenerPainter(),
        ),
      );
    }
    if (emoticon != null) {
      return Text(
        emoticon!,
        style: TextStyle(fontSize: iconSize),
      );
    }
    return Icon(
      icono,
      color: color,
      size: iconSize,
    );
  }

  CustomPainter _obtenerPainter() {
    switch (tipoArte) {
      case 'goal': return _GoalPainter(color: color);
      case 'whistle': return _WhistlePainter(color: color);
      case 'soccer': return _BallPainter(color: color, tipo: 'soccer');
      case 'rugby': return _BallPainter(color: color, tipo: 'rugby');
      case 'basketball': return _BallPainter(color: color, tipo: 'basketball');
      case 'flag': return _FlagPainter(color: color);
      default: return _WhistlePainter(color: color);
    }
  }
}

class _FlagPainter extends CustomPainter {
  final Color color;
  _FlagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paintPalo = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final paintBandera = Paint()..color = Colors.redAccent..style = PaintingStyle.fill;
    
    double w = size.width;
    double h = size.height;

    // Palo con sombra
    canvas.drawLine(Offset(w * 0.2, h * 0.9), Offset(w * 0.2, h * 0.1), paintPalo);
    
    // Bandera con efecto de movimiento
    Path path = Path();
    path.moveTo(w * 0.2, h * 0.1);
    path.quadraticBezierTo(w * 0.5, h * 0.05, w * 0.85, h * 0.25);
    path.quadraticBezierTo(w * 0.5, h * 0.45, w * 0.2, h * 0.4);
    path.close();
    
    canvas.drawPath(path, paintBandera);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

class _GoalPainter extends CustomPainter {
  final Color color;
  _GoalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paintPoste = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey.shade400, Colors.white, Colors.grey.shade400],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintRed = Paint()..color = Colors.white.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 0.8;

    double w = size.width;
    double h = size.height;

    // Red (Trama romboidal en perspectiva)
    for (double i = 0.3; i < 0.9; i += 0.15) {
      canvas.drawLine(Offset(w * 0.1, h * i), Offset(w * 0.9, h * (i - 0.1)), paintRed);
      canvas.drawLine(Offset(w * 0.9, h * i), Offset(w * 0.1, h * (i - 0.1)), paintRed);
    }

    // Estructura del Arco
    Path arco = Path();
    arco.moveTo(w * 0.1, h * 0.9);
    arco.lineTo(w * 0.1, h * 0.25);
    arco.lineTo(w * 0.9, h * 0.25);
    arco.lineTo(w * 0.9, h * 0.9);
    canvas.drawPath(arco, paintPoste);
    
    // Base de profundidad sutil
    canvas.drawLine(Offset(w * 0.1, h * 0.9), Offset(w * 0.9, h * 0.9), paintRed);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

class _WhistlePainter extends CustomPainter {
  final Color color;
  _WhistlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paintCuerpo = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey.shade700, Colors.white, Colors.grey.shade800],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    
    final paintDetalle = Paint()..color = Colors.black45..style = PaintingStyle.fill;

    double w = size.width;
    double h = size.height;

    // Mango/Cuerpo
    canvas.drawCircle(Offset(w * 0.35, h * 0.5), w * 0.3, paintCuerpo);
    // Boquilla
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.4, h * 0.35, w * 0.5, h * 0.3), const Radius.circular(4)), paintCuerpo);
    // Orificio de aire
    canvas.drawRect(Rect.fromLTWH(w * 0.45, h * 0.4, w * 0.15, h * 0.08), paintDetalle);
    // Anillo de sujeción
    canvas.drawCircle(Offset(w * 0.1, h * 0.5), w * 0.08, Paint()..color = Colors.white54..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

class _BallPainter extends CustomPainter {
  final Color color;
  final String tipo; 
  _BallPainter({required this.color, required this.tipo});

  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width;
    double h = size.height;
    final center = Offset(w/2, h/2);
    final radius = w * 0.45;

    if (tipo == 'rugby') {
      final paintRugby = Paint()..color = const Color(0xFF8B4513)..style = PaintingStyle.fill;
      final paintSombra = Paint()
        ..shader = RadialGradient(colors: [Colors.transparent, Colors.black38]).createShader(Rect.fromCircle(center: center, radius: radius));
        
      canvas.save();
      canvas.translate(w/2, h/2);
      canvas.rotate(0.4);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.9, height: h * 0.6), paintRugby);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.9, height: h * 0.6), paintSombra);
      // Cordones
      final pCordones = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5;
      canvas.drawLine(const Offset(-10, 0), const Offset(10, 0), pCordones);
      for(double i=-8; i<=8; i+=4) canvas.drawLine(Offset(i, -3), Offset(i, 3), pCordones);
      canvas.restore();
    } else if (tipo == 'basketball') {
      final paintBask = Paint()..color = Colors.orange..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, paintBask);
      final pLines = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.0;
      canvas.drawCircle(center, radius, pLines);
      canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), pLines);
      canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), pLines);
      canvas.drawArc(Rect.fromCircle(center: Offset(center.dx-radius*1.2, center.dy), radius: radius), -0.8, 1.6, false, pLines);
      canvas.drawArc(Rect.fromCircle(center: Offset(center.dx+radius*1.2, center.dy), radius: radius), 2.3, 1.6, false, pLines);
    } else {
      // FÚTBOL TRADICIONAL 3D
      final paintBase = Paint()..color = Colors.white..style = PaintingStyle.fill;
      final paintSombra = Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black26],
          stops: const [0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      
      canvas.drawCircle(center, radius, paintBase);
      
      // Pentágonos negros (Tradicional)
      final paintHex = Paint()..color = Colors.black87..style = PaintingStyle.fill;
      
      // Pentágono central
      _drawRegularPolygon(canvas, center, radius * 0.35, 5, paintHex);
      
      // Fragmentos de pentágonos en los bordes
      for (double i = 0; i < 5; i++) {
        double angle = i * (2 * math.pi / 5) - math.pi/2;
        Offset pos = center + Offset(math.cos(angle), math.sin(angle)) * radius;
        _drawRegularPolygon(canvas, pos, radius * 0.3, 5, paintHex);
      }
      
      canvas.drawCircle(center, radius, paintSombra);
      canvas.drawCircle(center, radius, Paint()..color = Colors.black12..style = PaintingStyle.stroke..strokeWidth = 0.5);
    }
  }

  void _drawRegularPolygon(Canvas canvas, Offset center, double radius, int sides, Paint paint) {
    Path path = Path();
    for (int i = 0; i < sides; i++) {
      double angle = i * (2 * math.pi / sides) - math.pi/2;
      double x = center.dx + math.cos(angle) * radius;
      double y = center.dy + math.sin(angle) * radius;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override bool shouldRepaint(CustomPainter old) => false;
}

class WidgetTarjetaFisicaQuantum extends StatelessWidget {
  final Color color;
  final String numero;
  final double height;

  const WidgetTarjetaFisicaQuantum({
    super.key,
    required this.color,
    required this.numero,
    this.height = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: height * 0.7,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
      ),
      child: Center(
        child: Text(
          numero,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
