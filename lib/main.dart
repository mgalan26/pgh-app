import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/env.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // Manejar deep link de invitación / recuperación de contraseña.
  // En Flutter web los parámetros llegan como fragment (#access_token=…).
  final uri      = Uri.base;
  final fragment = uri.fragment;
  if (fragment.contains('type=invite') || fragment.contains('type=recovery')) {
    final params       = Uri.splitQueryString(fragment);
    final accessToken  = params['access_token'];
    final refreshToken = params['refresh_token'];
    if (accessToken != null && refreshToken != null) {
      await Supabase.instance.client.auth.setSession(accessToken, refreshToken);
    }
  }

  runApp(
    const ProviderScope(
      child: PghApp(),
    ),
  );
}

class PghApp extends ConsumerWidget {
  const PghApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PGH — Agenda Hispana',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
    );
  }
}
