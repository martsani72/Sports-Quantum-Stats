import 'package:flutter/material.dart';
import 'package:mi_nueva_app/core/constants.dart';
import 'package:mi_nueva_app/core/purchases_service.dart';
import 'package:mi_nueva_app/core/traductor.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PantallaPremium extends StatefulWidget {
  const PantallaPremium({Key? key}) : super(key: key);

  @override
  _PantallaPremiumState createState() => _PantallaPremiumState();
}

class _PantallaPremiumState extends State<PantallaPremium> {
  Offering? _offering;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offering = await PurchasesService().getCurrentOffering();
    if (mounted) {
      setState(() {
        _offering = offering;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNegro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(Traductor.get('premium_mayus') ?? 'PREMIUM', style: const TextStyle(color: kVerdeNeon, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kVerdeNeon))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.stars, color: kVerdeNeon, size: 80),
                const SizedBox(height: 20),
                Text(
                  Traductor.get('beneficios_premium') ?? 'DISFRUTA LA EXPERIENCIA COMPLETA',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                _buildBenefitRow(Icons.block, 'Sin anuncios publicitarios'),
                _buildBenefitRow(Icons.bolt, 'Mayor rapidez en la app'),
                _buildBenefitRow(Icons.favorite, 'Apoya el desarrollo continuo'),
                
                const SizedBox(height: 40),
                
                if (_offering == null || _offering!.availablePackages.isEmpty)
                  const Text("No hay ofertas disponibles en este momento.", style: TextStyle(color: Colors.white54))
                else
                  ..._offering!.availablePackages.map((package) => _buildPackageCard(package)).toList(),
                
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    await PurchasesService().restorePurchases();
                    if (PurchasesService().isPremium.value) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Suscripción restaurada con éxito!")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se encontraron compras para restaurar.")));
                    }
                  },
                  child: const Text("RESTAURAR COMPRAS", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: kVerdeNeon, size: 24),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Package package) {
    String title = package.packageType.toString().split('.').last.toUpperCase();
    if (title == 'LIFETIME') title = 'DE POR VIDA';
    if (title == 'ANNUAL') title = 'ANUAL';
    if (title == 'MONTHLY') title = 'MENSUAL';

    return GestureDetector(
      onTap: () async {
        setState(() => _isLoading = true);
        bool success = await PurchasesService().purchasePackage(package);
        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            Navigator.pop(context);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: kVerdeNeon.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: kVerdeNeon, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 5),
                Text(package.storeProduct.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            Text(
              package.storeProduct.priceString,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
