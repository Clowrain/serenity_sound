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
  final double volume;

  @HiveField(6)
  final bool isRemote; // 是否为远程音效

  @HiveField(7)
  final String? sourceId; // 关联的远程来源 ID

  SoundEffect({
    required this.id,
    required this.name,
    required this.svgPath,
    required this.audioPath,
    required this.themeColor,
    this.volume = 0.5,
    this.isRemote = false,
    this.sourceId,
  });

  SoundEffect copyWith({
    double? volume,
    bool? isRemote,
    String? sourceId,
  }) {
    return SoundEffect(
      id: id,
      name: name,
      svgPath: svgPath,
      audioPath: audioPath,
      themeColor: themeColor,
      volume: volume ?? this.volume,
      isRemote: isRemote ?? this.isRemote,
      sourceId: sourceId ?? this.sourceId,
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
      isRemote: json['isRemote'] ?? false,
      sourceId: json['sourceId'],
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
      'isRemote': isRemote,
      'sourceId': sourceId,
    };
  }
}

/// 远程音效来源
class RemoteSource {
  final String id;
  final String url;
  final String name;
  final List<String> soundIds; // 该来源包含的音效 ID
  final DateTime addedAt;

  RemoteSource({
    required this.id,
    required this.url,
    required this.name,
    required this.soundIds,
    required this.addedAt,
  });

  factory RemoteSource.fromJson(Map<String, dynamic> json) {
    return RemoteSource(
      id: json['id'],
      url: json['url'],
      name: json['name'] ?? '未命名',
      soundIds: List<String>.from(json['soundIds'] ?? []),
      addedAt: json['addedAt'] != null 
          ? DateTime.parse(json['addedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'name': name,
      'soundIds': soundIds,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}

class SoundScene {
  final String id;
  final String name;
  final Map<String, double> soundConfig; // 激活的 SoundID -> Volume
  final List<String> soundOrder; // 所有音效的排序 (保存时的顺序)
  final String color; // 场景主题色 (hex)

  SoundScene({
    required this.id,
    required this.name,
    required this.soundConfig,
    this.soundOrder = const [],
    this.color = '#38f9d7',
  });

  SoundScene copyWith({String? name, String? color}) {
    return SoundScene(
      id: id,
      name: name ?? this.name,
      soundConfig: soundConfig,
      soundOrder: soundOrder,
      color: color ?? this.color,
    );
  }

  factory SoundScene.fromJson(Map<String, dynamic> json) {
    return SoundScene(
      id: json['id'],
      name: json['name'],
      soundConfig: Map<String, double>.from(json['soundConfig']),
      soundOrder: json['soundOrder'] != null 
          ? List<String>.from(json['soundOrder']) 
          : [],
      color: json['color'] ?? '#38f9d7',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'soundConfig': soundConfig,
      'soundOrder': soundOrder,
      'color': color,
    };
  }
}