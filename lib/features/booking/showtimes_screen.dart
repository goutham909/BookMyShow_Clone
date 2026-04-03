import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../data/models/catalog_models.dart';
import '../../providers/providers.dart';

String _formatTime12(String time24) {
  final parts = time24.split(':');
  var h = int.tryParse(parts[0]) ?? 0;
  final m = parts.length > 1 ? parts[1] : '00';
  final isPm = h >= 12;
  if (h > 12) h -= 12;
  if (h == 0) h = 12;
  return '$h:$m ${isPm ? 'PM' : 'AM'}';
}

String _formatDurationShort(int mins) {
  final h = mins ~/ 60;
  final m = mins % 60;
  if (h <= 0) return '${m}m';
  return '${h}h ${m}m';
}

class ShowtimesScreen extends ConsumerStatefulWidget {
  const ShowtimesScreen({super.key, required this.movieId});

  final String movieId;

  @override
  ConsumerState<ShowtimesScreen> createState() => _ShowtimesScreenState();
}

class _ShowtimesScreenState extends ConsumerState<ShowtimesScreen> {
  int _dateIndex = 0;

  static const _weekday = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _month = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

  List<DateTime> _demoDates() {
    final base = DateTime(2026, 4, 2);
    return List.generate(6, (i) => base.add(Duration(days: i)));
  }

  Future<void> _pickSeatsThenNavigate(
    BuildContext context,
    String movieId,
    Showtime st,
    Movie movie,
  ) async {
    final n = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HowManySeatsSheet(movieTitle: movie.title),
    );
    if (!context.mounted || n == null) return;
    context.push('/movie/$movieId/showtimes/${st.id}/seats?n=$n');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(catalogProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (catalog) {
        final movie = catalog.movieById(widget.movieId);
        if (movie == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Movie not found.')));
        }
        final times = catalog.showtimesForMovie(widget.movieId);
        if (times.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Showtimes')),
            body: const Center(child: Text('No showtimes in the demo catalog.')),
          );
        }

        final byVenue = <String, List<Showtime>>{};
        for (final s in times) {
          byVenue.putIfAbsent(s.venueId, () => []).add(s);
        }

        final dates = _demoDates();
        final langBits = movie.languages.split(',').first.trim();
        final fmt = movie.formatsLine?.split(',').first.trim() ?? '2D';

        return Scaffold(
          backgroundColor: AppTokens.canvas,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  'Movie runtime: ${_formatDurationShort(movie.durationMins)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => context.pushNamed('search')),
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (ctx) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Refine showtimes',
                              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: const Icon(Icons.sort_rounded),
                              title: const Text('Sort by distance'),
                              onTap: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sorted by nearest cinema (demo).')),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.closed_caption_off_outlined),
                              title: const Text('Hide sold out'),
                              onTap: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sold-out slots hidden where applicable (demo).')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: dates.length,
                  itemBuilder: (context, i) {
                    final d = dates[i];
                    final sel = i == _dateIndex;
                    final w = _weekday[d.weekday - 1];
                    final mon = _month[d.month - 1];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _dateIndex = i),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 88,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppTokens.primaryRed : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? AppTokens.primaryRed : AppTokens.divider),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${d.day.toString().padLeft(2, '0')} $w',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: sel ? Colors.white : const Color(0xFF212121),
                                ),
                              ),
                              Text(
                                mon,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: sel ? Colors.white70 : AppTokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$langBits • $fmt',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final parts = movie.languages
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                        showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Language & format',
                                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                for (final lang in parts)
                                  ListTile(
                                    title: Text(lang),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Demo: locked to $langBits · $fmt for this flow.')),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Text('Change >', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.tune_rounded, color: AppTokens.primaryRed, size: 22),
                    ),
                    _PriceChip(
                      label: 'Sort by ▾',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sort: nearest / price (demo).')),
                        );
                      },
                    ),
                    _PriceChip(
                      label: 'Special Formats ▾',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('IMAX · 4DX · ScreenX — filter is demo only.')),
                        );
                      },
                    ),
                    _PriceChip(
                      label: '₹0 - ₹100',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Price band filter (demo).')),
                        );
                      },
                    ),
                    _PriceChip(
                      label: '₹100 - ₹200',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Price band filter (demo).')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    _FavouriteTooltip(),
                    const SizedBox(height: 8),
                    ...byVenue.entries.map((e) {
                      final venue = catalog.venueById(e.key);
                      final name = venue?.name ?? 'Venue';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _CinemaShowtimeCard(
                          name: name,
                          logoUrl: venue?.logoRef,
                          nonCancellable: venue?.nonCancellable ?? false,
                          visited: e.value.any((s) => s.visitedHint),
                          showtimes: e.value,
                          onPickShowtime: (st) => _pickSeatsThenNavigate(context, widget.movieId, st, movie),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.primaryRed,
          side: const BorderSide(color: AppTokens.primaryRed),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}

class _FavouriteTooltip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTokens.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Mark Favourite Cinemas by tapping on the ♡',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Icon(Icons.close_rounded, size: 18, color: AppTokens.textSecondary),
        ],
      ),
    );
  }
}

class _CinemaShowtimeCard extends StatelessWidget {
  const _CinemaShowtimeCard({
    required this.name,
    required this.showtimes,
    required this.onPickShowtime,
    this.logoUrl,
    this.nonCancellable = false,
    this.visited = false,
  });

  final String name;
  final String? logoUrl;
  final bool nonCancellable;
  final bool visited;
  final List<Showtime> showtimes;
  final void Function(Showtime st) onPickShowtime;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: logoUrl != null
                        ? Image.network(logoUrl!, fit: BoxFit.cover)
                        : Container(
                            color: AppTokens.surfaceMuted,
                            alignment: Alignment.center,
                            child: const Icon(Icons.theaters_outlined),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Icon(Icons.info_outline_rounded, size: 18, color: AppTokens.textSecondary),
                          const SizedBox(width: 8),
                          Icon(Icons.favorite_border_rounded, size: 20, color: AppTokens.textSecondary),
                        ],
                      ),
                      if (visited)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Visited',
                              style: TextStyle(
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      if (nonCancellable)
                        Text(
                          'Non-cancellable',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: showtimes.map((st) => _ShowtimeChip(st: st, onTap: () => onPickShowtime(st))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowtimeChip extends StatelessWidget {
  const _ShowtimeChip({required this.st, required this.onTap});

  final Showtime st;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color border = AppTokens.divider;
    var width = 1.0;
    if (st.visualTier == 'gold') {
      border = const Color(0xFFFFC107);
      width = 2;
    } else if (st.visualTier == 'green') {
      border = AppTokens.seatAvailableGreen;
      width = 2;
    }

    final time = _formatTime12(st.time24);
    final sub = st.screenLabel ?? st.format;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: width),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Text(
                  time,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
            if (st.visualTier == 'green')
              const Positioned(
                right: -2,
                top: -6,
                child: Icon(Icons.nightlight_round, size: 16, color: Color(0xFF9E9E9E)),
              ),
          ],
        ),
      ),
    );
  }
}

class _HowManySeatsSheet extends StatefulWidget {
  const _HowManySeatsSheet({required this.movieTitle});

  final String movieTitle;

  @override
  State<_HowManySeatsSheet> createState() => _HowManySeatsSheetState();
}

class _HowManySeatsSheetState extends State<_HowManySeatsSheet> {
  int _count = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTokens.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'How many seats?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text('🛵', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final n = i + 1;
                final sel = n == _count;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: InkWell(
                    onTap: () => setState(() => _count = n),
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: sel ? AppTokens.accentPink : Colors.transparent,
                      child: Text(
                        '$n',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : const Color(0xFF212121),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: _SeatClassRow(
                    label: 'RECLINER ROWS',
                    price: '₹450',
                    status: 'SOLD OUT',
                    statusColor: AppTokens.textSecondary,
                  ),
                ),
                Expanded(
                  child: _SeatClassRow(
                    label: 'PRIME ROWS',
                    price: '₹350',
                    status: 'ALMOST FULL',
                    statusColor: AppTokens.nearlyFullYellow,
                  ),
                ),
              ],
            ),
            Center(
              child: _SeatClassRow(
                label: 'LOUNGERS ROWS',
                price: '₹350',
                status: 'FILLING FAST',
                statusColor: AppTokens.nearlyFullYellow,
                compact: true,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.labelSmall,
                  children: const [
                    TextSpan(text: 'Book the '),
                    TextSpan(text: '■', style: TextStyle(color: Color(0xFFFDD835))),
                    TextSpan(text: ' Bestseller Seats in this cinema at no extra cost!'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.accentPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(context).pop(_count),
                child: const Text('Select Seats', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatClassRow extends StatelessWidget {
  const _SeatClassRow({
    required this.label,
    required this.price,
    required this.status,
    required this.statusColor,
    this.compact = false,
  });

  final String label;
  final String price;
  final String status;
  final Color statusColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text(price, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          Text(
            status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
