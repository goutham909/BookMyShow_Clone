import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../providers/providers.dart';

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('My tickets'),
      ),
      body: bookings.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No bookings yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Book a show from Home or Movies — confirmations appear here (saved on device for this demo).',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.goNamed('movies'),
                      child: const Text('Browse movies'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.goNamed('home'),
                      child: const Text('Back to home'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final b = bookings[i];
                return Material(
                  color: AppTokens.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.movieTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(b.venueName, style: Theme.of(context).textTheme.labelLarge),
                        Text(b.showLabel, style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 8),
                        Text('Seats: ${b.seats.join(", ")}', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Paid ₹${b.totalInr.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Demo',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
