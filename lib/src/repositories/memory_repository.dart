import 'dart:core';

import 'cache_repository.dart';

class MemoryRepository extends CacheRepository {
  final Map<String, (dynamic, DateTime)> cache = {};

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

  @override
  Future<(T, DateTime)?> remove<T>({required String key}) async {
    final data = cache.remove(key);
    if (data is (T, DateTime)) return data;
    return null;
  }

  @override
  Future<bool> write<T>(
      {required String key,
      required T value,
      required DateTime expirationDate}) async {
    if (DateTime.now().isAfter(expirationDate)) return false;
    cache[key] = (value, expirationDate);
    return true;
  }

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

  @override
  Future<bool> clearAll<T>() {
    cache.clear();
    return Future.value(true);
  }
}
