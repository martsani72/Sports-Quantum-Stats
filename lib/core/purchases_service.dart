import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io' show Platform;

class PurchasesService {
  static final PurchasesService _instance = PurchasesService._internal();
  factory PurchasesService() => _instance;
  PurchasesService._internal();

  static const _apiKey = "goog_sAoCaxSFrkwexNGlfbbZBZktWKT";
  static const _entitlementId = "premium_access"; // Debes crear este Entitlement en RevenueCat

  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);

  Future<void> init() async {
    if (kIsWeb) return;
    // Debug logs solo en desarrollo
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

    PurchasesConfiguration configuration;
    if (!kIsWeb && Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
    }

    // Verificar estado inicial
    await updatePurchaseStatus();

    // Escuchar cambios en tiempo real (ej: si se activa la suscripción)
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateStatusFromInfo(customerInfo);
    });
  }

  Future<void> updatePurchaseStatus() async {
    if (kIsWeb) return;
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateStatusFromInfo(customerInfo);
    } catch (e) {
      debugPrint("Error al obtener CustomerInfo: $e");
    }
  }

  void _updateStatusFromInfo(CustomerInfo info) {
    // Verifica si el entitlement específico está activo
    bool hasPremium = info.entitlements.active.containsKey(_entitlementId);
    isPremium.value = hasPremium;
    debugPrint("Estado Premium actualizado: $hasPremium");
  }

  /// Obtiene las ofertas configuradas en RevenueCat
  Future<Offering?> getCurrentOffering() async {
    if (kIsWeb) return null;
    try {
      Offerings offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      debugPrint("Error al obtener Offerings: $e");
      return null;
    }
  }

  /// Realiza la compra de un paquete
  Future<bool> purchasePackage(Package package) async {
    if (kIsWeb) return false;
    try {
      PurchaseResult result = await Purchases.purchasePackage(package);
      _updateStatusFromInfo(result.customerInfo);
      return isPremium.value;
    } catch (e) {
      debugPrint("Error en la compra: $e");
      return false;
    }
  }

  /// Restaura compras previas
  Future<void> restorePurchases() async {
    if (kIsWeb) return;
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateStatusFromInfo(customerInfo);
    } catch (e) {
      debugPrint("Error al restaurar: $e");
    }
  }
}
