/// Defines a generic interface for lightweight key-value caching operations.
///
/// Implementations may store cached values in memory, secure storage, shared
/// preferences, local databases, or remote cache layers depending on the use case.
/// Each cached item includes an expiration timestamp to support time-based invalidation.
abstract class CacheRepository {
  /// Reads a cached value by [key].
  ///
  /// Returns a tuple `(value, expirationDate)` if the item exists,
  /// or `null` if it is not found.
  ///
  /// Implementations may automatically remove expired entries.
  Future<(T, DateTime)?> read<T>({required String key});

  /// Writes a value into the cache with the specified [expirationDate].
  ///
  /// Returns `true` if the value was successfully written.
  Future<bool> write<T>(
      {required String key,
      required T value,
      required DateTime expirationDate});

  /// Reads all cached entries of type [T].
  ///
  /// Returns a list of `(key, value, expirationDate)` tuples.
  Future<List<(String key, T value, DateTime expirationDate)>> readAll<T>();

  /// Writes multiple key-value pairs in a batch operation.
  ///
  /// Returns `true` if the bulk write succeeds.
  Future<bool> writeAll<T>(
      {required List<(String key, T value, DateTime expirationDate)> values});

  /// Removes an entry associated with [key] from the cache.
  ///
  /// Returns the removed `(value, expirationDate)` tuple if present, otherwise `null`.
  Future<(T, DateTime)?> remove<T>({required String key});

  /// Removes all cached entries of type [T].
  ///
  /// Returns `true` if the cache was successfully cleared.
  Future<bool> clearAll<T>();
}
