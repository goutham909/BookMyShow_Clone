class CatalogBanner {
  const CatalogBanner({
    required this.id,
    required this.headline,
    required this.subhead,
    required this.imageRef,
    this.deepLinkMovieId,
    this.deepLinkEventId,
  });

  final String id;
  final String headline;
  final String subhead;
  final String imageRef;
  final String? deepLinkMovieId;
  final String? deepLinkEventId;

  factory CatalogBanner.fromJson(Map<String, dynamic> j) {
    return CatalogBanner(
      id: j['id'] as String,
      headline: j['headline'] as String,
      subhead: j['subhead'] as String,
      imageRef: j['imageRef'] as String,
      deepLinkMovieId: j['deepLinkMovieId'] as String?,
      deepLinkEventId: j['deepLinkEventId'] as String?,
    );
  }
}

/// Optional hero promo under the home carousel (BookMyShow-style strip).
class HomePromoStrip {
  const HomePromoStrip({
    required this.imageRef,
    required this.headline,
    required this.ctaLabel,
    this.deepLinkEventId,
    this.deepLinkRoute,
  });

  final String imageRef;
  final String headline;
  final String ctaLabel;
  final String? deepLinkEventId;
  /// e.g. `liveEvents` | `movies` when no event id.
  final String? deepLinkRoute;

  factory HomePromoStrip.fromJson(Map<String, dynamic> j) {
    return HomePromoStrip(
      imageRef: j['imageRef'] as String,
      headline: j['headline'] as String,
      ctaLabel: j['ctaLabel'] as String,
      deepLinkEventId: j['deepLinkEventId'] as String?,
      deepLinkRoute: j['deepLinkRoute'] as String?,
    );
  }
}

class ContentRail {
  const ContentRail({
    required this.id,
    required this.title,
    this.subtitle,
    this.movieIds = const [],
    this.eventIds = const [],
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<String> movieIds;
  final List<String> eventIds;

  factory ContentRail.fromJson(Map<String, dynamic> j) {
    return ContentRail(
      id: j['id'] as String,
      title: j['title'] as String,
      subtitle: j['subtitle'] as String?,
      movieIds: (j['movieIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      eventIds: (j['eventIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.area,
    this.logoRef,
    this.nonCancellable = false,
  });

  final String id;
  final String name;
  final String area;
  final String? logoRef;
  final bool nonCancellable;

  factory Venue.fromJson(Map<String, dynamic> j) {
    return Venue(
      id: j['id'] as String,
      name: j['name'] as String,
      area: j['area'] as String,
      logoRef: j['logoRef'] as String?,
      nonCancellable: j['nonCancellable'] as bool? ?? false,
    );
  }
}

class CastMember {
  const CastMember({required this.name, required this.imageRef});

  final String name;
  final String imageRef;

  factory CastMember.fromJson(Map<String, dynamic> j) {
    return CastMember(
      name: j['name'] as String,
      imageRef: j['imageRef'] as String,
    );
  }
}

class EventTicketTier {
  const EventTicketTier({
    required this.name,
    required this.priceInr,
    this.fastFilling = false,
  });

  final String name;
  final double priceInr;
  final bool fastFilling;

  factory EventTicketTier.fromJson(Map<String, dynamic> j) {
    return EventTicketTier(
      name: j['name'] as String,
      priceInr: (j['priceInr'] as num).toDouble(),
      fastFilling: j['fastFilling'] as bool? ?? false,
    );
  }
}

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.durationMins,
    required this.certification,
    required this.languages,
    required this.rating,
    required this.ratingCount,
    required this.synopsis,
    required this.posterRef,
    required this.heroRef,
    required this.tags,
    this.releaseDateLabel,
    this.formatsLine,
    this.engagementUsesLikes = false,
    this.cast = const [],
    this.trailerCount = 1,
    this.trendingTicketsLine,
    this.formatOptions = const [],
  });

  final String id;
  final String title;
  final String genre;
  final int durationMins;
  final String certification;
  final String languages;
  final double rating;
  final int ratingCount;
  final String synopsis;
  final String posterRef;
  final String heroRef;
  final List<String> tags;
  /// Shown on detail hero strip, e.g. "Releasing on 3 Apr, 2026".
  final String? releaseDateLabel;
  /// e.g. "2D, IMAX" — optional separate from [tags].
  final String? formatsLine;
  /// If true, home/movies grids show thumbs-up + "likes" instead of star votes.
  final bool engagementUsesLikes;
  final List<CastMember> cast;
  final int trailerCount;
  final String? trendingTicketsLine;
  /// Discrete format labels for the language/format bottom sheet (e.g. 2D, 4DX).
  final List<String> formatOptions;

  static String formatCountShort(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M+';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K+';
    return '$n';
  }

  factory Movie.fromJson(Map<String, dynamic> j) {
    final castRaw = j['cast'] as List<dynamic>?;
    return Movie(
      id: j['id'] as String,
      title: j['title'] as String,
      genre: j['genre'] as String,
      durationMins: (j['durationMins'] as num).toInt(),
      certification: j['certification'] as String,
      languages: j['languages'] as String,
      rating: (j['rating'] as num).toDouble(),
      ratingCount: (j['ratingCount'] as num).toInt(),
      synopsis: j['synopsis'] as String,
      posterRef: j['posterRef'] as String,
      heroRef: j['heroRef'] as String,
      tags: (j['tags'] as List<dynamic>).cast<String>(),
      releaseDateLabel: j['releaseDateLabel'] as String?,
      formatsLine: j['formatsLine'] as String?,
      engagementUsesLikes: j['engagementUsesLikes'] as bool? ?? false,
      cast: castRaw == null
          ? const []
          : castRaw.map((x) => CastMember.fromJson(x as Map<String, dynamic>)).toList(),
      trailerCount: (j['trailerCount'] as num?)?.toInt() ?? 1,
      trendingTicketsLine: j['trendingTicketsLine'] as String?,
      formatOptions: (j['formatOptions'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

class LiveEvent {
  const LiveEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.venueId,
    required this.dateLabel,
    required this.priceFrom,
    required this.imageRef,
    required this.synopsis,
    this.appBarTitle,
    this.venueLine,
    this.dateTimeSubtitle,
    this.interestedCount = 0,
    this.eventTags = const [],
    this.durationLabel,
    this.ageGroup,
    this.languageLabel,
    this.showTypeLabel,
    this.fillingFast = false,
    this.ticketTiers = const [],
  });

  final String id;
  final String title;
  final String category;
  final String venueId;
  final String dateLabel;
  final double priceFrom;
  final String imageRef;
  final String synopsis;
  final String? appBarTitle;
  final String? venueLine;
  final String? dateTimeSubtitle;
  final int interestedCount;
  final List<String> eventTags;
  final String? durationLabel;
  final String? ageGroup;
  final String? languageLabel;
  final String? showTypeLabel;
  final bool fillingFast;
  final List<EventTicketTier> ticketTiers;

  factory LiveEvent.fromJson(Map<String, dynamic> j) {
    final tiersRaw = j['ticketTiers'] as List<dynamic>?;
    return LiveEvent(
      id: j['id'] as String,
      title: j['title'] as String,
      category: j['category'] as String,
      venueId: j['venueId'] as String,
      dateLabel: j['dateLabel'] as String,
      priceFrom: (j['priceFrom'] as num).toDouble(),
      imageRef: j['imageRef'] as String,
      synopsis: j['synopsis'] as String,
      appBarTitle: j['appBarTitle'] as String?,
      venueLine: j['venueLine'] as String?,
      dateTimeSubtitle: j['dateTimeSubtitle'] as String?,
      interestedCount: (j['interestedCount'] as num?)?.toInt() ?? 0,
      eventTags: (j['eventTags'] as List<dynamic>?)?.cast<String>() ?? const [],
      durationLabel: j['durationLabel'] as String?,
      ageGroup: j['ageGroup'] as String?,
      languageLabel: j['languageLabel'] as String?,
      showTypeLabel: j['showTypeLabel'] as String?,
      fillingFast: j['fillingFast'] as bool? ?? false,
      ticketTiers: tiersRaw == null
          ? const []
          : tiersRaw.map((x) => EventTicketTier.fromJson(x as Map<String, dynamic>)).toList(),
    );
  }
}

class Showtime {
  const Showtime({
    required this.id,
    required this.venueId,
    required this.time24,
    required this.format,
    required this.priceFrom,
    this.screenLabel,
    this.visualTier,
    this.visitedHint = false,
  });

  final String id;
  final String venueId;
  final String time24;
  final String format;
  final double priceFrom;
  /// Shown under time, e.g. PXL, VIP SCREEN.
  final String? screenLabel;
  /// gold | green (late show) | null.
  final String? visualTier;
  final bool visitedHint;

  factory Showtime.fromJson(Map<String, dynamic> j) {
    return Showtime(
      id: j['id'] as String,
      venueId: j['venueId'] as String,
      time24: j['time24'] as String,
      format: j['format'] as String,
      priceFrom: (j['priceFrom'] as num).toDouble(),
      screenLabel: j['screenLabel'] as String?,
      visualTier: j['visualTier'] as String?,
      visitedHint: j['visitedHint'] as bool? ?? false,
    );
  }
}

class Catalog {
  const Catalog({
    required this.schemaVersion,
    required this.datasetId,
    required this.cityLabel,
    required this.banners,
    required this.rails,
    required this.venues,
    required this.movies,
    required this.events,
    required this.movieShowtimes,
    this.homePromo,
  });

  final int schemaVersion;
  final String datasetId;
  final String cityLabel;
  final List<CatalogBanner> banners;
  final List<ContentRail> rails;
  final HomePromoStrip? homePromo;
  final List<Venue> venues;
  final List<Movie> movies;
  final List<LiveEvent> events;
  final Map<String, List<Showtime>> movieShowtimes;

  Movie? movieById(String id) {
    for (final m in movies) {
      if (m.id == id) return m;
    }
    return null;
  }

  LiveEvent? eventById(String id) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  Venue? venueById(String id) {
    for (final v in venues) {
      if (v.id == id) return v;
    }
    return null;
  }

  List<Showtime> showtimesForMovie(String movieId) => movieShowtimes[movieId] ?? const [];

  factory Catalog.fromJson(Map<String, dynamic> j) {
    final showtimesRaw = j['movieShowtimes'] as Map<String, dynamic>? ?? {};
    final showtimes = <String, List<Showtime>>{};
    for (final e in showtimesRaw.entries) {
      showtimes[e.key] = (e.value as List<dynamic>)
          .map((x) => Showtime.fromJson(x as Map<String, dynamic>))
          .toList();
    }

    final promoRaw = j['homePromo'] as Map<String, dynamic>?;

    return Catalog(
      schemaVersion: (j['schemaVersion'] as num).toInt(),
      datasetId: j['datasetId'] as String,
      cityLabel: j['cityLabel'] as String,
      banners: (j['banners'] as List<dynamic>)
          .map((x) => CatalogBanner.fromJson(x as Map<String, dynamic>))
          .toList(),
      rails: (j['rails'] as List<dynamic>)
          .map((x) => ContentRail.fromJson(x as Map<String, dynamic>))
          .toList(),
      homePromo: promoRaw == null ? null : HomePromoStrip.fromJson(promoRaw),
      venues: (j['venues'] as List<dynamic>)
          .map((x) => Venue.fromJson(x as Map<String, dynamic>))
          .toList(),
      movies: (j['movies'] as List<dynamic>)
          .map((x) => Movie.fromJson(x as Map<String, dynamic>))
          .toList(),
      events: (j['events'] as List<dynamic>)
          .map((x) => LiveEvent.fromJson(x as Map<String, dynamic>))
          .toList(),
      movieShowtimes: showtimes,
    );
  }
}
