abstract class CacheRepository {

  Future<(T, DateTime)?> read<T>({
    required String key
  });

  Future<bool> write<T>({
    required String key,
    required T value,
    required DateTime expirationDate
  });

  Future<List<(String key, T value, DateTime expirationDate)>> readAll<T>();

  Future<bool> writeAll<T>({
    required List<(String key, T value, DateTime expirationDate)> values
  });

  Future<(T, DateTime)?> remove<T>({
    required String key
  });

  Future<bool> clearAll<T>();
}