class Bookmark {
  final int id;
  final String mangaId;
  final String chapterId;
  final String chapterTitle;
  final int pageIndex;
  final String pageUrl;
  final String? note;
  final String createdAt;

  const Bookmark({
    required this.id,
    required this.mangaId,
    required this.chapterId,
    required this.chapterTitle,
    required this.pageIndex,
    required this.pageUrl,
    this.note,
    required this.createdAt,
  });

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int,
      mangaId: map['mangaId'] as String,
      chapterId: map['chapterId'] as String,
      chapterTitle: map['chapterTitle'] as String,
      pageIndex: map['pageIndex'] as int,
      pageUrl: map['pageUrl'] as String,
      note: map['note'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }
}
