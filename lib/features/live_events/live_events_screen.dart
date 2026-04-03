import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../data/models/catalog_models.dart';
import '../../providers/providers.dart';
import '../../widgets/catalog_image.dart';

class _EventCategory {
  const _EventCategory(this.label, this.imageUrl, this.tabIndex);

  final String label;
  final String imageUrl;
  /// Maps to [LiveEventsScreen] top TabBar index.
  final int tabIndex;
}

List<LiveEvent> liveEventsFilter(List<LiveEvent> all, int tabIndex) {
  if (tabIndex == 0) return List<LiveEvent>.from(all);
  bool match(LiveEvent e) {
    final c = e.category.toLowerCase();
    final t = e.title.toLowerCase();
    final tagStr = e.eventTags.join(' ').toLowerCase();
    switch (tabIndex) {
      case 1:
        return c.contains('music') || t.contains('concert') || tagStr.contains('music');
      case 2:
        return c.contains('comedy') || tagStr.contains('comedy') || t.contains('laugh');
      case 3:
        return c.contains('sport') || t.contains('sport') || tagStr.contains('sport') || t.contains('ipl');
      case 4:
        return c.contains('play') || tagStr.contains('play') || t.contains('play');
      case 5:
        return c.contains('workshop') ||
            c.contains('experience') ||
            tagStr.contains('workshop') ||
            c.contains('activities');
      default:
        return true;
    }
  }
  return all.where(match).toList();
}

class LiveEventsScreen extends ConsumerStatefulWidget {
  const LiveEventsScreen({super.key});

  @override
  ConsumerState<LiveEventsScreen> createState() => _LiveEventsScreenState();
}

class _LiveEventsScreenState extends ConsumerState<LiveEventsScreen> with SingleTickerProviderStateMixin {
  int _carouselIndex = 0;
  late final TabController _categoryTabController;

  static const _categories = <_EventCategory>[
    _EventCategory(
      'Music Shows',
      'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&q=80',
      1,
    ),
    _EventCategory(
      'Comedy Shows',
      'https://images.unsplash.com/photo-1585699324551-f6c309eedeca?w=400&q=80',
      2,
    ),
    _EventCategory(
      'Sports',
      'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400&q=80',
      3,
    ),
    _EventCategory(
      'Workshops',
      'https://images.unsplash.com/photo-1516035069371-29a1b244ccff?w=400&q=80',
      5,
    ),
    _EventCategory(
      'Plays',
      'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=400&q=80',
      4,
    ),
  ];

  static const _tabLabels = ['All', 'Music', 'Comedy', 'Sports', 'Plays', 'Workshops'];

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(length: _tabLabels.length, vsync: this);
    _categoryTabController.addListener(_onCategoryTabChanged);
  }

  void _onCategoryTabChanged() {
    if (!mounted) return;
    setState(() => _carouselIndex = 0);
  }

  @override
  void dispose() {
    _categoryTabController.removeListener(_onCategoryTabChanged);
    _categoryTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(catalogProvider);

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (catalog) {
        final filtered = liveEventsFilter(catalog.events, _categoryTabController.index);

        return Scaffold(
          backgroundColor: AppTokens.canvas,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: AppTokens.canvas,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Events',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _showLiveEventsRegionPicker(context, catalog.cityLabel),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  catalog.cityLabel,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTokens.primaryRed,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppTokens.primaryRed, size: 22),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                context.pushNamed('search', queryParameters: {'scope': 'events'}),
                            icon: const Icon(Icons.search_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Material(
                color: AppTokens.canvas,
                child: TabBar(
                  controller: _categoryTabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  indicatorColor: AppTokens.primaryRed,
                  indicatorWeight: 3,
                  labelColor: AppTokens.primaryRed,
                  unselectedLabelColor: AppTokens.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  tabs: [for (final l in _tabLabels) Tab(text: l)],
                ),
              ),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  itemCount: _categories.length,
                  separatorBuilder: (_, unused) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final c = _categories[i];
                    final selected = _categoryTabController.index == c.tabIndex;
                    return InkWell(
                      onTap: () {
                        _categoryTabController.animateTo(c.tabIndex);
                        setState(() => _carouselIndex = 0);
                      },
                      child: Column(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected ? AppTokens.primaryRed : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: CatalogImage(url: c.imageUrl, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 76,
                            child: Text(
                              c.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: selected ? AppTokens.primaryRed : const Color(0xFF5C6B7A),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_busy_outlined, size: 48, color: AppTokens.textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                'No live events in this category right now.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try All or another tab — same flow as BookMyShow category browse.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTokens.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  _categoryTabController.animateTo(0);
                                  setState(() => _carouselIndex = 0);
                                },
                                child: const Text('View all events'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : CustomScrollView(
                        primary: false,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              child: _ThingsToDoCarousel(
                                events: filtered,
                                carouselIndex: _carouselIndex,
                                onPageChanged: (i) => setState(() => _carouselIndex = i),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Choices Vast But Filling Fast',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 112,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                children: [
                                  ...filtered.take(6).map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: _FastBannerCard(event: e),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 32)),
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

class _ThingsToDoCarousel extends StatelessWidget {
  const _ThingsToDoCarousel({
    required this.events,
    required this.carouselIndex,
    required this.onPageChanged,
  });

  final List<LiveEvent> events;
  final int carouselIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final pages = events.take(5).toList();
    if (pages.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTokens.liveEventsLavender,
            Colors.white,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Things To Do In Your City ✨',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTokens.liveEventsIndigo,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's what everyone is booking",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTokens.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 168,
            child: PageView.builder(
              controller: PageController(viewportFraction: 1),
              itemCount: pages.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, i) {
                final ev = pages[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 110,
                        height: 150,
                        child: CatalogImage(url: ev.imageRef, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ev.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ev.category,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ev.synopsis,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
                          ),
                          const Spacer(),
                          Text(
                            '₹ ${ev.priceFrom.toStringAsFixed(0)} onwards',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => context.push('/event/${ev.id}'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTokens.primaryRed,
                                side: const BorderSide(color: AppTokens.primaryRed),
                                backgroundColor: Colors.white,
                              ),
                              child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == carouselIndex ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == carouselIndex ? const Color(0xFF424242) : AppTokens.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FastBannerCard extends StatelessWidget {
  const _FastBannerCard({required this.event});

  final LiveEvent event;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CatalogImage(url: event.imageRef, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

void _showLiveEventsRegionPicker(BuildContext context, String currentCity) {
  final options = ['Mumbai', 'Delhi-NCR', 'Bengaluru', 'Hyderabad', 'Pune'];
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
              trailing: currentCity.contains(city.split('-').first)
                  ? const Icon(Icons.check_rounded, color: AppTokens.primaryRed)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Demo: listings stay on $currentCity. ($city in a full app.)',
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
