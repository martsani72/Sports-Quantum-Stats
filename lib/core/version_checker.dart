import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:mi_nueva_app/core/traductor.dart';
import 'package:mi_nueva_app/core/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionChecker {
  // CONFIGURACIÓN: Cambiar esta URL por tu propio Gist o archivo JSON en GitHub
  static const String _versionUrl = 'https://raw.githubusercontent.com/martsani72/Sports-Quantum-Stats/main/version_config.json';

  static Future<void> checkVersion(BuildContext context) async {
    try {
      // 1. Obtener versión actual de la app
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version; // Ejemplo: "1.0.0"

      // 2. Consultar versión mínima permitida en el servidor
      final response = await http.get(Uri.parse(_versionUrl)).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        String minVersion = data['min_version'] ?? '1.0.0';
        String storeUrl = data['store_url'] ?? 'https://play.google.com/store/apps/details?id=martsani72.sports_quantum_stats';

        if (_isVersionLower(currentVersion, minVersion)) {
          _mostrarDialogoActualizacion(context, storeUrl);
        }
      }
    } catch (e) {
      // Si falla la conexión, permitimos seguir (no bloqueamos al usuario si no tiene internet)
      debugPrint('Error chequeando versión: $e');
    }
  }

  static bool _isVersionLower(String current, String min) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> minParts = min.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        int c = i < currentParts.length ? currentParts[i] : 0;
        int m = i < minParts.length ? minParts[i] : 0;
        if (c < m) return true;
        if (c > m) return false;
      }
    } catch (_) {}
    return false;
  }

  static void _mostrarDialogoActualizacion(BuildContext context, String storeUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // OBLIGATORIO: No se puede cerrar
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Bloquea botón atrás en Android
        child: AlertDialog(
          backgroundColor: kNegro,
          shape: RoundedRectangleBorder(side: const BorderSide(color: kVerdeNeon, width: 2), borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.system_update, color: kVerdeNeon),
              const SizedBox(width: 10),
              Text(Traductor.get('actualizacion_requerida'), style: const TextStyle(color: kVerdeNeon, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          content: Text(
            Traductor.get('msj_actualizacion'),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kVerdeNeon, minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                final Uri url = Uri.parse(storeUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(Traductor.get('actualizar_ahora'), style: const TextStyle(color: kNegro, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
