import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class SoundEffect extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String svgPath;

  @HiveField(3)
  final String audioPath;

  @HiveField(4)
  final String themeColor;

  @HiveField(5)
  final double volume; // 新增音量字段

  SoundEffect({
    required this.id,
    required this.name,
    required this.svgPath,
    required this.audioPath,
    required this.themeColor,
    this.volume = 0.5, // 默认音量 50%
  });

  SoundEffect copyWith({double? volume}) {
    return SoundEffect(
      id: id,
      name: name,
      svgPath: svgPath,
      audioPath: audioPath,
      themeColor: themeColor,
      volume: volume ?? this.volume,
    );
  }

  factory SoundEffect.fromJson(Map<String, dynamic> json) {
    return SoundEffect(
      id: json['id'],
      name: json['name'],
      svgPath: json['svgPath'],
      audioPath: json['audioPath'],
      themeColor: json['themeColor'],
      volume: json['volume']?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'svgPath': svgPath,
      'audioPath': audioPath,
      'themeColor': themeColor,
      'volume': volume,
    };
  }
}

class SoundScene {
  final String id;
  final String name;
  final Map<String, double> soundConfig; // SoundID -> Volume

  SoundScene({
    required this.id,
    required this.name,
    required this.soundConfig,
  });

  factory SoundScene.fromJson(Map<String, dynamic> json) {
    return SoundScene(
      id: json['id'],
      name: json['name'],
      soundConfig: Map<String, double>.from(json['soundConfig']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'soundConfig': soundConfig,
    };
  }
}