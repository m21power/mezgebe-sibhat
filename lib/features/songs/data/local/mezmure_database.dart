import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:mezgebe_sibhat/features/Service/adService.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class MezmureDatabase {
  static const String _assetPath = 'assets/mezmure.db.enc';

  // TEST KEY ONLY.
  // Replace this later with your fragmented production key.
  static String password = DbKey.value;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();

    final dbPath = p.join(documentsDirectory.path, 'mezmure.db');

    final dbFile = File(dbPath);

    // Copy the encrypted asset only the first time.
    if (!await dbFile.exists()) {
      final ByteData data = await rootBundle.load(_assetPath);

      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await dbFile.writeAsBytes(bytes, flush: true);
    }

    final db = await openDatabase(dbPath, password: password, readOnly: true);

    return db;
  }

  Future<List<Map<String, dynamic>>> getAllSongs() async {
    final db = await database;

    return db.query('songs', orderBy: 'id ASC');
  }

  Future<List<Map<String, dynamic>>> getChildren(int parentId) async {
    final db = await database;

    return db.query(
      'songs',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'id ASC',
    );
  }

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
