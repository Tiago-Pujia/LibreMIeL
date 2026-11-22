import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('AppDatabase migrations', () {
    test(
      'migration from v4 with existing avatar_url in cached_teachers succeeds idempotently',
      () async {
        final raw = sqlite3.openInMemory();
        raw.execute('PRAGMA user_version = 4;');
        raw.execute('''
          CREATE TABLE "subjects" (
            "id_comision" TEXT NOT NULL,
            "name" TEXT NOT NULL,
            "commission_code" TEXT NOT NULL DEFAULT '',
            "is_hidden_in_miel" INTEGER NOT NULL DEFAULT 0,
            "muted" INTEGER NOT NULL DEFAULT 0,
            "notify_contenidos" INTEGER NOT NULL DEFAULT 1,
            "notify_portafolio" INTEGER NOT NULL DEFAULT 1,
            "notify_mensajeria" INTEGER NOT NULL DEFAULT 1,
            "notify_foros" INTEGER NOT NULL DEFAULT 1,
            "notify_evaluacion" INTEGER NOT NULL DEFAULT 1,
            "has_portafolio" INTEGER NOT NULL DEFAULT 0,
            "has_evaluacion" INTEGER NOT NULL DEFAULT 0,
            "last_contenidos_badge" INTEGER NOT NULL DEFAULT 0,
            "last_mensajes_badge" INTEGER NOT NULL DEFAULT 0,
            "last_foro_badge" INTEGER NOT NULL DEFAULT 0,
            "last_synced_at" INTEGER NULL,
            "subject_code" TEXT NOT NULL DEFAULT '',
            "role_label" TEXT NOT NULL DEFAULT '',
            "has_contenidos" INTEGER NOT NULL DEFAULT 1,
            "has_autoguia" INTEGER NOT NULL DEFAULT 0,
            "has_mensajeria" INTEGER NOT NULL DEFAULT 1,
            "has_foro" INTEGER NOT NULL DEFAULT 1,
            "has_chat" INTEGER NOT NULL DEFAULT 0,
            "has_encuestas" INTEGER NOT NULL DEFAULT 0,
            "sort_order" INTEGER NOT NULL DEFAULT 0,
            "local_visibility_override" INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY ("id_comision")
          );
          CREATE TABLE "cached_teachers" (
            "id_comision" TEXT NOT NULL,
            "normalized_name" TEXT NOT NULL,
            "display_name" TEXT NOT NULL,
            "role" TEXT NOT NULL DEFAULT 'Tutor/a',
            "cached_at" INTEGER NOT NULL,
            "avatar_url" TEXT NOT NULL DEFAULT '',
            PRIMARY KEY ("id_comision", "normalized_name")
          );
          CREATE TABLE "snapshot_entries" (
            "id_comision" TEXT NOT NULL,
            "module" TEXT NOT NULL,
            "item_id" TEXT NOT NULL,
            "fingerprint" TEXT NOT NULL,
            "summary" TEXT NOT NULL DEFAULT '',
            "updated_at" INTEGER NOT NULL,
            PRIMARY KEY ("id_comision", "module", "item_id")
          );
          CREATE TABLE "notification_logs" (
            "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            "dedupe_key" TEXT NOT NULL UNIQUE,
            "id_comision" TEXT NOT NULL,
            "subject_name" TEXT NOT NULL,
            "module" TEXT NOT NULL,
            "title" TEXT NOT NULL,
            "body" TEXT NOT NULL,
            "target_url" TEXT NOT NULL DEFAULT '',
            "is_read" INTEGER NOT NULL DEFAULT 0,
            "created_at" INTEGER NOT NULL
          );
          CREATE TABLE "app_settings" (
            "key" TEXT NOT NULL,
            "value" TEXT NOT NULL,
            PRIMARY KEY ("key")
          );
          CREATE TABLE "downloaded_resources" (
            "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            "id_comision" TEXT NOT NULL,
            "module" TEXT NOT NULL,
            "resource_id" TEXT NOT NULL,
            "title" TEXT NOT NULL,
            "local_path" TEXT NOT NULL,
            "file_size" INTEGER NOT NULL,
            "sha256" TEXT NULL,
            "downloaded_at" INTEGER NOT NULL
          );
        ''');

        final db = AppDatabase(NativeDatabase.opened(raw));

        // Al ejecutar una consulta inicial, Drift dispara la migración onUpgrade(4, 5).
        final setting = await db.getSetting('dummy');
        expect(setting, isNull);

        // Verificamos que el PRAGMA user_version haya subido a 5
        final versionResult = raw.select('PRAGMA user_version;');
        expect(versionResult.first.columnAt(0), 5);

        await db.close();
      },
    );

    test(
      'migration from v4 without avatar_url adds the column successfully',
      () async {
        final raw = sqlite3.openInMemory();
        raw.execute('PRAGMA user_version = 4;');
        raw.execute('''
          CREATE TABLE "subjects" (
            "id_comision" TEXT NOT NULL,
            "name" TEXT NOT NULL,
            PRIMARY KEY ("id_comision")
          );
          CREATE TABLE "cached_teachers" (
            "id_comision" TEXT NOT NULL,
            "normalized_name" TEXT NOT NULL,
            "display_name" TEXT NOT NULL,
            "role" TEXT NOT NULL DEFAULT 'Tutor/a',
            "cached_at" INTEGER NOT NULL,
            PRIMARY KEY ("id_comision", "normalized_name")
          );
          CREATE TABLE "snapshot_entries" (
            "id_comision" TEXT NOT NULL,
            "module" TEXT NOT NULL,
            "item_id" TEXT NOT NULL,
            "fingerprint" TEXT NOT NULL,
            "summary" TEXT NOT NULL DEFAULT '',
            "updated_at" INTEGER NOT NULL,
            PRIMARY KEY ("id_comision", "module", "item_id")
          );
          CREATE TABLE "notification_logs" (
            "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            "dedupe_key" TEXT NOT NULL UNIQUE,
            "id_comision" TEXT NOT NULL,
            "subject_name" TEXT NOT NULL,
            "module" TEXT NOT NULL,
            "title" TEXT NOT NULL,
            "body" TEXT NOT NULL,
            "target_url" TEXT NOT NULL DEFAULT '',
            "is_read" INTEGER NOT NULL DEFAULT 0,
            "created_at" INTEGER NOT NULL
          );
          CREATE TABLE "app_settings" (
            "key" TEXT NOT NULL,
            "value" TEXT NOT NULL,
            PRIMARY KEY ("key")
          );
          CREATE TABLE "downloaded_resources" (
            "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            "id_comision" TEXT NOT NULL,
            "module" TEXT NOT NULL,
            "resource_id" TEXT NOT NULL,
            "title" TEXT NOT NULL,
            "local_path" TEXT NOT NULL,
            "file_size" INTEGER NOT NULL,
            "sha256" TEXT NULL,
            "downloaded_at" INTEGER NOT NULL
          );
        ''');

        final db = AppDatabase(NativeDatabase.opened(raw));
        await db.getSetting('dummy');

        // Verificamos que la columna avatar_url fue agregada
        final columns = raw.select('PRAGMA table_info(cached_teachers);');
        final columnNames = columns.map((r) => r['name']).toList();
        expect(columnNames, contains('avatar_url'));

        final versionResult = raw.select('PRAGMA user_version;');
        expect(versionResult.first.columnAt(0), 5);

        await db.close();
      },
    );

    test('real database copy from user environment migrates successfully', () async {
      final file = File('/tmp/test_libremiel.sqlite');
      if (!file.existsSync()) return;

      final db = AppDatabase(NativeDatabase(file));
      final interval = await db.getSyncIntervalMinutes();
      expect(interval, isA<int>());
      await db.close();
    });
  });
}
