import 'dart:core';

import 'cache_repository.dart';

/// In-memory implementation of [CacheRepository].
///
/// Stores cached items inside a simple in-process [Map], making this repository
/// suitable for high-performance and short-lived caching scenarios such as
/// UI state, session tokens, and temporary computation results.
///
/// Expired entries are automatically removed upon access.
class MemoryRepository extends CacheRepository {
  /// Internal storage container mapping string keys to tuple `(value, expirationDate)`.
  ///
  /// Values are kept until manually cleared or automatically removed when expired.
  final Map<String, (dynamic, DateTime)> cache = {};

  /// If the item exists and has not expired, returns the cached tuple.
  /// Otherwise, removes the stale entry and returns `null`.
  @override
  Future<(T, DateTime)?> read<T>({required String key}) {
    final data = cache[key];
    if (data != null && DateTime.now().isBefore(data.$2)) {
      return Future.value(data as (T, DateTime));
    } else {
      cache.remove(key); // Remove expired data
      return Future.value(null);
    }
  }

  /// Automatically cleans expired entries while collecting those matching type [T].
  @override
  Future<List<(String key, T value, DateTime expirationDate)>>
      readAll<T>() async {
    List<(String key, T value, DateTime expirationDate)> values = [];

    cache.removeWhere((key, value) {
      if (DateTime.now().isAfter(value.$2)) return true;
      if (value.$1 is T) {
        values.add((key, value.$1, value.$2));
      }
      return false;
    });

    return values;
  }

  /// Removes a cached item and returns it if it matches type [T], otherwise `null`.
  @override
  Future<(T, DateTime)?> remove<T>({required String key}) async {
    final data = cache.remove(key);
    if (data is (T, DateTime)) return data;
    return null;
  }

  /// Skips storage if the expiration date is already in the past.
  @override
  Future<bool> write<T>(
      {required String key,
      required T value,
      required DateTime expirationDate}) async {
    if (DateTime.now().isAfter(expirationDate)) return false;
    cache[key] = (value, expirationDate);
    return true;
  }

  /// Writes multiple entries and returns `true` only if all writes succeed.
  @override
  Future<bool> writeAll<T>(
      {required List<(String key, T value, DateTime expirationDate)>
          values}) async {
    bool written = true;
    for (var value in values) {
      final wasWritten =
          await write(key: value.$1, value: value.$2, expirationDate: value.$3);
      written = written && wasWritten;
    }
    return written;
  }

  /// Clears the entire in-memory cache, ignoring type filtering.
  @override
  Future<bool> clearAll<T>() {
    cache.clear();
    return Future.value(true);
  }
}
