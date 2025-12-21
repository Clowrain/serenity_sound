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
    
    // 首先初始化默认场景（如果不存在）
    if (box.get(_keyScenes) == null) {
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
    
    final List<dynamic> storedData = box.get(_keySounds, defaultValue: []);
    
    // 如果是首次运行（没有存储数据），直接使用 JSON 顺序
    if (storedData.isEmpty) {
      await box.put(_keySounds, jsonList);
      return;
    }
    
    // 分离本地和远程音效
    final List<dynamic> storedRemoteSounds = storedData.where((item) => item['isRemote'] == true).toList();
    final List<dynamic> storedLocalSounds = storedData.where((item) => item['isRemote'] != true).toList();
    
    // 创建 JSON 配置的 Map（用于获取最新配置，如 svgPath, audioPath 等）
    final Map<String, dynamic> jsonConfigMap = {
      for (var config in jsonList) config['id']: config
    };
    
    // 按照用户保存的顺序更新本地音效（保留排序和音量，更新其他配置）
    final List<dynamic> syncedLocalList = [];
    final Set<String> processedIds = {};
    
    // 1. 按用户保存的顺序处理已存在的音效
    for (final storedItem in storedLocalSounds) {
      final id = storedItem['id'];
      if (jsonConfigMap.containsKey(id)) {
        // 更新配置但保留音量
        syncedLocalList.add({
          ...jsonConfigMap[id],
          'volume': storedItem['volume'] ?? jsonConfigMap[id]['volume'],
        });
        processedIds.add(id);
      }
      // 如果 JSON 中不存在该音效，跳过（被删除的音效）
    }
    
    // 2. 添加 JSON 中新增的音效（追加到本地音效末尾）
    for (final config in jsonList) {
      if (!processedIds.contains(config['id'])) {
        syncedLocalList.add(config);
      }
    }

    // 合并：本地音效 + 远程音效（远程音效追加在后面）
    final List<dynamic> newList = [...syncedLocalList, ...storedRemoteSounds];

    await box.put(_keySounds, newList);
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
