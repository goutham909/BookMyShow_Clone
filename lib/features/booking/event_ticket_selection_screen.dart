import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../data/models/catalog_models.dart';
import '../../providers/providers.dart';

class EventTicketSelectionScreen extends ConsumerStatefulWidget {
  const EventTicketSelectionScreen({super.key, required this.eventId});

  final String eventId;

  static String formatInr(double n) {
    final v = n.round();
    final s = v.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[last3];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return parts.join(',');
  }

  @override
  ConsumerState<EventTicketSelectionScreen> createState() => _EventTicketSelectionScreenState();
}

class _EventTicketSelectionScreenState extends ConsumerState<EventTicketSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _sectionTabController;
  int _reviewStep = 0;
  final Map<String, int> _tierQty = {};
  final Map<String, int> _addonQty = {};

  static const List<(String label, double priceInr)> _addons = [
    ('Official merchandise kit', 349),
    ('Express entry lane', 199),
    ('Venue parking pass', 150),
  ];

  static const int _maxTickets = 10;

  @override
  void initState() {
    super.initState();
    _sectionTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _sectionTabController.dispose();
    super.dispose();
  }

  int get _totalTicketCount => _tierQty.values.fold(0, (a, b) => a + b);

  double _ticketsSubtotal(List<EventTicketTier> tiers) {
    var s = 0.0;
    for (final tier in tiers) {
      final q = _tierQty[tier.name] ?? 0;
      s += q * tier.priceInr;
    }
    return s;
  }

  double _addonsSubtotal() {
    var s = 0.0;
    for (final a in _addons) {
      final q = _addonQty[a.$1] ?? 0;
      s += q * a.$2;
    }
    return s;
  }

  double _convenienceFee(double subtotal) => subtotal > 0 ? 29.0 : 0.0;

  void _bumpTier(String name, int delta) {
    final cur = _tierQty[name] ?? 0;
    final next = cur + delta;
    if (next < 0) return;
    if (delta > 0 && _totalTicketCount >= _maxTickets) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can add up to $_maxTickets tickets only.')),
      );
      return;
    }
    setState(() {
      if (next == 0) {
        _tierQty.remove(name);
      } else {
        _tierQty[name] = next;
      }
    });
  }

  void _bumpAddon(String label, int delta) {
    final cur = _addonQty[label] ?? 0;
    final next = cur + delta;
    if (next < 0) return;
    setState(() {
      if (next == 0) {
        _addonQty.remove(label);
      } else {
        _addonQty[label] = next;
      }
    });
  }

  void _goReview(List<EventTicketTier> tiers) {
    if (_totalTicketCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one ticket to continue.')),
      );
      return;
    }
    setState(() => _reviewStep = 1);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(catalogProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (catalog) {
        final event = catalog.eventById(widget.eventId);
        if (event == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Event not found.')),
          );
        }
        final title = event.appBarTitle ?? event.title;
        final tiers = event.ticketTiers.isNotEmpty
            ? event.ticketTiers
            : [
                EventTicketTier(name: 'GENERAL ADMISSION', priceInr: event.priceFrom, fastFilling: event.fillingFast),
              ];

        final ticketTotal = _ticketsSubtotal(tiers);
        final addonTotal = _addonsSubtotal();
        final subtotal = ticketTotal + addonTotal;
        final fees = _convenienceFee(subtotal);
        final grand = subtotal + fees;

        return Scaffold(
          backgroundColor: AppTokens.canvasMuted,
          appBar: AppBar(
            backgroundColor: AppTokens.canvas,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CheckoutStepper(
                reviewStep: _reviewStep,
                ticketsSelected: _totalTicketCount,
                onTapSelect: () => setState(() => _reviewStep = 0),
                onTapReview: () => _goReview(tiers),
              ),
              Container(
                width: double.infinity,
                color: AppTokens.eventHeaderGrey,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.venueLine ?? catalog.venueById(event.venueId)?.name ?? '',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.dateTimeSubtitle ?? event.dateLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (_reviewStep == 0) ...[
                Material(
                  color: AppTokens.canvas,
                  child: TabBar(
                    controller: _sectionTabController,
                    labelColor: AppTokens.primaryRed,
                    unselectedLabelColor: AppTokens.textSecondary,
                    indicatorColor: AppTokens.primaryRed,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Select tickets'),
                      Tab(text: 'Add-ons'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _sectionTabController,
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          Text(
                            'Choose categories',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Up to $_maxTickets tickets per transaction · taxes may apply at checkout',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTokens.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          ...tiers.map(
                            (t) => _TicketTierQtyCard(
                              tier: t,
                              qty: _tierQty[t.name] ?? 0,
                              formatInr: EventTicketSelectionScreen.formatInr,
                              onDelta: (d) => _bumpTier(t.name, d),
                            ),
                          ),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          Text(
                            'Enhance your visit',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Merchandise, parking & more — same idea as BookMyShow add-ons.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTokens.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ..._addons.map(
                            (a) => _AddonRow(
                              label: a.$1,
                              priceInr: a.$2,
                              qty: _addonQty[a.$1] ?? 0,
                              formatInr: EventTicketSelectionScreen.formatInr,
                              onDelta: (d) => _bumpAddon(a.$1, d),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Text(
                        'Review your order',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      ..._buildReviewLines(tiers, event.title),
                      const SizedBox(height: 12),
                      _ReviewLine(
                        label: 'Convenience fee',
                        value: '₹${EventTicketSelectionScreen.formatInr(fees)}',
                        muted: true,
                      ),
                      const Divider(height: 28),
                      _ReviewLine(
                        label: 'Amount payable',
                        value: '₹${EventTicketSelectionScreen.formatInr(grand)}',
                        emphasize: true,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'By paying you accept the organiser terms. Demo only — no charge.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              _BottomCheckoutBar(
                reviewStep: _reviewStep,
                totalTickets: _totalTicketCount,
                grandTotal: grand,
                formatInr: EventTicketSelectionScreen.formatInr,
                onProceed: () => _goReview(tiers),
                onPay: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Complete demo payment?'),
                      content: Text(
                        '${event.title}\n'
                        'Tickets: $_totalTicketCount · Add-ons · Fees included in total shown.',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pay now')),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking confirmed (demo). Check email in a real app.')),
                    );
                    context.pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildReviewLines(List<EventTicketTier> tiers, String eventTitle) {
    final lines = <Widget>[];
    lines.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          eventTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTokens.textSecondary),
        ),
      ),
    );
    for (final tier in tiers) {
      final q = _tierQty[tier.name] ?? 0;
      if (q < 1) continue;
      lines.add(
        _ReviewLine(
          label: '$q × ${tier.name}',
          value: '₹${EventTicketSelectionScreen.formatInr(q * tier.priceInr)}',
        ),
      );
    }
    for (final a in _addons) {
      final q = _addonQty[a.$1] ?? 0;
      if (q < 1) continue;
      lines.add(
        _ReviewLine(
          label: '$q × ${a.$1}',
          value: '₹${EventTicketSelectionScreen.formatInr(q * a.$2)}',
        ),
      );
    }
    if (lines.length == 1) {
      lines.add(
        Text(
          'No line items — go back to add tickets.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTokens.textSecondary),
        ),
      );
    }
    return lines;
  }
}

class _CheckoutStepper extends StatelessWidget {
  const _CheckoutStepper({
    required this.reviewStep,
    required this.ticketsSelected,
    required this.onTapSelect,
    required this.onTapReview,
  });

  final int reviewStep;
  final int ticketsSelected;
  final VoidCallback onTapSelect;
  final VoidCallback onTapReview;

  @override
  Widget build(BuildContext context) {
    Widget stepCircle(int n, bool active, bool done) {
      final bg = active || done ? Colors.black : const Color(0xFFBDBDBD);
      return Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Text(
          '$n',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
        ),
      );
    }

    Widget stepLabel(String text, bool active) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? Colors.black : AppTokens.textSecondary,
        ),
      );
    }

    final onSelect = reviewStep == 0;
    final onReview = reviewStep == 1;

    return Material(
      color: AppTokens.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTapSelect,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      stepCircle(1, onSelect, ticketsSelected > 0 && reviewStep == 1),
                      const SizedBox(width: 8),
                      Expanded(child: stepLabel('Ticket', onSelect)),
                    ],
                  ),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTokens.textSecondary, size: 20),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onTapReview,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      stepCircle(2, onReview, false),
                      const SizedBox(width: 8),
                      Expanded(child: stepLabel('Review & Proceed to Pay', onReview)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketTierQtyCard extends StatefulWidget {
  const _TicketTierQtyCard({
    required this.tier,
    required this.qty,
    required this.formatInr,
    required this.onDelta,
  });

  final EventTicketTier tier;
  final int qty;
  final String Function(double) formatInr;
  final void Function(int delta) onDelta;

  @override
  State<_TicketTierQtyCard> createState() => _TicketTierQtyCardState();
}

class _TicketTierQtyCardState extends State<_TicketTierQtyCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tier;
    final rose = AppTokens.ticketAccentRose;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      t.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF424242),
                            letterSpacing: 0.2,
                          ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        onPressed: widget.qty > 0 ? () => widget.onDelta(-1) : null,
                        icon: const Icon(Icons.remove_rounded, size: 20),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(40, 40),
                          foregroundColor: rose,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${widget.qty}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => widget.onDelta(1),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(40, 40),
                          foregroundColor: rose,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '₹${widget.formatInr(t.priceInr)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF424242),
                        ),
                  ),
                  if (t.fastFilling) ...[
                    Text(' | ', style: TextStyle(color: AppTokens.textSecondary.withValues(alpha: 0.5))),
                    Text(
                      'Fast Filling',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTokens.fastFilling,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Know more',
                      style: TextStyle(color: rose, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: rose,
                      size: 20,
                    ),
                  ],
                ),
              ),
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Includes entry for this category. Seat or table allocation as per venue rules. '
                    'Non-transferable in a real event.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTokens.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddonRow extends StatelessWidget {
  const _AddonRow({
    required this.label,
    required this.priceInr,
    required this.qty,
    required this.formatInr,
    required this.onDelta,
  });

  final String label;
  final double priceInr;
  final int qty;
  final String Function(double) formatInr;
  final void Function(int delta) onDelta;

  @override
  Widget build(BuildContext context) {
    final rose = AppTokens.ticketAccentRose;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        elevation: 1,
        shadowColor: Colors.black12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '₹${formatInr(priceInr)} each',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: qty > 0 ? () => onDelta(-1) : null,
                icon: const Icon(Icons.remove_rounded, size: 18),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(36, 36),
                  foregroundColor: rose,
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$qty',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => onDelta(1),
                icon: const Icon(Icons.add_rounded, size: 18),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(36, 36),
                  foregroundColor: rose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({
    required this.label,
    required this.value,
    this.muted = false,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool muted;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: muted ? AppTokens.textSecondary : const Color(0xFF212121),
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
                  color: emphasize ? AppTokens.primaryRed : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _BottomCheckoutBar extends StatelessWidget {
  const _BottomCheckoutBar({
    required this.reviewStep,
    required this.totalTickets,
    required this.grandTotal,
    required this.formatInr,
    required this.onProceed,
    required this.onPay,
  });

  final int reviewStep;
  final int totalTickets;
  final double grandTotal;
  final String Function(double) formatInr;
  final VoidCallback onProceed;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (reviewStep == 0)
                      Text(
                        totalTickets > 0 ? '$totalTickets ticket${totalTickets == 1 ? '' : 's'}' : 'Nothing selected',
                        style: Theme.of(context).textTheme.labelLarge,
                      )
                    else
                      Text(
                        'Payable now',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    Text(
                      reviewStep == 0 && totalTickets < 1
                          ? '—'
                          : '₹${formatInr(grandTotal)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
                onPressed: reviewStep == 0
                    ? (totalTickets > 0 ? onProceed : null)
                    : (grandTotal > 0 ? onPay : null),
                child: Text(
                  reviewStep == 0 ? 'Proceed' : 'Pay now',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
