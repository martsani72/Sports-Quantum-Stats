import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:mi_nueva_app/core/purchases_service.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({Key? key}) : super(key: key);

  @override
  _AdBannerWidgetState createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  String get _adUnitId {
    if (kIsWeb) return "";
    return Platform.isAndroid
      ? 'ca-app-pub-5212228288336430/2691201960' // ID Real Banner
      : 'ca-app-pub-3940256099942544/2934735716';
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Error al cargar el banner: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PurchasesService().isPremium,
      builder: (context, isPremium, child) {
        if (isPremium) return const SizedBox.shrink();
        if (_isAdLoaded && _bannerAd != null) {
          return SafeArea(
            child: SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
