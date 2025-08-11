import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YandexRewardApp', // app name
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Rewarded Ad Demo'),
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
  // Loader + current rewarded ad
  late final Future<RewardedAdLoader> _adLoader;
  RewardedAd? _rewarded;
  bool _isLoading = false; // UX: show feedback when fetching

  // Your real rewarded ad unit
  static const String _rewardedUnitId = 'R-M-16666594-1';

  @override
  void initState() {
    super.initState();
    // Initialize SDK early
    MobileAds.initialize();
    _adLoader = _createRewardedLoader();
    _loadRewarded();
  }

  Future<RewardedAdLoader> _createRewardedLoader() {
    return RewardedAdLoader.create(
      onAdLoaded: (RewardedAd ad) {
        _rewarded = ad;
      },
      onAdFailedToLoad: (AdRequestError error) {
        debugPrint('Rewarded failed to load: $error');
      },
    );
  }

  Future<void> _loadRewarded() async {
    final loader = await _adLoader;
    await loader.loadAd(
      adRequestConfiguration: const AdRequestConfiguration(
        adUnitId: _rewardedUnitId, // ✅ real unit
      ),
    );
  }

  Future<void> _showRewarded() async {
    // If not ready, try loading once and inform the user
    if (_rewarded == null) {
      setState(() => _isLoading = true);
      await _loadRewarded();
      setState(() => _isLoading = false);

      if (_rewarded == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ad not ready yet. Please try again.')),
          );
        }
        return;
      }
    }

    // Handle lifecycle + reward
    _rewarded!.setAdEventListener(
      eventListener: RewardedAdEventListener(
        onAdShown: () => debugPrint('Rewarded shown'),
        onAdFailedToShow: (error) {
          debugPrint('Rewarded failed to show: $error');
          _rewarded?.destroy();
          _rewarded = null;
          _loadRewarded(); // prepare next
        },
        onAdDismissed: () {
          _rewarded?.destroy();
          _rewarded = null;
          _loadRewarded(); // preload next after closing
        },
        onAdImpression: (impressionData) {
          // Some versions don’t expose .rawData; toString() is safe
          debugPrint('Impression: $impressionData');
        },
        onAdClicked: () => debugPrint('Rewarded clicked'),
        onRewarded: (Reward reward) {
          // ✅ Grant your in-app reward here
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Reward: ${reward.amount} ${reward.type}')),
            );
          }
        },
      ),
    );

    await _rewarded!.show();

    // Optional: wait for dismissal and read the returned Reward as well
    final reward = await _rewarded!.waitForDismiss();
    if (reward != null && mounted) {
      debugPrint('waitForDismiss -> got ${reward.amount} ${reward.type}');
    }
  }

  @override
  void dispose() {
    _rewarded?.destroy();
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
          onPressed: _isLoading ? null : _showRewarded,
          child: Text(
            _isLoading ? 'Loading…' : 'Show Ad',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
