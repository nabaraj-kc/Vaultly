import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vault_file.dart';

class CacheService {
  static const String _cacheFileName = "vaultly_cache.json";
  static List<VaultFile> _inMemoryCache = [];
  
  // Transient session-level store for PDF binary bytes on Web
  static final Map<String, Uint8List> _sessionBytes = {};

  static Future<File> get _cacheFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_cacheFileName');
  }

  /// Loads all cached documents from disk or session-memory.
  static Future<List<VaultFile>> loadCachedFiles() async {
    if (kIsWeb) {
      // Re-populate transient file bytes on web from session memory
      for (var file in _inMemoryCache) {
        if (file.fileBytes == null && _sessionBytes.containsKey(file.id)) {
          file.fileBytes = _sessionBytes[file.id];
        }
      }
      return _inMemoryCache;
    }
    
    if (_inMemoryCache.isNotEmpty) {
      return _inMemoryCache;
    }
    
    try {
      final file = await _cacheFile;
      if (!await file.exists()) {
        return [];
      }
      
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      _inMemoryCache = jsonList.map((m) => VaultFile.fromMap(m)).toList();
      
      // Sort: Newest first
      _inMemoryCache.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return _inMemoryCache;
    } catch (e) {
      return [];
    }
  }

  /// Appends or updates a document metadata entry in the cache.
  static Future<void> saveFile(VaultFile vaultFile) async {
    // Retain binary bytes in session map
    if (vaultFile.fileBytes != null) {
      _sessionBytes[vaultFile.id] = vaultFile.fileBytes!;
    } else if (_sessionBytes.containsKey(vaultFile.id)) {
      vaultFile.fileBytes = _sessionBytes[vaultFile.id];
    }

    final index = _inMemoryCache.indexWhere((f) => f.id == vaultFile.id);
    if (index >= 0) {
      _inMemoryCache[index] = vaultFile;
    } else {
      _inMemoryCache.insert(0, vaultFile);
    }

    if (!kIsWeb) {
      await _persist();
    }
  }

  /// Deletes a document cache entry from disk.
  static Future<void> deleteFile(String id) async {
    _inMemoryCache.removeWhere((f) => f.id == id);
    _sessionBytes.remove(id);
    if (!kIsWeb) {
      await _persist();
    }
  }

  static Future<void> _persist() async {
    try {
      final file = await _cacheFile;
      final jsonString = jsonEncode(_inMemoryCache.map((f) => f.toMap()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      // Silent error logging
    }
  }

  /// Clean all local caches.
  static Future<void> clearCache() async {
    _inMemoryCache.clear();
    _sessionBytes.clear();
    if (!kIsWeb) {
      final file = await _cacheFile;
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
