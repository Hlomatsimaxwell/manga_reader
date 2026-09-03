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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS manga (
          mangaId TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          coverUrl TEXT,
          sourceId TEXT,
          totalChapters INTEGER DEFAULT 0,
          lastReadChapter REAL DEFAULT -1,
          lastReadAt TEXT,
          isFavorite INTEGER DEFAULT 0,
          isReadLater INTEGER DEFAULT 0
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    // Store per-chapter reading records
    await db.execute('''
      CREATE TABLE reading_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mangaId TEXT NOT NULL,
        chapterId TEXT NOT NULL,
        chapterNumber REAL NOT NULL,
        lastReadAt TEXT NOT NULL
      )
    ''');

    // Store manga metadata used to build the History screen
    await db.execute('''
      CREATE TABLE manga (
        mangaId TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        coverUrl TEXT,
        sourceId TEXT,
        totalChapters INTEGER DEFAULT 0,
        lastReadChapter REAL DEFAULT -1,
        lastReadAt TEXT,
        isFavorite INTEGER DEFAULT 0,
        isReadLater INTEGER DEFAULT 0
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

  // Record a manga's metadata + latest read chapter (used to build History).
  // Upserts: preserves favorite/readLater state if already present.
  Future<void> saveMangaProgress({
    required String mangaId,
    required String title,
    String? coverUrl,
    String? sourceId,
    int totalChapters = 0,
    required double lastReadChapter,
  }) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();

    final existing = await db.query(
      'manga',
      where: 'mangaId = ?',
      whereArgs: [mangaId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final row = existing.first;
      final prevChapter = (row['lastReadChapter'] as num? ?? -1).toDouble();
      final newChapter =
          lastReadChapter > prevChapter ? lastReadChapter : prevChapter;

      await db.update(
        'manga',
        {
          'title': title,
          'coverUrl': coverUrl ?? row['coverUrl'],
          'sourceId': sourceId ?? row['sourceId'],
          'totalChapters': totalChapters > 0
              ? totalChapters
              : (row['totalChapters'] as int? ?? 0),
          'lastReadChapter': newChapter,
          'lastReadAt': now,
        },
        where: 'mangaId = ?',
        whereArgs: [mangaId],
      );
    } else {
      await db.insert(
        'manga',
        {
          'mangaId': mangaId,
          'title': title,
          'coverUrl': coverUrl,
          'sourceId': sourceId,
          'totalChapters': totalChapters,
          'lastReadChapter': lastReadChapter,
          'lastReadAt': now,
          'isFavorite': 0,
          'isReadLater': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Returns all manga that have reading history, most recently read first.
  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await instance.database;
    final result = await db.query(
      'manga',
      where: 'lastReadChapter >= 0',
      orderBy: 'lastReadAt DESC',
    );
    return result;
  }

  Future<Map<String, dynamic>?> getManga(String mangaId) async {
    final db = await instance.database;
    final result = await db.query(
      'manga',
      where: 'mangaId = ?',
      whereArgs: [mangaId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Remove all reading history (leaves favorites intact).
  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete('manga', where: 'lastReadChapter >= 0');
    await db.delete('reading_progress');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
