import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class BmsHomeNavIcon extends StatelessWidget {
  const BmsHomeNavIcon({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = selected ? AppTokens.primaryRed : AppTokens.textSecondary;
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(selected ? Icons.home_rounded : Icons.home_outlined, size: 24, color: c),
          Positioned(
            bottom: 1,
            child: Text(
              'MY',
              style: TextStyle(
                fontSize: 5.5,
                height: 1,
                fontWeight: FontWeight.w900,
                color: c,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BmsTicketNavIcon extends StatelessWidget {
  const BmsTicketNavIcon({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = selected ? AppTokens.primaryRed : AppTokens.textSecondary;
    return Icon(
      selected ? Icons.confirmation_number_rounded : Icons.confirmation_number_outlined,
      size: 24,
      color: c,
    );
  }
}
