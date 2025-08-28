import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/creator_provider.dart';
import 'features/auth/views/screens/auth_screen.dart';
import 'features/feed/views/screens/feed_screen.dart';
import 'features/creator/views/screens/creator_profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => CreatorProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TikTok Clone',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/feed': (context) => const FeedScreen(),
          '/creator': (context) => const CreatorProfileScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        switch (auth.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.authenticated:
            final user = auth.user;
            if (user == null) {
              return const AuthScreen();
            }

            switch (user.role) {
              case 'creator':
                return const CreatorProfileScreen(); // This will show creator's own profile
              case 'consumer':
                return const FeedScreen(); // This will show consumer feed
              default:
                return const AuthScreen();
            }
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return const AuthScreen();
        }
      },
    );
  }
}
