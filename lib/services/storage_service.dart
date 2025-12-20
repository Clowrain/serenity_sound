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
    final Map<String, dynamic> storedMap = {
      for (var item in storedData) item['id']: item
    };

    // 以 JSON 配置为准，但保留已存储的音量
    final newList = jsonList.map((config) {
      final id = config['id'];
      if (storedMap.containsKey(id)) {
        return {
          ...config,
          'volume': storedMap[id]['volume'] ?? config['volume'],
        };
      }
      return config;
    }).toList();

    // 如果存储中的顺序存在，尽量维持顺序
    // 这里简单处理：如果长度不一致，说明有新增，直接用新的（或者您可以做更复杂的 merge）
    if (storedData.length == newList.length) {
       // 维持原有顺序
       final orderedList = storedData.map((s) {
         final match = newList.firstWhere((n) => n['id'] == s['id'], orElse: () => null);
         return match ?? s;
       }).toList();
       await box.put(_keySounds, orderedList);
    } else {
       await box.put(_keySounds, newList);
    }

    if (box.get(_keyScenes) == null) {
      final defaultScenes = [
        {
          'id': 'scene_default',
          'name': '默认',
          'soundConfig': <String, double>{},
          'soundOrder': <String>[],
          'color': '#FFFFFF'
        },
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
}
