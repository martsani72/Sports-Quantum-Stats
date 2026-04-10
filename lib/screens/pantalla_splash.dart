import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mi_nueva_app/core/constants.dart';
import 'package:mi_nueva_app/core/traductor.dart';
import 'package:mi_nueva_app/assets_data.dart';
import 'package:mi_nueva_app/screens/pantalla_principal.dart';

class PantallaSplash extends StatefulWidget {
  const PantallaSplash({super.key});

  @override
  State<PantallaSplash> createState() => _PantallaSplashState();
}

class _PantallaSplashState extends State<PantallaSplash> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;


  @override
  void initState() {
    super.initState();
    


    // Configuración del Pulso Lento (Respiración)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Navegar automáticamente después de 3 segundos
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const PantallaPrincipal(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNegro,
      body: Center(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo con Pulso
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          kVerdeNeon,
                          BlendMode.modulate,
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 140, // Ajustado de 180 a 140 para mayor seguridad
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.lightbulb_outline, color: kVerdeNeon, size: 80),
                        ),
                      ),
                  ),
                ),
                const SizedBox(height: 40),
                // Título con Aparición Suave
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        'SPORTS',
                        style: TextStyle(
                          color: kVerdeNeon.withOpacity(0.8),
                          fontSize: 16,
                          letterSpacing: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'QUANTUM STATS',
                        style: TextStyle(
                          color: kVerdeNeon,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
