import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../data/models/catalog_models.dart';
import '../../providers/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery, this.scope, this.initialPill});

  final String? initialQuery;
  final String? scope;
  /// Matches index in [_pills] when provided (e.g. from explore tabs deep link).
  final int? initialPill;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery ?? '');
  String _q = '';
  int _pillIndex = 0;

  static const _pills = ['Movies', 'STREAM', 'Events', 'Plays'];

  @override
  void initState() {
    super.initState();
    if (widget.scope == 'events') {
      _pillIndex = 2;
    } else if (widget.initialPill != null &&
        widget.initialPill! >= 0 &&
        widget.initialPill! < _pills.length) {
      _pillIndex = widget.initialPill!;
    }
    _q = _controller.text.trim().toLowerCase();
    _controller.addListener(() {
      setState(() => _q = _controller.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(catalogProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (catalog) {
        var movies = catalog.movies;
        var events = catalog.events;
        if (_q.isNotEmpty) {
          movies = _filterMovies(movies, _q);
          events = _filterEvents(events, _q);
        }

        final rows = <_SearchRow>[];
        if (_pillIndex == 0 || _pillIndex == 1) {
          final list = _q.isEmpty ? movies.take(8) : movies;
          rows.addAll(list.map((m) => _SearchRow.movie(m)));
        }
        if (_pillIndex == 2 || _pillIndex == 3) {
          final list = _q.isEmpty ? events.take(8) : events;
          rows.addAll(list.map((e) => _SearchRow.event(e)));
        }

        final searching = _q.isNotEmpty;
        final accent = AppTokens.primaryRedDark;

        return Scaffold(
          backgroundColor: AppTokens.canvasSearch,
          appBar: AppBar(
            backgroundColor: AppTokens.canvasSearch,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTokens.searchFill,
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: widget.initialQuery == null || widget.initialQuery!.isEmpty,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: searching ? null : 'Search for movies, events, plays, sports…',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTokens.textSecondary),
                  ),
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  itemCount: _pills.length,
                  itemBuilder: (context, i) {
                    final sel = i == _pillIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_pills[i]),
                        selected: sel,
                        onSelected: (_) => setState(() => _pillIndex = i),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: sel ? accent : AppTokens.divider, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  },
                ),
              ),
              if (!searching) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3ECEF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Popular/Trending Results',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: searching
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          elevation: 1,
                          shadowColor: Colors.black12,
                          child: Column(
                            children: [
                              Expanded(
                                child: rows.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No matches for “$_q”',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: AppTokens.textSecondary,
                                              ),
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: EdgeInsets.zero,
                                        itemCount: rows.length,
                                        separatorBuilder: (_, unused) => const Divider(height: 1, thickness: 1),
                                        itemBuilder: (context, i) {
                                          final r = rows[i];
                                          return ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                            title: Text(
                                              r.title,
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            subtitle: Text(
                                              r.isEvent ? '📅 Event' : '🎬 In movies | ${r.subtitleTag}',
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: AppTokens.textSecondary,
                                                  ),
                                            ),
                                            onTap: () {
                                              if (r.isEvent) {
                                                context.push('/event/${r.eventId}');
                                              } else {
                                                context.push('/movie/${r.movieId}');
                                              }
                                            },
                                          );
                                        },
                                      ),
                              ),
                              if (rows.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  child: OutlinedButton(
                                    onPressed: () {
                                      if (_pillIndex == 2 || _pillIndex == 3) {
                                        context.goNamed('liveEvents');
                                      } else {
                                        context.goNamed('movies');
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: accent,
                                      side: BorderSide(color: accent),
                                      minimumSize: const Size.fromHeight(48),
                                      shape: const StadiumBorder(),
                                    ),
                                    child: const Text('View All Results', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, unused) =>
                              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                          itemBuilder: (context, i) {
                            final r = rows[i];
                            return ListTile(
                              title: Text(
                                r.title,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              trailing: Icon(
                                r.isEvent ? Icons.event_outlined : Icons.movie_creation_outlined,
                                color: AppTokens.textSecondary,
                              ),
                              onTap: () {
                                if (r.isEvent) {
                                  context.push('/event/${r.eventId}');
                                } else {
                                  context.push('/movie/${r.movieId}');
                                }
                              },
                            );
                          },
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

List<Movie> _filterMovies(List<Movie> all, String q) {
  if (q.isEmpty) return all;
  return all
      .where((m) => m.title.toLowerCase().contains(q) || m.genre.toLowerCase().contains(q))
      .toList();
}

List<LiveEvent> _filterEvents(List<LiveEvent> all, String q) {
  if (q.isEmpty) return all;
  return all
      .where((e) => e.title.toLowerCase().contains(q) || e.category.toLowerCase().contains(q))
      .toList();
}

class _SearchRow {
  _SearchRow._({
    required this.title,
    required this.isEvent,
    this.movieId,
    this.eventId,
    this.subtitleTag = '',
  });

  factory _SearchRow.movie(Movie m) => _SearchRow._(
        title: m.title,
        isEvent: false,
        movieId: m.id,
        subtitleTag: 'Upcoming Movie',
      );

  factory _SearchRow.event(LiveEvent e) => _SearchRow._(
        title: e.title,
        isEvent: true,
        eventId: e.id,
        subtitleTag: e.category,
      );

  final String title;
  final bool isEvent;
  final String? movieId;
  final String? eventId;
  final String subtitleTag;
}
