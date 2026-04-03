import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'routing/app_router.dart';

final _router = createAppRouter();

class ShowTicketsApp extends StatelessWidget {
  const ShowTicketsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ShowTickets',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
