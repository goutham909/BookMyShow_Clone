import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/catalog_image.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(catalogProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (catalog) {
        final event = catalog.eventById(eventId);
        if (event == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Event not found.')),
          );
        }
        final venue = catalog.venueById(event.venueId);
        final navTitle = event.appBarTitle ?? event.title;
        final tags = event.eventTags.isNotEmpty ? event.eventTags : [event.category];
        final fromPrice = event.priceFrom.toStringAsFixed(0);

        return Scaffold(
          backgroundColor: AppTokens.canvas,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppTokens.canvas,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              navTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  final link = 'https://showtickets.demo/event/$eventId';
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event link copied (demo).')),
                  );
                },
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: CatalogImage(url: event.imageRef, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTokens.tagNavy,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              t,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTokens.interestedBg,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.thumb_up_alt_rounded, color: AppTokens.likeGreen, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${event.interestedCount} are interested',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mark interested to know more about this event.',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Marked interested (demo).')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTokens.primaryRed,
                            side: const BorderSide(color: AppTokens.primaryRed),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Interested?', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (event.dateLabel.contains('|')) ...[
                        _MetaRow(icon: Icons.calendar_today_outlined, text: event.dateLabel.split('|').first.trim()),
                        _MetaRow(icon: Icons.access_time_rounded, text: event.dateLabel.split('|').last.trim()),
                      ] else
                        _MetaRow(icon: Icons.calendar_today_outlined, text: event.dateLabel),
                      if (event.durationLabel != null)
                        _MetaRow(icon: Icons.hourglass_top_outlined, text: event.durationLabel!),
                      if (event.ageGroup != null)
                        _MetaRow(icon: Icons.groups_2_outlined, text: event.ageGroup!),
                      if (event.languageLabel != null)
                        _MetaRow(icon: Icons.translate_rounded, text: event.languageLabel!),
                      if (event.showTypeLabel != null)
                        _MetaRow(icon: Icons.theater_comedy_outlined, text: event.showTypeLabel!),
                      _MetaRow(
                        icon: Icons.location_on_outlined,
                        text: venue?.name ?? '',
                        trailing: Icon(Icons.navigation_rounded, size: 20, color: AppTokens.trendingBlue),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
                  child: Container(
                    width: double.infinity,
                    color: AppTokens.infoBarCream,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bookings are filling fast for ${catalog.cityLabel}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Offers For You',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 88,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _OfferStrip(
                              title: 'Unlock ₹500 off on LIVE gigs',
                              subtitle: 'With PLAY credit card',
                              borderDark: true,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('PLAY card offer — demo only.')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTokens.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹$fromPrice onwards',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (event.fillingFast)
                            Text(
                              'Filling Fast',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTokens.fastFilling,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTokens.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => context.push('/event/$eventId/tickets'),
                      child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text, this.trailing});

  final IconData icon;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppTokens.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          if (trailing case final t?) t,
        ],
      ),
    );
  }
}

class _OfferStrip extends StatelessWidget {
  const _OfferStrip({
    required this.title,
    required this.subtitle,
    this.borderDark = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool borderDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Container(
          width: 260,
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: borderDark ? Colors.black : AppTokens.divider, width: borderDark ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary)),
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
