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
  return '$h:${m.padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}';
}

class SeatSelectionScreen extends ConsumerStatefulWidget {
  const SeatSelectionScreen({
    super.key,
    required this.movieId,
    required this.showtimeId,
    this.seatCount = 2,
  });

  final String movieId;
  final String showtimeId;
  final int seatCount;

  @override
  ConsumerState<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends ConsumerState<SeatSelectionScreen> {
  final Set<String> _selected = {};

  static const _rows = 10;
  static const _cols = 12;

  late final int _maxSeats;

  @override
  void initState() {
    super.initState();
    _maxSeats = widget.seatCount.clamp(1, 6);
  }

  bool _isTaken(int row, int col) {
    final h = widget.showtimeId.hashCode ^ (row * 31 + col) * 17;
    return h % 5 == 0;
  }

  bool _isAvailableOutline(int row, int col) {
    if (_isTaken(row, col)) return false;
    final h = (row + 1) * 13 + col;
    return h % 4 != 0;
  }

  String _id(int row, int col) => '${String.fromCharCode(65 + row)}${col + 1}';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(catalogProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (catalog) {
        final movie = catalog.movieById(widget.movieId);
        final showtimes = catalog.showtimesForMovie(widget.movieId);
        Showtime? st;
        for (final s in showtimes) {
          if (s.id == widget.showtimeId) {
            st = s;
            break;
          }
        }
        if (movie == null || st == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Showtime not found.')),
          );
        }
        final venue = catalog.venueById(st.venueId);
        final venueName = venue?.name ?? 'Cinema';
        final showLabel = st.screenLabel ?? st.format;
        final timeLabel = _formatTime12(st.time24);

        final unit = st.priceFrom;
        final fees = 28.0;
        final total = _selected.isEmpty ? 0.0 : (_selected.length * unit) + fees;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F5F5),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                Text(
                  venueName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTokens.textSecondary),
                ),
              ],
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Thu, 02 Apr',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_outlined, size: 18, color: AppTokens.accentPink),
                    const SizedBox(width: 4),
                    Text(
                      '$_maxSeats Tickets',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTokens.accentPink,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTokens.showtimeGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        timeLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        showLabel,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    children: List.generate(_rows, (r) {
                      final rowLetter = String.fromCharCode(65 + (_rows - 1 - r));
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(
                                rowLetter,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppTokens.textSecondary,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 4,
                                runSpacing: 4,
                                children: List.generate(_cols, (c) {
                                  final id = _id(_rows - 1 - r, c);
                                  final taken = _isTaken(_rows - 1 - r, c);
                                  final availableLook = _isAvailableOutline(_rows - 1 - r, c);
                                  final sel = _selected.contains(id);
                                  if (taken) {
                                    return _SeatCell(
                                      label: '${c + 1}',
                                      sold: true,
                                      selected: false,
                                      availableOutline: false,
                                      onTap: null,
                                    );
                                  }
                                  return _SeatCell(
                                    label: '${c + 1}',
                                    sold: false,
                                    selected: sel,
                                    availableOutline: availableLook && !sel,
                                    onTap: () {
                                      setState(() {
                                        if (sel) {
                                          _selected.remove(id);
                                        } else if (_selected.length < _maxSeats) {
                                          _selected.add(id);
                                        }
                                      });
                                    },
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Column(
                children: [
                  CustomPaint(
                    painter: _ScreenPainter(),
                    child: const SizedBox(width: double.infinity, height: 44),
                  ),
                  Text(
                    'All eyes this way please!',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTokens.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _LegendItem(color: Color(0xFFFDD835), label: 'Bestseller', icon: Icons.info_outline_rounded),
                    _LegendItem(color: AppTokens.seatAvailableGreen, label: 'Available', outlined: true),
                    _LegendItem(color: AppTokens.seatAvailableGreen, label: 'Selected'),
                    _LegendItem(color: AppTokens.seatSoldGrey, label: 'Sold'),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
                  ),
                ),
                child: Row(
                  children: [
                    const Text('★', style: TextStyle(fontSize: 20, color: Color(0xFFD32F2F))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add Club membership at ₹179 for 60 days and get instant 15% off',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Club membership added to cart (demo).')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTokens.primaryRed,
                        side: const BorderSide(color: AppTokens.primaryRed),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text('Add Club', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                              Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selected.isEmpty ? 'Select up to $_maxSeats seats' : '${_selected.length} seats',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              _selected.isEmpty ? '—' : '₹${total.toStringAsFixed(0)} incl. fees',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppTokens.accentPink),
                        onPressed: _selected.isEmpty
                            ? null
                            : () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirm demo booking'),
                                    content: Text(
                                      '${movie.title}\n$venueName · $showLabel\nSeats: ${_selected.join(", ")}',
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
                                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pay')),
                                    ],
                                  ),
                                );
                                if (ok == true && context.mounted) {
                                  await ref.read(bookingsProvider.notifier).add(
                                        SavedBooking(
                                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                                          movieTitle: movie.title,
                                          venueName: venueName,
                                          showLabel: '$showLabel · $timeLabel',
                                          seats: _selected.toList()..sort(),
                                          totalInr: total,
                                          placedAtIso: DateTime.now().toIso8601String(),
                                        ),
                                      );
                                  if (context.mounted) context.pushNamed('myTickets');
                                }
                              },
                        child: const Text('Pay'),
                      ),
                    ],
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

class _SeatCell extends StatelessWidget {
  const _SeatCell({
    required this.label,
    required this.sold,
    required this.selected,
    required this.availableOutline,
    required this.onTap,
  });

  final String label;
  final bool sold;
  final bool selected;
  final bool availableOutline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    if (sold) {
      bg = AppTokens.seatSoldGrey;
    } else if (selected) {
      bg = AppTokens.seatAvailableGreen;
    } else {
      bg = Colors.white;
    }
    final border = (!sold && availableOutline && !selected)
        ? Border.all(color: AppTokens.seatAvailableGreen, width: 1.5)
        : null;
    final fg = (sold || selected) ? Colors.white : const Color(0xFF424242);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: border,
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.icon,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(3),
            border: outlined ? Border.all(color: color, width: 2) : null,
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: 2),
          Icon(icon, size: 14, color: AppTokens.textSecondary),
        ],
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFBBDEFB);
    final path = Path()
      ..moveTo(size.width * 0.1, 0)
      ..lineTo(size.width * 0.9, 0)
      ..lineTo(size.width * 0.78, size.height)
      ..lineTo(size.width * 0.22, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
