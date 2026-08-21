import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../features/sources/models/manga.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('manga_reader.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Enable FFI for Linux/Desktop support
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites (
        id TEXT PRIMARY KEY,
        sourceId TEXT NOT NULL,
        title TEXT NOT NULL,
        coverUrl TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE history (
        mangaId TEXT PRIMARY KEY,
        lastChapterId TEXT NOT NULL,
        lastChapterTitle TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  // Favorite Operations
  Future<void> toggleFavorite(Manga manga) async {
    final db = await instance.database;
    final isFav = await isFavorite(manga.id);

    if (isFav) {
      await db.delete('favorites', where: 'id = ?', whereArgs: [manga.id]);
    } else {
      await db.insert('favorites', {
        'id': manga.id,
        'sourceId': manga.sourceId,
        'title': manga.title,
        'coverUrl': manga.coverUrl,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<bool> isFavorite(String mangaId) async {
    final db = await instance.database;
    final maps = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [mangaId],
    );
    return maps.isNotEmpty;
  }

 Future<void> markChapterAsRead(String mangaId, String chapterId, double chapterNum) async {
  final db = await instance.database;
  await db.insert(
    'history',
    {
      'mangaId': mangaId,
      'lastChapterId': chapterId,
      'lastChapterTitle': chapterNum.toString(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<double> getMaxReadChapterNum(String mangaId) async {
  final db = await instance.database;
  final maps = await db.query(
    'history',
    where: 'mangaId = ?',
    whereArgs: [mangaId],
  );
  if (maps.isEmpty) return -1.0;
  
  double maxNum = -1.0;
  for (var map in maps) {
    final num = double.tryParse(map['lastChapterTitle'] as String? ?? '') ?? -1.0;
    if (num > maxNum) maxNum = num;
  }
  return maxNum;
}

  Future<Set<String>> getReadChapterIds() async {
    final db = await instance.database;
    final maps = await db.query('history');
    return maps.map((e) => e['lastChapterId'] as String).toSet();
  }

  Future<List<Manga>> getFavorites() async {
    final db = await instance.database;
    final maps = await db.query('favorites');

    return maps.map((json) {
      return Manga(
        id: json['id'] as String,
        sourceId: json['sourceId'] as String,
        title: json['title'] as String,
        coverUrl: json['coverUrl'] as String,
      );
    }).toList();
  }
}
