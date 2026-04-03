import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../providers/providers.dart';

/// BookMyShow-style profile: top tabs **You** · **Bookings** · **More**.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _nestedOuterController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nestedOuterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _nestedOuterController,
      child: Scaffold(
        backgroundColor: AppTokens.canvasMuted,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTokens.canvasMuted,
              elevation: innerBoxIsScrolled ? 0.5 : 0,
              title: const Text('Profile'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Material(
                  color: AppTokens.canvasMuted,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTokens.primaryRed,
                    indicatorWeight: 3,
                    labelColor: AppTokens.primaryRed,
                    unselectedLabelColor: AppTokens.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'You'),
                      Tab(text: 'Bookings'),
                      Tab(text: 'More'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _YouTab(onLogin: () => _showLoginDialog(context)),
            _BookingsTab(
              onMyTickets: () => context.pushNamed('myTickets'),
              onBrowseEvents: () => context.goNamed('liveEvents'),
              onBrowseMovies: () => context.goNamed('movies'),
            ),
            const _MoreTab(),
          ],
        ),
      ),
    ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign in'),
        content: const Text(
          'Use your mobile number or email to sign in. Demo build — no real authentication.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _YouTab extends StatefulWidget {
  const _YouTab({required this.onLogin});

  final VoidCallback onLogin;

  @override
  State<_YouTab> createState() => _YouTabState();
}

class _YouTabState extends State<_YouTab> {
  bool _notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          elevation: 1,
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTokens.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🍿', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey there!',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Login to unlock special offers, faster checkout & your STREAM library.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTokens.textSecondary,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: widget.onLogin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.primaryRed,
                    side: const BorderSide(color: AppTokens.primaryRed),
                  ),
                  child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionTitle(label: 'Preferences'),
        _ProfileCard(
          children: [
            _SwitchRow(
              icon: Icons.notifications_outlined,
              title: 'Push notifications',
              subtitle: 'Show reminders & offers',
              value: _notificationsOn,
              onChanged: (v) {
                setState(() => _notificationsOn = v);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(v ? 'Notifications on (demo).' : 'Notifications off (demo).')),
                );
              },
            ),
            const Divider(height: 1),
            _ProfileRow(
              icon: Icons.language_rounded,
              title: 'Language & region',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('English · India (demo).')),
                );
              },
            ),
            const Divider(height: 1),
            _ProfileRow(
              icon: Icons.payment_rounded,
              title: 'Saved payment methods',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add cards & UPI after sign-in (demo).')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle(label: 'Partner with us'),
        _ProfileCard(
          children: [
            _ProfileRow(
              icon: Icons.storefront_outlined,
              title: 'List your Show',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('List your show — partner onboarding (demo).')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _BookingsTab extends StatelessWidget {
  const _BookingsTab({
    required this.onMyTickets,
    required this.onBrowseEvents,
    required this.onBrowseMovies,
  });

  final VoidCallback onMyTickets;
  final VoidCallback onBrowseEvents;
  final VoidCallback onBrowseMovies;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text(
          'Your orders',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Movies, live events & STREAM — same place as on BookMyShow.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTokens.textSecondary),
        ),
        const SizedBox(height: 16),
        _ProfileCard(
          children: [
            _ProfileRow(
              icon: Icons.confirmation_number_outlined,
              title: 'My tickets',
              subtitle: 'Saved on this device (demo)',
              onTap: onMyTickets,
            ),
            const Divider(height: 1),
            _ProfileRow(
              icon: Icons.movie_creation_outlined,
              title: 'Movie bookings',
              onTap: onBrowseMovies,
            ),
            const Divider(height: 1),
            _ProfileRow(
              icon: Icons.event_available_outlined,
              title: 'Live event bookings',
              onTap: onBrowseEvents,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'STREAM',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _ProfileCard(
          children: [
            _ProfileRow(
              icon: Icons.tv_outlined,
              title: 'STREAM Library',
              locked: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sign in to see rentals & purchases (demo).')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _MoreTab extends ConsumerWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _ProfileCard(
          children: [
            _ProfileRow(
              icon: Icons.shopping_bag_outlined,
              title: 'Your Bookings & Purchases',
              locked: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sign in to view full history (demo).')),
                );
              },
            ),
            const Divider(height: 1),
            _ProfileRow(
              icon: Icons.credit_card_outlined,
              title: 'PLAY Credit Card',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PLAY credit card — exclusive movie & event offers (demo).')),
                );
              },
            ),
            const Divider(height: 1),
            _ProfileRow(
              icon: Icons.help_outline_rounded,
              title: 'Help Centre',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help 24x7 · support@showtickets.demo (demo).')),
                );
              },
            ),
            const Divider(height: 1),
            _ProfileRow(
              icon: Icons.card_giftcard_outlined,
              title: 'Rewards',
              onTap: () => context.pushNamed('search', queryParameters: const {'q': 'rewards'}),
            ),
            const Divider(height: 1),
            _ProfileRow(
              icon: Icons.local_offer_outlined,
              title: 'Offers',
              onTap: () => context.pushNamed('search', queryParameters: const {'q': 'offers'}),
            ),
            const Divider(height: 1),
            _ProfileRow(
              icon: Icons.card_membership_outlined,
              title: 'Gift Cards',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Buy & redeem gift cards (demo).')),
                );
              },
            ),
            const Divider(height: 1),
            _ProfileRow(
              icon: Icons.fastfood_outlined,
              title: 'Food & Beverages',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pre-order F&B with movie tickets (demo).')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ProfileCard(
          children: [
            _ProfileRow(
              icon: Icons.settings_outlined,
              title: 'Account & Settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account, privacy & app settings (demo).')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Clear bookings?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(bookingsProvider.notifier).clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookings cleared.')));
              }
            }
          },
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          label: const Text('Clear saved demo bookings'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF212121), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppTokens.primaryRed,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Column(children: children),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final muted = locked ? AppTokens.textSecondary.withValues(alpha: 0.45) : const Color(0xFF212121);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: muted, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
                    ),
                ],
              ),
            ),
            Icon(
              locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
              color: AppTokens.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
