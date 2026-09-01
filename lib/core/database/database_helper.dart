import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Singleton pattern to ensure only one database connection exists
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Get the default path for databases on Android/iOS
    String path = join(await getDatabasesPath(), 'manga_reader.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Create a table to store reading progress
    await db.execute('''
      CREATE TABLE reading_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mangaId TEXT NOT NULL,
        chapterId TEXT NOT NULL,
        chapterNumber REAL NOT NULL,
        lastReadAt TEXT NOT NULL
      )
    ''');
  }

  // Method to mark a chapter as read
  Future<void> markChapterAsRead(String mangaId, String chapterId, double chapterNum) async {
    final db = await instance.database;

    // We use 'conflictAlgorithm: ConflictAlgorithm.replace' 
    // so that if the chapter is already there, it just updates the number.
    await db.insert(
      'reading_progress',
      {
        'mangaId': mangaId,
        'chapterId': chapterId,
        'chapterNumber': chapterNum,
        'lastReadAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // You can add a method here later to get the last read chapter
  Future<Map<String, dynamic>?> getLastReadChapter(String mangaId) async {
    final db = await instance.database;
    final result = await db.query(
      'reading_progress',
      where: 'mangaId = ?',
      whereArgs: [mangaId],
      orderBy: 'chapterNumber DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
