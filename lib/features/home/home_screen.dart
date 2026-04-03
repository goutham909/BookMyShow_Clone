import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../data/models/catalog_models.dart';
import '../../providers/providers.dart';
import '../../widgets/catalog_image.dart';

/// Muted blue-grey for "likes" lines on poster tiles (BookMyShow-style).
const Color _kLikesLineColor = Color(0xFF5C6BC0);

void _showCityPicker(BuildContext context, WidgetRef ref, String currentCity) {
  final options = ['Mumbai', 'Delhi-NCR', 'Bengaluru', 'Hyderabad', 'Pune', 'Chennai', 'Kolkata'];
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Select your region',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final city in options)
            ListTile(
              title: Text(city),
              trailing: currentCity == city || currentCity.contains(city.split('-').first)
                  ? const Icon(Icons.check_rounded, color: AppTokens.primaryRed)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                ref.read(homeCityLabelProvider.notifier).setCity(city);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void _onHomeCategoryTap(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.goNamed('movies');
      break;
    case 1:
      context.pushNamed('search', queryParameters: const {'pill': '1', 'q': 'lounge'});
      break;
    case 2:
      context.pushNamed('search', queryParameters: const {'q': 'IPL', 'pill': '2'});
      break;
    case 3:
      context.goNamed('liveEvents');
      break;
    case 4:
      context.pushNamed('search', queryParameters: const {'q': 'comedy', 'pill': '1'});
      break;
    case 5:
      context.pushNamed('search', queryParameters: const {'q': 'attractions', 'pill': '2'});
      break;
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bannerIndex = 0;
  late final PageController _bannerPageController;
  final ScrollController _homeScrollController = ScrollController();
  Timer? _bannerAutoTimer;
  int? _bannerAutoForCount;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController();
  }

  void _syncBannerAutoAdvance(int bannerCount) {
    if (bannerCount < 2) {
      _bannerAutoTimer?.cancel();
      _bannerAutoTimer = null;
      _bannerAutoForCount = null;
      return;
    }
    if (_bannerAutoForCount == bannerCount && (_bannerAutoTimer?.isActive ?? false)) {
      return;
    }
    _bannerAutoForCount = bannerCount;
    _bannerAutoTimer?.cancel();
    _bannerAutoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerPageController.hasClients) return;
      final current = _bannerPageController.page?.round() ?? _bannerIndex;
      final next = (current + 1) % bannerCount;
      _bannerPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerAutoTimer?.cancel();
    _homeScrollController.dispose();
    _bannerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(catalogProvider);
    final cityOverride = ref.watch(homeCityLabelProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Could not load catalog.\n$e', textAlign: TextAlign.center)),
      ),
      data: (catalog) {
        final n = catalog.banners.length;
        if (n > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncBannerAutoAdvance(n);
          });
        } else {
          _bannerAutoTimer?.cancel();
          _bannerAutoTimer = null;
          _bannerAutoForCount = null;
        }
        final cityLabel = cityOverride ?? catalog.cityLabel;
        return Scaffold(
          backgroundColor: AppTokens.canvas,
          body: _HomeBody(
            scrollController: _homeScrollController,
            catalog: catalog,
            cityLabel: cityLabel,
            onOpenCityPicker: () => _showCityPicker(context, ref, cityLabel),
            bannerIndex: _bannerIndex,
            onBannerChanged: (i) => setState(() => _bannerIndex = i),
            bannerPageController: _bannerPageController,
          ),
        );
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.scrollController,
    required this.catalog,
    required this.cityLabel,
    required this.onOpenCityPicker,
    required this.bannerIndex,
    required this.onBannerChanged,
    required this.bannerPageController,
  });

  final ScrollController scrollController;
  final Catalog catalog;
  final String cityLabel;
  final VoidCallback onOpenCityPicker;
  final int bannerIndex;
  final ValueChanged<int> onBannerChanged;
  final PageController bannerPageController;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bannerHeight = ((w - 32) / 2).clamp(160.0, 220.0);

    return CustomScrollView(
      controller: scrollController,
      primary: false,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Guest!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              height: 1.15,
                              color: const Color(0xFF212121),
                            ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: onOpenCityPicker,
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cityLabel,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTokens.primaryRed,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppTokens.primaryRed, size: 22),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.pushNamed('search'),
                  icon: const Icon(Icons.search_rounded),
                  color: const Color(0xFF212121),
                  visualDensity: VisualDensity.compact,
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifications: 2 new offers (demo).')),
                        );
                      },
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: const Color(0xFF212121),
                      visualDensity: VisualDensity.compact,
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTokens.primaryRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        alignment: Alignment.center,
                        child: const Text(
                          '2',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _HomeCategoryStrip(onTap: (i) => _onHomeCategoryTap(context, i))),
        if (catalog.banners.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                child: SizedBox(
                  height: bannerHeight,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PageView.builder(
                        controller: bannerPageController,
                        itemCount: catalog.banners.length,
                        onPageChanged: onBannerChanged,
                        itemBuilder: (context, i) {
                          return _BannerCard(banner: catalog.banners[i]);
                        },
                      ),
                      Positioned(
                        bottom: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            catalog.banners.length,
                            (i) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == bannerIndex
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: catalog.homePromo != null
                  ? _ImagePromoStrip(promo: catalog.homePromo!)
                  : _TextPromoFallback(banner: catalog.banners.first),
            ),
          ),
        ],
        ...catalog.rails.expand((rail) sync* {
          yield SliverToBoxAdapter(child: _RailSection(catalog: catalog, rail: rail));
        }),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _HomeCategoryStrip extends StatelessWidget {
  const _HomeCategoryStrip({required this.onTap});

  final ValueChanged<int> onTap;

  static const _labels = [
    'Movies',
    'HSBC Lounge',
    'TATA IPL 2026',
    'Music Shows',
    'Comedy Shows',
    'Tourist Attractions',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        physics: const BouncingScrollPhysics(),
        itemCount: _labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          return _CategoryItem(
            label: _labels[i],
            index: i,
            onTap: () => onTap(i),
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.label,
    required this.index,
    required this.onTap,
  });

  final String label;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 64,
              width: 64,
              child: _CategoryGlyph(index: index),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.15,
                    color: const Color(0xFF424242),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGlyph extends StatelessWidget {
  const _CategoryGlyph({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final ring = BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFFF5F5F5),
      border: Border.all(color: const Color(0xFFE8E8E8)),
    );

    switch (index) {
      case 0:
        return Container(
          decoration: ring,
          alignment: Alignment.center,
          child: Icon(Icons.movie_filter_rounded, size: 30, color: AppTokens.primaryRed),
        );
      case 1:
        return Container(
          decoration: ring,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(Icons.confirmation_number_rounded, size: 28, color: AppTokens.textSecondary),
              Positioned(
                top: 4,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTokens.primaryRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FAV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 2:
        return Container(
          decoration: ring,
          alignment: Alignment.center,
          child: Icon(Icons.sports_cricket_rounded, size: 32, color: const Color(0xFF2E7D32)),
        );
      case 3:
        return Container(
          decoration: ring,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.mic_rounded, size: 26, color: AppTokens.textSecondary),
              Positioned(
                bottom: 14,
                right: 10,
                child: Icon(Icons.music_note_rounded, size: 16, color: AppTokens.primaryRed),
              ),
            ],
          ),
        );
      case 4:
        return Container(
          decoration: ring,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.mic_rounded, size: 26, color: AppTokens.textSecondary),
              Positioned(
                bottom: 10,
                child: Text(
                  'HA HA',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppTokens.primaryRed,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      case 5:
        return Container(
          decoration: ring,
          alignment: Alignment.center,
          child: Icon(Icons.attractions_rounded, size: 28, color: const Color(0xFF5C6BC0)),
        );
      default:
        return Container(decoration: ring);
    }
  }
}

class _ImagePromoStrip extends StatelessWidget {
  const _ImagePromoStrip({required this.promo});

  final HomePromoStrip promo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (promo.deepLinkEventId != null) {
            context.push('/event/${promo.deepLinkEventId}');
          } else if (promo.deepLinkRoute == 'movies') {
            context.goNamed('movies');
          } else {
            context.goNamed('liveEvents');
          }
        },
        child: SizedBox(
          height: 88,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CatalogImage(url: promo.imageRef, borderRadius: BorderRadius.zero),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Text(
                              'PLAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            promo.headline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (promo.deepLinkEventId != null) {
                          context.push('/event/${promo.deepLinkEventId}');
                        } else {
                          context.goNamed('liveEvents');
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTokens.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(
                        promo.ctaLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextPromoFallback extends StatelessWidget {
  const _TextPromoFallback({required this.banner});

  final CatalogBanner banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              banner.subhead,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Offer applied: ${banner.subhead}')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final CatalogBanner banner;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (banner.deepLinkMovieId != null) {
            context.push('/movie/${banner.deepLinkMovieId}');
          } else if (banner.deepLinkEventId != null) {
            context.push('/event/${banner.deepLinkEventId}');
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            CatalogImage(url: banner.imageRef, borderRadius: BorderRadius.zero),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 48,
              bottom: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.headline,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          height: 1.15,
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 8),
                          ],
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    banner.subhead,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 12,
                          height: 1.25,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailSection extends StatelessWidget {
  const _RailSection({required this.catalog, required this.rail});

  final Catalog catalog;
  final ContentRail rail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rail.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                    ),
                    if (rail.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        rail.subtitle!,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTokens.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  if (rail.eventIds.isNotEmpty) {
                    context.goNamed('liveEvents');
                  } else {
                    context.goNamed('movies');
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: AppTokens.primaryRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTokens.primaryRed, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: rail.movieIds.isNotEmpty ? 272 : 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              if (rail.movieIds.isNotEmpty)
                ...rail.movieIds.map((id) {
                  final m = catalog.movieById(id);
                  if (m == null) return const SizedBox.shrink();
                  return _MoviePosterTile(movie: m);
                }),
              if (rail.eventIds.isNotEmpty)
                ...rail.eventIds.map((id) {
                  final e = catalog.eventById(id);
                  if (e == null) return const SizedBox.shrink();
                  return _EventTile(event: e, catalog: catalog);
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoviePosterTile extends StatelessWidget {
  const _MoviePosterTile({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: SizedBox(
        width: 132,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            onTap: () => context.push('/movie/${movie.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CatalogImage(
                    url: movie.posterRef,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                ),
                const SizedBox(height: 8),
                if (movie.ratingCount > 0)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          movie.engagementUsesLikes ? Icons.thumb_up_alt_rounded : Icons.star_rounded,
                          size: 15,
                          color: movie.engagementUsesLikes ? AppTokens.likeGreen : AppTokens.primaryRed,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: movie.engagementUsesLikes ? _kLikesLineColor : AppTokens.textSecondary,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                            children: [
                              if (!movie.engagementUsesLikes)
                                TextSpan(
                                  text: '${movie.rating} ',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF424242)),
                                ),
                              TextSpan(
                                text: movie.engagementUsesLikes
                                    ? '${Movie.formatCountShort(movie.ratingCount)}+ likes'
                                    : '${Movie.formatCountShort(movie.ratingCount)}+ votes',
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.2,
                        color: const Color(0xFF212121),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.catalog});

  final LiveEvent event;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final venue = catalog.venueById(event.venueId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 200,
        child: Material(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          child: InkWell(
            onTap: () => context.push('/event/${event.id}'),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CatalogImage(url: event.imageRef),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(event.dateLabel, style: Theme.of(context).textTheme.labelSmall),
                        if (venue != null)
                          Text(
                            venue.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
