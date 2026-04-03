import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../data/models/catalog_models.dart';
import '../../providers/providers.dart';
import '../../widgets/catalog_image.dart';

class MovieDetailScreen extends ConsumerWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(catalogProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (catalog) {
        final movie = catalog.movieById(movieId);
        if (movie == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Movie not found (demo catalog).')),
          );
        }
        return _MovieDetailBody(catalog: catalog, movie: movie);
      },
    );
  }
}

class _MovieDetailBody extends StatefulWidget {
  const _MovieDetailBody({required this.catalog, required this.movie});

  final Catalog catalog;
  final Movie movie;

  @override
  State<_MovieDetailBody> createState() => _MovieDetailBodyState();
}

class _MovieDetailBodyState extends State<_MovieDetailBody> {
  bool _synopsisExpanded = false;

  Movie get movie => widget.movie;
  Catalog get catalog => widget.catalog;

  @override
  Widget build(BuildContext context) {
    final hasShowtimes = catalog.showtimesForMovie(movie.id).isNotEmpty;
    final release = movie.releaseDateLabel ?? 'In cinemas · check showtimes';
    final formats = movie.formatsLine ?? (movie.tags.isNotEmpty ? movie.tags.join(', ') : '2D');

    return Scaffold(
      backgroundColor: AppTokens.canvas,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              movie.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  final link = 'https://showtickets.demo/movie/${movie.id}';
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard (demo).')),
                  );
                },
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CatalogImage(url: movie.heroRef, fit: BoxFit.cover),
                      Center(
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Demo: trailer player not included.')),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                                  const SizedBox(width: 8),
                                  Text(
                                    movie.trailerCount > 1
                                        ? 'Trailers (${movie.trailerCount})'
                                        : 'Trailer',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: double.infinity,
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: Text(
                            release,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (movie.ratingCount > 0)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTokens.interestedBg,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: AppTokens.divider.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up_alt_rounded, color: AppTokens.likeGreen, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${Movie.formatCountShort(movie.ratingCount)}+ are interested',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Are you interested in watching this movie?',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You are interested — we will remind you (demo).')),
                              );
                            },
                            child: const Text("I'm interested"),
                          ),
                        ],
                      ),
                    ),
                  if (movie.ratingCount > 0) const SizedBox(height: 14),
                  Text(
                    '${_formatDuration(movie.durationMins)} · ${movie.genre} · ${movie.certification}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTokens.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  _GreyChipRow(label: formats),
                  const SizedBox(height: 8),
                  _GreyChipRow(label: movie.languages),
                  const SizedBox(height: 16),
                  _SynopsisBlock(
                    text: movie.synopsis,
                    expanded: _synopsisExpanded,
                    onToggle: () => setState(() => _synopsisExpanded = !_synopsisExpanded),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: AppTokens.trendingBlue.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTokens.trendingBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Trending',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            movie.trendingTicketsLine ??
                                '${(8 + movie.id.hashCode % 12)}.${movie.id.hashCode % 10}K tickets booked in last 24 hours',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppTokens.likeGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Top offers for you',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 82,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _BmsOfferCard(
                          title: 'Get 15% off on all Movies',
                          subtitle: 'Tap to view details',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('15% off movies — apply at checkout (demo).')),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Material(
                            color: const Color(0xFFFFFDE7),
                            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                            child: InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('YES BANK partner offer — demo only.')),
                                );
                              },
                              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                              child: Container(
                                width: 140,
                                padding: const EdgeInsets.all(12),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: AppTokens.primaryRed, size: 28),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'YES BANK',
                                        style: TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cast',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 118,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: movie.cast.isEmpty
                          ? const [
                              _CastAvatar(name: 'Lead'),
                              _CastAvatar(name: 'Co-star'),
                              _CastAvatar(name: 'Director'),
                            ]
                          : movie.cast
                              .map((c) => _CastMemberTile(member: c))
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 88),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: hasShowtimes
                  ? () => _openBookTickets(context)
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Showtimes not listed for this title yet.')),
                      );
                    },
              child: Text(hasShowtimes ? 'Book tickets' : 'Notify me'),
            ),
          ),
        ),
      ),
    );
  }

  void _openBookTickets(BuildContext context) {
    var formats = List<String>.from(movie.formatOptions);
    if (formats.isEmpty && movie.formatsLine != null) {
      formats = movie.formatsLine!
          .split(RegExp(r'\s*,\s*'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !e.startsWith('+'))
          .toList();
    }
    if (formats.isEmpty) formats = ['2D'];
    final lang = movie.languages.split(',').first.trim().toUpperCase();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FormatBottomSheet(
        movieTitle: movie.title,
        languageLabel: lang,
        formats: formats,
        onContinue: () {
          Navigator.of(ctx).pop();
          context.push('/movie/${movie.id}/showtimes');
        },
      ),
    );
  }

  static String _formatDuration(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h <= 0) return '${m}m';
    return '${h}h ${m}m';
  }
}

class _GreyChipRow extends StatelessWidget {
  const _GreyChipRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SynopsisBlock extends StatelessWidget {
  const _SynopsisBlock({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    const maxChars = 120;
    final showMore = text.length > maxChars;
    final display = expanded || !showMore ? text : '${text.substring(0, maxChars).trim()}…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          display,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        if (showMore)
          TextButton(
            onPressed: onToggle,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              expanded ? 'Read less' : 'Read more',
              style: TextStyle(color: AppTokens.primaryRed, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _BmsOfferCard extends StatelessWidget {
  const _BmsOfferCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          child: Container(
            width: 240,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: Colors.black87, width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 30),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                      Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary)),
                    ],
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

class _FormatBottomSheet extends StatefulWidget {
  const _FormatBottomSheet({
    required this.movieTitle,
    required this.languageLabel,
    required this.formats,
    required this.onContinue,
  });

  final String movieTitle;
  final String languageLabel;
  final List<String> formats;
  final VoidCallback onContinue;

  @override
  State<_FormatBottomSheet> createState() => _FormatBottomSheetState();
}

class _FormatBottomSheetState extends State<_FormatBottomSheet> {
  late int _selected = widget.formats.length > 1 ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.movieTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTokens.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Select language and format',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.languageLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTokens.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(widget.formats.length, (i) {
                final f = widget.formats[i];
                final sel = i == _selected;
                return InkWell(
                  onTap: () => setState(() => _selected = i),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: sel ? AppTokens.primaryRed : AppTokens.divider,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: sel ? AppTokens.primaryRed : const Color(0xFF212121),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: widget.onContinue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CastMemberTile extends StatelessWidget {
  const _CastMemberTile({required this.member});

  final CastMember member;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CatalogImage(
              url: member.imageRef,
              borderRadius: BorderRadius.circular(12),
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 84,
            child: Text(
              member.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CastAvatar extends StatelessWidget {
  const _CastAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTokens.surfaceMuted,
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF424242)),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
