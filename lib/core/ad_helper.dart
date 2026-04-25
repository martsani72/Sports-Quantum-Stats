import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;

class AdHelper {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoaded = false;

  // ID de prueba de Google para Intersticiales
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Carga el anuncio en segundo plano para que esté listo cuando se necesite
  static void cargarInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;

          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdLoaded = false;
              // Recargar otro para la próxima vez
              cargarInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdLoaded = false;
              cargarInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          print('Error al cargar InterstitialAd: ${err.message}');
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  /// Muestra el anuncio si está cargado, y ejecuta una acción (onAdClosed) cuando el usuario lo cierra
  static void mostrarInterstitialAd({required Function() onAdClosed}) {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      // Reemplazamos el callback de cierre temporalmente para ejecutar la acción de navegación de la app
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialAdLoaded = false;
          onAdClosed(); // Navegamos a la siguiente pantalla
          cargarInterstitialAd(); // Cargamos el próximo
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isInterstitialAdLoaded = false;
          onAdClosed(); // Si falla, que no bloquee al usuario
          cargarInterstitialAd();
        },
      );
      _interstitialAd!.show();
    } else {
      // Si por alguna razón no se cargó o no hay internet, continuamos el flujo normal
      onAdClosed();
    }
  }
}
