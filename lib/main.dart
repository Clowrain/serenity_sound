import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/sound_provider.dart';
import 'services/audio_handler.dart';
import 'services/storage_service.dart';
import 'services/asset_cache_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final assetCacheService = AssetCacheService();
  await assetCacheService.init();

  final handler = await AudioService.init(
    builder: () => SerenityAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.serenity.sound.channel.audio',
      androidNotificationChannelName: 'Serenity Sound Playback',
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        audioHandlerProvider.overrideWithValue(handler),
        assetCacheServiceProvider.overrideWithValue(assetCacheService),
      ],
      child: const SerenityApp(),
    ),
  );
}

class SerenityApp extends StatelessWidget {
  const SerenityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serenity Sound',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}