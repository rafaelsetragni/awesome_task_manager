import 'package:awesome_task_manager/src/repositories/memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryRepository', () {
    late MemoryRepository cache;
    setUp(() {
      cache = MemoryRepository();
    });

    group('write operations', () {
      test('write a non-expired value', () async {
        String key = 'testKey';
        String value = 'testValue';
        DateTime expirationDate = DateTime.now().add(const Duration(seconds: 10));

        bool result = await cache.write<String>(
          key: key,
          value: value,
          expirationDate: expirationDate,
        );

        expect(result, isTrue);
        expect(cache.cache.containsKey(key), isTrue);
        expect(cache.cache[key], (value, expirationDate));
      });

      test('write an expired value', () async {
        String key = 'expiredKey';
        String value = 'testValue';

        bool result1 = await cache.write<String>(
          key: key,
          value: value,
          expirationDate: DateTime.now(),
        );

        expect(result1, isFalse);
        expect(cache.cache.containsKey(key), isFalse);

        bool result2 = await cache.write<String>(
          key: key,
          value: value,
          expirationDate: DateTime
              .now()
              .subtract(const Duration(seconds: 10)),
        );

        expect(result2, isFalse);
        expect(cache.cache.containsKey(key), isFalse);
      });

      // Add more write tests here...
    });

    group('read operations', () {
      test('read a non-expired value', () async {
        String key = 'testKey';
        String value = 'testValue';
        DateTime expirationDate = DateTime.now().add(const Duration(seconds: 10));
        await cache.write<String>(
          key: key,
          value: value,
          expirationDate: expirationDate,
        );

        var result = await cache.read<String>(key: key);
        expect(result, isNotNull);
        expect(result?.$1, equals(value));
      });

      test('read an expired value', () async {
        String key = 'expiredKey';
        String value = 'testValue';
        expect(
          await cache.write<String>(
            key: key,
            value: value,
            expirationDate: DateTime.now(),
          ),
          isFalse,
        );

        expect(await cache.read<String>(key: key), isNull);

        expect(
          await cache.write<String>(
            key: key,
            value: value,
            expirationDate: DateTime.now()
                .subtract(const Duration(seconds: 10)),
          ),
          isFalse,
        );

        expect(await cache.read<String>(key: key), isNull);
      });

      // Add more read tests here...
    });

    group('remove operations', () {
      test('remove a present value', () async {
        String key = 'testKey';
        String value = 'testValue';
        DateTime expirationDate = DateTime.now().add(const Duration(seconds: 10));
        await cache.write<String>(
          key: key,
          value: value,
          expirationDate: expirationDate,
        );

        dynamic result ;
        await expectLater(
            () async => result = await cache.remove<String>(key: key),
            returnsNormally
        );
        expect(result, isNotNull);
        expect(result?.$1, equals(value));
        expect(await cache.remove<String>(key: 'invalid'), isNull);
      });

      test('remove a non-present value', () async {
        String key = 'nonexistentKey';

        var result = await cache.remove<String>(key: key);
        expect(result, isNull);
      });

      // Add more remove tests here...
    });

    test('writeAll with non-expired values and readAll', () async {
      List<(String key, String value, DateTime expirationDate)> valuesToWrite = [
        ('key1', 'value1', DateTime.now().add(const Duration(seconds: 10))),
        ('key2', 'value2', DateTime.now().add(const Duration(seconds: 20))),
      ];

      bool writeResult = await cache.writeAll<String>(values: valuesToWrite);
      expect(writeResult, isTrue);

      // Checking if values are written
      for (var tuple in valuesToWrite) {
        expect(cache.cache.containsKey(tuple.$1), isTrue);
        expect(cache.cache[tuple.$1], (tuple.$2, tuple.$3));
      }

      // Reading all values with a common key pattern
      var readResults = await cache.readAll<String>();
      expect(readResults.length, equals(valuesToWrite.length));
      readResults.removeWhere((result) {
        final tuple = valuesToWrite.firstWhere(
          (element) => result.$1 == element.$1
        );
        expect(tuple,(tuple.$1, tuple.$2, tuple.$3));
        return true;
      });
      expect(readResults.isEmpty, isTrue);
    });

    test('writeAll with some expired values and readAll', () async {
      List<(String key, String value, DateTime expirationDate)> valuesToWrite = [
        ('key1', 'value1', DateTime.now().subtract(const Duration(seconds: 10))),
        ('key2', 'value2', DateTime.now().add(const Duration(seconds: 20))),
      ];

      bool writeResult = await cache.writeAll<String>(values: valuesToWrite);
      expect(writeResult, isFalse);

      // Only non-expired values should be read
      var readResults = await cache.readAll<String>();
      expect(readResults.length, lessThan(valuesToWrite.length));
      expect(
          readResults.any((element) => element == valuesToWrite[0]),
          isFalse
      );
      expect(readResults.any(
          (element) => element == valuesToWrite[1]),
          isTrue
      );
    });

    group('clear operations', () {
      test('clear cache', () async {
        String key = 'testKey';
        String value = 'testValue';
        DateTime expirationDate = DateTime.now().add(const Duration(seconds: 10));
        await cache.write<String>(
          key: key,
          value: value,
          expirationDate: expirationDate,
        );

        bool result = await cache.clearAll<String>();
        expect(result, isTrue);
        var readResult = await cache.read<String>(key: key);
        expect(readResult, isNull);
      });
    });
  });
}

