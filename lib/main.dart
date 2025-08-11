import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart'; // Yandex Ads

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter + Yandex Ads',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Show Yandex Interstitial'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Yandex interstitial pieces
  late final Future<InterstitialAdLoader> _adLoader;
  InterstitialAd? _interstitial;

  @override
  void initState() {
    super.initState();
    MobileAds.initialize(); // Initialize SDK
    _adLoader = _createInterstitialAdLoader();
    _loadInterstitial();
  }

  Future<InterstitialAdLoader> _createInterstitialAdLoader() {
    return InterstitialAdLoader.create(
      onAdLoaded: (InterstitialAd ad) {
        _interstitial = ad;
      },
      onAdFailedToLoad: (AdRequestError error) {
        debugPrint('Yandex interstitial failed to load: $error');
      },
    );
  }

  Future<void> _loadInterstitial() async {
    final loader = await _adLoader;
    await loader.loadAd(
      adRequestConfiguration: const AdRequestConfiguration(adUnitId: 'demo-interstitial-yandex'),
    );
  }

  Future<void> _showInterstitial() async {
    if (_interstitial == null) {
      await _loadInterstitial();
      return;
    }

    _interstitial!.setAdEventListener(
      eventListener: InterstitialAdEventListener(
        onAdShown: () => debugPrint('Yandex interstitial shown'),
        onAdFailedToShow: (error) {
          debugPrint('Failed to show: $error');
          _interstitial?.destroy();
          _interstitial = null;
          _loadInterstitial();
        },
        onAdDismissed: () {
          _interstitial?.destroy();
          _interstitial = null;
          _loadInterstitial();
        },
      ),
    );

    await _interstitial!.show();
    await _interstitial!.waitForDismiss();
  }

  @override
  void dispose() {
    _interstitial?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _showInterstitial,
          child: const Text(
            'Show Ad',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
