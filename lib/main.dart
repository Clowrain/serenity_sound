import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/sound_provider.dart';
import 'services/audio_handler.dart';
import 'services/storage_service.dart';
import 'services/asset_cache_service.dart';
import 'screens/home_screen.dart';
import 'theme/serenity_theme.dart';

Future<void> main() async {
  // 全局错误处理
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 捕获 Flutter 框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };

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
  }, (error, stack) {
    // 忽略 just_audio 的加载中断异常
    if (error is PlatformException && error.code == 'abort') {
      return;
    }
    // 其他错误打印日志
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stack');
  });
}

class SerenityApp extends StatelessWidget {
  const SerenityApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use CupertinoApp for iOS-native feel, with Material localizations for compatibility
    return CupertinoApp(
      title: 'Serenity Sound',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: SerenityTheme.accent,
        scaffoldBackgroundColor: SerenityTheme.background,
        textTheme: const CupertinoTextThemeData(
          primaryColor: SerenityTheme.primaryText,
        ),
      ),
      // Add localizations for Material widgets compatibility
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      // Wrap with Material for widgets that need MaterialLocalizations
      home: Material(
        color: SerenityTheme.background,
        child: const HomeScreen(),
      ),
    );
  }
}