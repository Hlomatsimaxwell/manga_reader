/// Which strategy [MadaraSource] uses to build the list of page image URLs
/// for a chapter.
///
/// Madara/CMS sites differ wildly here (generic CSS selectors cover the
/// listing/detail/chapter parts, but the reader is per-site):
/// - [inline]: images are in the chapter HTML (`#reading-content img`), eager
///   or lazy-loaded (`data-src`).
/// - [styleList]: same as [inline], but each URL gets `?style=list` appended,
///   which some image CDNs require to serve the page-sized file.
/// - [ajaxRest]: the site ships Madara's built-in REST endpoint, reached at
///   `{baseUrl}/rest-api/?action=szv_Chapter&manga=...&slug=...`.
/// - [chapterDataJs]: the page embeds a `chapterData`/`localized` JS object
///   holding the image array; extracted with a light regex pass.
enum MadaraPageExtractor { inline, styleList, ajaxRest, chapterDataJs }

/// Describes one Madara/WordPress manga site. A site is fully described by a
/// [MadaraSiteConfig] + the plugins it ships, so new sites can be added by
/// creating a config instead of writing a whole source.
class MadaraSiteConfig {
  const MadaraSiteConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.language = 'Manga, Manhwa, Manhua, English',
    this.iconUrl = '',
    this.popularPath = '?m_orderby=views',
    this.searchPath = '?s={query}&post_type=wp-manga',
    this.tagSearchPath = '?genre[]={tag}&post_type=wp-manga',
    this.mangaCardSelector = '.c-tabs-item__content',
    this.mangaTitleSelector = '.post-title a',
    this.mangaCoverSelector = 'img',
    this.coverAttr = 'src',
    this.detailDescriptionSelector = '.summary__content',
    this.detailAuthorsSelector = '.author-content a',
    this.detailGenresSelector = '.genres-content a',
    this.detailStatusSelector = '.post-status .summary-content',
    this.chapterListSelector = 'ul.main li.wp-manga-chapter',
    this.chapterLinkSelector = 'a',
    this.pageExtractor = MadaraPageExtractor.inline,
    this.readerImageSelector = '#reading-content img',
    this.readerImageAttr = 'data-src',
    this.imagesNeedReferer = false,
    this.extraHeaders = const {},
  });

  final String id;
  final String name;
  final String baseUrl;
  final String language;

  /// Favicon/logo shown on the source tile.
  final String iconUrl;

  /// Path template for popular manga; `{page}` is replaced by the page number.
  final String popularPath;

  /// Path template for title search; `{query}` is replaced with the
  /// URL-encoded query and `{page}` with the page number.
  final String searchPath;

  /// Path template for genre search; `{tag}` and `{page}` are replaced.
  final String tagSearchPath;

  // --- Listing / search selectors (each is relative to a singular group item
  // in the grid helper or resolved against the page) ---

  /// Selector for one manga card on popular/search/genre pages.
  final String mangaCardSelector;

  /// Anchor selector within one [mangaCardSelector] item.
  final String mangaTitleSelector;

  /// Image selector within one [mangaCardSelector] item.
  final String mangaCoverSelector;

  /// Attribute holding the cover URL (`src`, `data-src`, ...).
  final String coverAttr;

  // --- Details page selectors ---

  final String detailDescriptionSelector;
  final String detailAuthorsSelector;
  final String detailGenresSelector;
  final String detailStatusSelector;

  // --- Chapter list selectors ---

  /// Selector for one chapter entry on the details page.
  final String chapterListSelector;

  /// Anchor selector within one [chapterListSelector] entry.
  final String chapterLinkSelector;

  // --- Reader / page extraction ---

  /// How page image URLs are resolved for this site.
  final MadaraPageExtractor pageExtractor;

  /// Image element selector inside the reader HTML (inline extraction).
  final String readerImageSelector;

  /// Attribute holding the page image URL on [readerImageSelector] elements.
  final String readerImageAttr;

  /// Whether page images are hotlink-protected and need the site `Referer`
  /// attached. The reader forwards [MadaraSource.headers] on image requests,
  /// so this only controls what headers the source advertises.
  final bool imagesNeedReferer;

  /// Extra headers merged into every request (beyond the browser UA).
  final Map<String, String> extraHeaders;

  factory MadaraSiteConfig.fromJson(Map<String, dynamic> json) {
    return MadaraSiteConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      language: json['language'] as String? ?? 'Manga, Manhwa, Manhua, English',
      iconUrl: json['iconUrl'] as String? ?? '',
      popularPath: json['popularPath'] as String? ?? '?m_orderby=views',
      searchPath:
          json['searchPath'] as String? ?? '?s={query}&post_type=wp-manga',
      tagSearchPath: json['tagSearchPath'] as String? ??
          '?genre[]={tag}&post_type=wp-manga',
      mangaCardSelector:
          json['mangaCardSelector'] as String? ?? '.c-tabs-item__content',
      mangaTitleSelector:
          json['mangaTitleSelector'] as String? ?? '.post-title a',
      mangaCoverSelector: json['mangaCoverSelector'] as String? ?? 'img',
      coverAttr: json['coverAttr'] as String? ?? 'src',
      detailDescriptionSelector: json['detailDescriptionSelector'] as String? ??
          '.summary__content',
      detailAuthorsSelector:
          json['detailAuthorsSelector'] as String? ?? '.author-content a',
      detailGenresSelector:
          json['detailGenresSelector'] as String? ?? '.genres-content a',
      detailStatusSelector: json['detailStatusSelector'] as String? ??
          '.post-status .summary-content',
      chapterListSelector: json['chapterListSelector'] as String? ??
          'ul.main li.wp-manga-chapter',
      chapterLinkSelector:
          json['chapterLinkSelector'] as String? ?? 'a',
      pageExtractor: MadaraPageExtractor.values.firstWhere(
        (e) => e.name == json['pageExtractor'],
        orElse: () => MadaraPageExtractor.inline,
      ),
      readerImageSelector: json['readerImageSelector'] as String? ??
          '#reading-content img',
      readerImageAttr: json['readerImageAttr'] as String? ?? 'data-src',
      imagesNeedReferer: json['imagesNeedReferer'] as bool? ?? false,
      extraHeaders:
          (json['extraHeaders'] as Map?)?.cast<String, String>() ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'language': language,
      'iconUrl': iconUrl,
      'popularPath': popularPath,
      'searchPath': searchPath,
      'tagSearchPath': tagSearchPath,
      'mangaCardSelector': mangaCardSelector,
      'mangaTitleSelector': mangaTitleSelector,
      'mangaCoverSelector': mangaCoverSelector,
      'coverAttr': coverAttr,
      'detailDescriptionSelector': detailDescriptionSelector,
      'detailAuthorsSelector': detailAuthorsSelector,
      'detailGenresSelector': detailGenresSelector,
      'detailStatusSelector': detailStatusSelector,
      'chapterListSelector': chapterListSelector,
      'chapterLinkSelector': chapterLinkSelector,
      'pageExtractor': pageExtractor.name,
      'readerImageSelector': readerImageSelector,
      'readerImageAttr': readerImageAttr,
      'imagesNeedReferer': imagesNeedReferer,
      'extraHeaders': extraHeaders,
    };
  }
}