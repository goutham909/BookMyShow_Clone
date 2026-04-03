import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../data/models/catalog_models.dart';
import '../../providers/providers.dart';
import '../../widgets/catalog_image.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  static const _filters = ['New Releases', 'Re-releases', 'English', 'Hindi', 'IMAX'];

  final Set<String> _activeFilters = {};
  bool _comingSoonOnly = false;

  List<Movie> _filteredMovies(Catalog catalog) {
    var list = List<Movie>.from(catalog.movies);
    if (_comingSoonOnly) {
      list = list.where((m) => m.ratingCount == 0).toList();
    }
    for (final f in _activeFilters) {
      switch (f) {
        case 'New Releases':
          list = list.where((m) => m.ratingCount > 0).toList();
          break;
        case 'Re-releases':
          final sub = list
              .where(
                (m) =>
                    m.tags.any((t) => t.toLowerCase().contains('re-release')) ||
                    m.title.toLowerCase().contains('re-release'),
              )
              .toList();
          list = sub.isNotEmpty ? sub : list;
          break;
        case 'English':
          list = list.where((m) => m.languages.toLowerCase().contains('english')).toList();
          break;
        case 'Hindi':
          list = list.where((m) => m.languages.toLowerCase().contains('hindi')).toList();
          break;
        case 'IMAX':
          list = list
              .where(
                (m) =>
                    (m.formatsLine?.toLowerCase().contains('imax') ?? false) ||
                    m.tags.any((t) => t.toLowerCase().contains('imax')),
              )
              .toList();
          break;
      }
    }
    return list;
  }

  void _openFilterSheet(Catalog catalog) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filters',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filters.map((f) {
                  final sel = _activeFilters.contains(f);
                  return FilterChip(
                    label: Text(f),
                    selected: sel,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _activeFilters.add(f);
                        } else {
                          _activeFilters.remove(f);
                        }
                      });
                    },
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: AppTokens.accentPink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: const BorderSide(color: AppTokens.accentPink),
                    selectedColor: AppTokens.accentPink.withValues(alpha: 0.12),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(catalogProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (catalog) {
        final promo = catalog.movies.isNotEmpty ? catalog.movies.first : null;
        final movies = _filteredMovies(catalog);
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Now Showing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${catalog.cityLabel} | ${catalog.movies.length} Movies',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTokens.textSecondary),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => context.pushNamed('search'),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 72),
            child: FloatingActionButton.extended(
              heroTag: 'browse_cinemas',
              backgroundColor: AppTokens.accentPink,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 48, color: AppTokens.primaryRed.withValues(alpha: 0.7)),
                        const SizedBox(height: 12),
                        Text(
                          'Browse by cinemas',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Demo: open a movie, then pick a cinema from showtimes — map view is not in this build.',
                          textAlign: TextAlign.center,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppTokens.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.pushNamed('search');
                          },
                          child: const Text('Search cinemas'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Browse by Cinemas'),
            ),
          ),
          body: CustomScrollView(
            primary: false,
            slivers: [
              if (promo != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _StreamPromoCard(movie: promo),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: () => _openFilterSheet(catalog),
                          icon: const Icon(Icons.tune_rounded, size: 22, color: AppTokens.primaryRed),
                        ),
                      ),
                      ..._filters.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f),
                            selected: _activeFilters.contains(f),
                            onSelected: (v) => setState(() {
                              if (v) {
                                _activeFilters.add(f);
                              } else {
                                _activeFilters.remove(f);
                              }
                            }),
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: AppTokens.accentPink,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            side: const BorderSide(color: AppTokens.accentPink),
                            backgroundColor: Colors.white,
                            selectedColor: AppTokens.accentPink.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Material(
                    color: AppTokens.accentPink,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      onTap: () {
                        setState(() => _comingSoonOnly = !_comingSoonOnly);
                        final n = catalog.movies.where((m) => m.ratingCount == 0).length;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _comingSoonOnly
                                  ? 'Showing $n upcoming titles'
                                  : 'Showing all ${_filteredMovies(catalog).length} titles',
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Coming Soon',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  Text(
                                    'Explore Upcoming Movies',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                sliver: movies.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No movies match these filters.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTokens.textSecondary),
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.48,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final m = movies[index];
                            return _MovieGridTile(movie: m);
                          },
                          childCount: movies.length,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StreamPromoCard extends StatelessWidget {
  const _StreamPromoCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: Colors.black12,
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'STREAM',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The gates of the temple are now open!',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => context.push('/movie/${movie.id}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTokens.accentPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Buy/Rent Online', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: CatalogImage(url: movie.posterRef, fit: BoxFit.cover),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieGridTile extends StatelessWidget {
  const _MovieGridTile({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/movie/${movie.id}'),
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CatalogImage(
              url: movie.posterRef,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            ),
          ),
          const SizedBox(height: 8),
          if (movie.ratingCount > 0)
            Row(
              children: [
                Icon(
                  movie.engagementUsesLikes ? Icons.thumb_up_alt_rounded : Icons.star_rounded,
                  size: 14,
                  color: movie.engagementUsesLikes ? AppTokens.likeGreen : AppTokens.primaryRed,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    movie.engagementUsesLikes
                        ? '${Movie.formatCountShort(movie.ratingCount)}+ likes'
                        : '${movie.rating} · ${Movie.formatCountShort(movie.ratingCount)}+',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
                  ),
                ),
              ],
            )
          else
            Text(
              'Coming soon',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
            ),
          const SizedBox(height: 4),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
