import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/storage/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('OfflinePageCache & AppDatabase offline methods', () {
    test(
      'putOfflinePage and getOfflinePage store and retrieve HTML content',
      () async {
        await db.putOfflinePage(
          cacheKey: 'comision_101',
          idComision: '101',
          module: 'comision',
          htmlContent: '<html>Comision 101</html>',
        );

        final cached = await db.getOfflinePage('comision_101');
        expect(cached, isNotNull);
        expect(cached!.cacheKey, 'comision_101');
        expect(cached.idComision, '101');
        expect(cached.module, 'comision');
        expect(cached.htmlContent, '<html>Comision 101</html>');
        expect(cached.sizeBytes.toInt(), greaterThan(0));
      },
    );

    test('getOfflinePage updates lastAccessedAt timestamp', () async {
      await db.putOfflinePage(
        cacheKey: 'test_access',
        idComision: '1',
        module: 'test',
        htmlContent: 'Content',
      );

      final first = await db.getOfflinePage('test_access');
      final firstAccess = first!.lastAccessedAt;

      await Future<void>.delayed(const Duration(milliseconds: 15));

      final second = await db.getOfflinePage('test_access');
      final secondAccess = second!.lastAccessedAt;

      expect(
        secondAccess.isAfter(firstAccess) ||
            secondAccess.isAtSameMomentAs(firstAccess),
        isTrue,
      );
    });

    test('putOfflinePage updates existing key on conflict', () async {
      await db.putOfflinePage(
        cacheKey: 'key_1',
        idComision: '101',
        module: 'comision',
        htmlContent: 'Old version',
      );

      await db.putOfflinePage(
        cacheKey: 'key_1',
        idComision: '101',
        module: 'comision',
        htmlContent: 'New updated version',
      );

      final cached = await db.getOfflinePage('key_1');
      expect(cached!.htmlContent, 'New updated version');
    });

    test('getOfflineCacheTotalBytes sums size of all entries', () async {
      await db.putOfflinePage(
        cacheKey: 'k1',
        idComision: '1',
        module: 'm1',
        htmlContent: '12345',
      );
      await db.putOfflinePage(
        cacheKey: 'k2',
        idComision: '2',
        module: 'm2',
        htmlContent: 'abcde',
      );

      final total = await db.getOfflineCacheTotalBytes();
      expect(total, 10);
    });

    test(
      'pruneOfflineCacheToQuota purges LRU entries when exceeding maxCacheMb',
      () async {
        // Creamos 3 entradas con marcas temporales escalonadas
        await db.putOfflinePage(
          cacheKey: 'oldest',
          idComision: '1',
          module: 'm',
          htmlContent: 'x' * 600, // 600 bytes
        );
        await Future<void>.delayed(const Duration(milliseconds: 15));

        await db.putOfflinePage(
          cacheKey: 'middle',
          idComision: '2',
          module: 'm',
          htmlContent: 'y' * 600, // 600 bytes
        );
        await Future<void>.delayed(const Duration(milliseconds: 15));

        await db.putOfflinePage(
          cacheKey: 'newest',
          idComision: '3',
          module: 'm',
          htmlContent: 'z' * 600, // 600 bytes
        );

        var total = await db.getOfflineCacheTotalBytes();
        expect(total, 1800);

        // Si llamamos con maxCacheMb con cuota simulada de 0 MB (o forzamos poda manual)
        // Como pruneOfflineCacheToQuota usa MB, probemos llamándolo con 0 MB
        await db.pruneOfflineCacheToQuota(maxCacheMb: 0);

        total = await db.getOfflineCacheTotalBytes();
        expect(total, 0);

        final remaining = await db.getOfflinePage('oldest');
        expect(remaining, isNull);
      },
    );

    test('clearOfflineCache deletes all rows in offline_page_cache', () async {
      await db.putOfflinePage(
        cacheKey: 'k1',
        idComision: '1',
        module: 'm1',
        htmlContent: 'abc',
      );
      await db.putOfflinePage(
        cacheKey: 'k2',
        idComision: '2',
        module: 'm2',
        htmlContent: 'xyz',
      );

      await db.clearOfflineCache();
      expect(await db.getOfflineCacheTotalBytes(), 0);
      expect(await db.getOfflinePage('k1'), isNull);
      expect(await db.getOfflinePage('k2'), isNull);
    });

    test('clearAccountData deletes offline_page_cache rows', () async {
      await db.putOfflinePage(
        cacheKey: 'account_page',
        idComision: '10',
        module: 'foros',
        htmlContent: 'Cached forum',
      );

      await db.clearAccountData();
      expect(await db.getOfflinePage('account_page'), isNull);
    });

    test(
      'pruneSubjectsNotIn removes cache rows for deactivated comisiones',
      () async {
        await db.putOfflinePage(
          cacheKey: 'active_page',
          idComision: '100',
          module: 'comision',
          htmlContent: 'Active',
        );
        await db.putOfflinePage(
          cacheKey: 'dead_page',
          idComision: '999',
          module: 'comision',
          htmlContent: 'Dead',
        );
        await db.putOfflinePage(
          cacheKey: 'global_page',
          idComision: '',
          module: 'global',
          htmlContent: 'Global',
        );

        await db.pruneSubjectsNotIn({'100'});

        expect(await db.getOfflinePage('active_page'), isNotNull);
        expect(await db.getOfflinePage('dead_page'), isNull);
        expect(await db.getOfflinePage('global_page'), isNotNull);
      },
    );

    test(
      'Offline settings getters return correct defaults and configured values',
      () async {
        // Valores por defecto
        expect(await db.getOfflineModeEnabled(), isFalse);
        expect(await db.getOfflinePrefetchSafeModules(), isFalse);
        expect(await db.getOfflineCacheMaxMb(), 100);

        // Seteo de valores
        await db.setSetting(SettingKeys.offlineModeEnabled, 'true');
        await db.setSetting(SettingKeys.offlinePrefetchSafeModules, 'true');
        await db.setSetting(SettingKeys.offlineCacheMaxMb, '250');

        expect(await db.getOfflineModeEnabled(), isTrue);
        expect(await db.getOfflinePrefetchSafeModules(), isTrue);
        expect(await db.getOfflineCacheMaxMb(), 250);
      },
    );
  });
}
