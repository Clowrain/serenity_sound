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
    
    final box = Hive.box(_boxName);
    if (box.get(_keySounds) == null) {
      await _seedData();
    }
  }

  Future<void> _seedData() async {
    final String response = await rootBundle.loadString('assets/config/sounds.json');
    final List<dynamic> data = json.decode(response);
    final box = Hive.box(_boxName);
    await box.put(_keySounds, data);
    
    // 初始化一些默认场景
    final defaultScenes = [
      {
        'id': 'scene_focus',
        'name': '专注',
        'soundConfig': {'rain_01': 0.6, 'forest_01': 0.3}
      },
      {
        'id': 'scene_sleep',
        'name': '入眠',
        'soundConfig': {'ocean_01': 0.4, 'wind_01': 0.2}
      }
    ];
    await box.put(_keyScenes, defaultScenes);
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
