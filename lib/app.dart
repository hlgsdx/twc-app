import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/app/twc_app_services.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class TwcApp extends StatefulWidget {
  const TwcApp({super.key, this.services});

  final TwcAppServices? services;

  @override
  State<TwcApp> createState() => _TwcAppState();
}

class _TwcAppState extends State<TwcApp> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    if (widget.services != null) {
      _router = buildAppRouter(widget.services!);
    } else {
      _bootstrap();
    }
  }

  @override
  void didUpdateWidget(covariant TwcApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.services != widget.services && widget.services != null) {
      _installServices(widget.services!);
    }
  }

  Future<void> _bootstrap() async {
    final services = await TwcAppServices.create();
    if (!mounted) {
      return;
    }
    _installServices(services);
  }

  void _installServices(TwcAppServices services) {
    setState(() {
      _router = buildAppRouter(services);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    if (router == null) {
      return MaterialApp(theme: AppTheme.light, home: const _BootstrapScreen());
    }

    return MaterialApp.router(
      title: 'TWC',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}
