import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 资源缓存状态
enum CacheStatus {
  notCached,
  downloading,
  cached,
  error,
}

/// 资源缓存服务
class AssetCacheService {
  final Dio _dio = Dio();
  String? _cacheDir;

  /// 初始化缓存目录
  Future<void> init() async {
    final dir = await getApplicationCacheDirectory();
    _cacheDir = '${dir.path}/remote_assets';
    await Directory(_cacheDir!).create(recursive: true);
  }

  String get cacheDir => _cacheDir ?? '';

  /// 获取音频文件的本地路径
  String getAudioCachePath(String id) {
    return '$_cacheDir/audio/$id.mp3';
  }

  /// 获取 SVG 文件的本地路径
  String getSvgCachePath(String id) {
    return '$_cacheDir/svg/$id.svg';
  }

  /// 检查资源是否已缓存
  bool isAudioCached(String id) {
    return File(getAudioCachePath(id)).existsSync();
  }

  bool isSvgCached(String id) {
    return File(getSvgCachePath(id)).existsSync();
  }

  /// 下载音频文件
  Future<String> downloadAudio(
    String url,
    String id, {
    void Function(double progress)? onProgress,
  }) async {
    final savePath = getAudioCachePath(id);
    await Directory('$_cacheDir/audio').create(recursive: true);
    
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );
    
    return savePath;
  }

  /// 下载 SVG 文件
  Future<String> downloadSvg(
    String url,
    String id, {
    void Function(double progress)? onProgress,
  }) async {
    final savePath = getSvgCachePath(id);
    await Directory('$_cacheDir/svg').create(recursive: true);
    
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );
    
    return savePath;
  }

  /// 获取或下载音频文件（返回本地路径）
  Future<String> getOrDownloadAudio(
    String url,
    String id, {
    void Function(double progress)? onProgress,
  }) async {
    if (isAudioCached(id)) {
      return getAudioCachePath(id);
    }
    return downloadAudio(url, id, onProgress: onProgress);
  }

  /// 获取或下载 SVG 文件（返回本地路径）
  Future<String> getOrDownloadSvg(
    String url,
    String id, {
    void Function(double progress)? onProgress,
  }) async {
    if (isSvgCached(id)) {
      return getSvgCachePath(id);
    }
    return downloadSvg(url, id, onProgress: onProgress);
  }

  /// 删除指定来源的所有缓存
  Future<void> deleteSourceCache(List<String> soundIds) async {
    for (final id in soundIds) {
      final audioFile = File(getAudioCachePath(id));
      final svgFile = File(getSvgCachePath(id));
      
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
      if (await svgFile.exists()) {
        await svgFile.delete();
      }
    }
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    final dir = Directory(_cacheDir!);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }

  /// 获取缓存大小（字节）
  Future<int> getCacheSize() async {
    final dir = Directory(_cacheDir!);
    if (!await dir.exists()) return 0;
    
    int size = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  /// 格式化缓存大小
  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

/// 全局 AssetCacheService provider
final assetCacheServiceProvider = Provider<AssetCacheService>((ref) {
  return AssetCacheService();
});
