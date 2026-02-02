import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A scalable caching service for storing JSON-serializable data locally.
/// Uses SharedPreferences for simple key-value storage with TTL support.
/// 
/// Designed for:
/// - Feed results caching to reduce Firestore reads
/// - User preferences caching
/// - API response caching
/// - Offline data support
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  
  /// Cache key prefixes for organization
  static const String _feedPrefix = 'feed_cache_';
  static const String _userPrefix = 'user_cache_';
  static const String _apiPrefix = 'api_cache_';
  static const String _metaPrefix = 'meta_';
  
  /// Default cache durations
  static const Duration feedCacheDuration = Duration(minutes: 5);
  static const Duration userCacheDuration = Duration(hours: 1);
  static const Duration apiCacheDuration = Duration(minutes: 15);

  /// Initialize the cache service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance (auto-initializes if needed)
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Store a JSON-serializable object with optional TTL
  Future<bool> set<T>({
    required String key,
    required T value,
    required Map<String, dynamic> Function(T) toJson,
    Duration? ttl,
  }) async {
    try {
      final prefs = await _preferences;
      final json = jsonEncode(toJson(value));
      await prefs.setString(key, json);
      
      // Store expiration time if TTL is set
      if (ttl != null) {
        final expiresAt = DateTime.now().add(ttl).millisecondsSinceEpoch;
        await prefs.setInt('${_metaPrefix}exp_$key', expiresAt);
      }
      
      if (kDebugMode) {
        debugPrint('[CacheService] Stored: $key (${json.length} bytes)');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CacheService] Error storing $key: $e');
      }
      return false;
    }
  }

  /// Retrieve a cached object, returns null if expired or not found
  Future<T?> get<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final prefs = await _preferences;
      
      // Check expiration
      final expiresAt = prefs.getInt('${_metaPrefix}exp_$key');
      if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
        if (kDebugMode) {
          debugPrint('[CacheService] Expired: $key');
        }
        await remove(key);
        return null;
      }
      
      final json = prefs.getString(key);
      if (json == null) return null;
      
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      if (kDebugMode) {
        debugPrint('[CacheService] Retrieved: $key');
      }
      return fromJson(decoded);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CacheService] Error retrieving $key: $e');
      }
      return null;
    }
  }

  /// Store a list of JSON-serializable objects
  Future<bool> setList<T>({
    required String key,
    required List<T> value,
    required Map<String, dynamic> Function(T) toJson,
    Duration? ttl,
  }) async {
    try {
      final prefs = await _preferences;
      final jsonList = value.map((item) => toJson(item)).toList();
      final json = jsonEncode(jsonList);
      await prefs.setString(key, json);
      
      if (ttl != null) {
        final expiresAt = DateTime.now().add(ttl).millisecondsSinceEpoch;
        await prefs.setInt('${_metaPrefix}exp_$key', expiresAt);
      }
      
      if (kDebugMode) {
        debugPrint('[CacheService] Stored list: $key (${value.length} items, ${json.length} bytes)');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CacheService] Error storing list $key: $e');
      }
      return false;
    }
  }

  /// Retrieve a cached list
  Future<List<T>?> getList<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final prefs = await _preferences;
      
      // Check expiration
      final expiresAt = prefs.getInt('${_metaPrefix}exp_$key');
      if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
        if (kDebugMode) {
          debugPrint('[CacheService] Expired list: $key');
        }
        await remove(key);
        return null;
      }
      
      final json = prefs.getString(key);
      if (json == null) return null;
      
      final decoded = jsonDecode(json) as List<dynamic>;
      final result = decoded
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
      
      if (kDebugMode) {
        debugPrint('[CacheService] Retrieved list: $key (${result.length} items)');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CacheService] Error retrieving list $key: $e');
      }
      return null;
    }
  }

  /// Store a simple string
  Future<bool> setString(String key, String value, {Duration? ttl}) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(key, value);
      
      if (ttl != null) {
        final expiresAt = DateTime.now().add(ttl).millisecondsSinceEpoch;
        await prefs.setInt('${_metaPrefix}exp_$key', expiresAt);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get a simple string
  Future<String?> getString(String key) async {
    try {
      final prefs = await _preferences;
      
      // Check expiration
      final expiresAt = prefs.getInt('${_metaPrefix}exp_$key');
      if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await remove(key);
        return null;
      }
      
      return prefs.getString(key);
    } catch (e) {
      return null;
    }
  }

  /// Remove a cached item
  Future<bool> remove(String key) async {
    try {
      final prefs = await _preferences;
      await prefs.remove(key);
      await prefs.remove('${_metaPrefix}exp_$key');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all cached items with a specific prefix
  Future<void> clearWithPrefix(String prefix) async {
    try {
      final prefs = await _preferences;
      final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
        await prefs.remove('${_metaPrefix}exp_$key');
      }
      if (kDebugMode) {
        debugPrint('[CacheService] Cleared ${keys.length} items with prefix: $prefix');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CacheService] Error clearing prefix $prefix: $e');
      }
    }
  }

  /// Clear all feed caches (call after posting a new sighting)
  Future<void> clearFeedCache() async {
    await clearWithPrefix(_feedPrefix);
  }

  /// Clear all user-related caches (call after sign-out)
  Future<void> clearUserCache() async {
    await clearWithPrefix(_userPrefix);
  }

  /// Clear all API caches
  Future<void> clearApiCache() async {
    await clearWithPrefix(_apiPrefix);
  }

  /// Clear all caches
  Future<void> clearAll() async {
    try {
      final prefs = await _preferences;
      await prefs.clear();
      if (kDebugMode) {
        debugPrint('[CacheService] Cleared all caches');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CacheService] Error clearing all: $e');
      }
    }
  }

  /// Get cache statistics for debugging
  Future<Map<String, dynamic>> getStats() async {
    try {
      final prefs = await _preferences;
      final keys = prefs.getKeys();
      
      int feedCount = 0;
      int userCount = 0;
      int apiCount = 0;
      int otherCount = 0;
      
      for (final key in keys) {
        if (key.startsWith(_feedPrefix)) {
          feedCount++;
        } else if (key.startsWith(_userPrefix)) {
          userCount++;
        } else if (key.startsWith(_apiPrefix)) {
          apiCount++;
        } else if (!key.startsWith(_metaPrefix)) {
          otherCount++;
        }
      }
      
      return {
        'total': keys.length,
        'feed': feedCount,
        'user': userCount,
        'api': apiCount,
        'other': otherCount,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Convenience methods for common cache keys
  
  /// Cache key for feed results with filters
  static String feedKey(String filterHash) => '$_feedPrefix$filterHash';
  
  /// Cache key for user profile
  static String userProfileKey(String uid) => '${_userPrefix}profile_$uid';
  
  /// Cache key for saved places
  static String savedPlacesKey(String uid) => '${_userPrefix}places_$uid';
  
  /// Cache key for API responses
  static String apiKey(String endpoint) => '$_apiPrefix$endpoint';
}
