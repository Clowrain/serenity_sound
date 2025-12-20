import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sound_effect.dart';

class StorageService {
  static const String _boxName = 'settings';
  static const String _keySounds = 'sounds_list';
  static const String _keyScenes = 'scenes_list';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    
    // 每次启动都尝试同步配置
    await _syncSounds();
  }

  Future<void> _syncSounds() async {
    final box = Hive.box(_boxName);
    final String jsonString = await rootBundle.loadString('assets/config/sounds.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    
    final List<dynamic> storedData = box.get(_keySounds, defaultValue: []);
    
    // 分离本地和远程音效
    final List<dynamic> storedRemoteSounds = storedData.where((item) => item['isRemote'] == true).toList();
    final Map<String, dynamic> storedLocalMap = {
      for (var item in storedData.where((item) => item['isRemote'] != true)) 
        item['id']: item
    };

    // 以 JSON 配置为准同步本地音效，但保留已存储的音量
    final syncedLocalList = jsonList.map((config) {
      final id = config['id'];
      if (storedLocalMap.containsKey(id)) {
        return {
          ...config,
          'volume': storedLocalMap[id]['volume'] ?? config['volume'],
        };
      }
      return config;
    }).toList();

    // 合并：本地音效 + 远程音效（远程音效追加在后面）
    final List<dynamic> newList = [...syncedLocalList, ...storedRemoteSounds];

    await box.put(_keySounds, newList);

    if (box.get(_keyScenes) == null) {
      // 只保留示例场景，不再有"默认"场景
      final defaultScenes = [
        {
          'id': 'scene_nature',
          'name': '大自然',
          'soundConfig': {'nature_campfire': 0.6, 'nature_river': 0.4},
          'soundOrder': <String>[],
          'color': '#38f9d7'
        }
      ];
      await box.put(_keyScenes, defaultScenes);
    }
  }

  List<SoundEffect> getSounds() {
    final box = Hive.box(_boxName);
    final List<dynamic> data = box.get(_keySounds, defaultValue: []);
    return data.map((e) => SoundEffect.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveSounds(List<SoundEffect> sounds) async {
    final box = Hive.box(_boxName);
    final List<Map<String, dynamic>> data = sounds.map((e) => e.toJson()).toList();
    await box.put(_keySounds, data);
  }

  List<SoundScene> getScenes() {
    final box = Hive.box(_boxName);
    final List<dynamic> data = box.get(_keyScenes, defaultValue: []);
    return data.map((e) => SoundScene.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveScenes(List<SoundScene> scenes) async {
    final box = Hive.box(_boxName);
    final List<Map<String, dynamic>> data = scenes.map((e) => e.toJson()).toList();
    await box.put(_keyScenes, data);
  }

  // --- 远程来源存储 ---
  static const String _keyRemoteSources = 'remote_sources';

  List<RemoteSource> getRemoteSources() {
    final box = Hive.box(_boxName);
    final List<dynamic> data = box.get(_keyRemoteSources, defaultValue: []);
    return data.map((e) => RemoteSource.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveRemoteSources(List<RemoteSource> sources) async {
    final box = Hive.box(_boxName);
    final List<Map<String, dynamic>> data = sources.map((e) => e.toJson()).toList();
    await box.put(_keyRemoteSources, data);
  }
}
