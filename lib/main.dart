import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'services/supabase_config.dart';
import 'auth/splash_page.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'pages/home_page.dart';
import 'pages/create_post_page.dart';
import 'pages/post_details_page.dart';
import 'pages/chat_list_page.dart';
import 'pages/chat_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'models/post_model.dart';
import 'pages/user_timeline_page.dart';
import 'pages/notifications_page.dart';
import 'pages/search_page.dart';
import 'pages/reports_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  runApp(const ReTurnHubApp());
}

class ReTurnHubApp extends StatelessWidget {
  const ReTurnHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReTurnHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const SplashPage(),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginPage(),
            );
          case '/register':
            return MaterialPageRoute(
              builder: (_) => const RegisterPage(),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (_) => const HomePage(),
            );
          case '/createPost':
            return MaterialPageRoute(
              builder: (_) => const CreatePostPage(),
            );
          case '/postDetails':
            final args = settings.arguments;
            if (args is Post) {
              return MaterialPageRoute(
                builder: (_) => PostDetailsPage(post: args),
              );
            }
            // Fallback if Post is not provided
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('Post details not available'),
                ),
              ),
            );
          case '/chatList':
            return MaterialPageRoute(
              builder: (_) => const ChatListPage(),
            );
          case '/search':
            return MaterialPageRoute(
              builder: (_) => const SearchPage(),
            );
          case '/chat':
            final args = settings.arguments;
            if (args is Map<String, dynamic>) {
              return MaterialPageRoute(
                builder: (_) => ChatPage(
                  chatId: args['chatId'] as String? ?? '',
                  recipientId: args['recipientId'] as String? ?? '',
                  recipientName: args['recipientName'] as String? ?? '',
                  recipientAvatar: args['recipientAvatar'] as String? ?? '',
                ),
              );
            }
            // Fallback if arguments are not provided
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('Chat information not available'),
                ),
              ),
            );
          case '/admin':
            return MaterialPageRoute(
              builder: (_) => AdminDashboardPage(),
            );
          case '/notifications':
            return MaterialPageRoute(
              builder: (_) => const NotificationsPage(),
            );
          case '/reports':
            return MaterialPageRoute(
              builder: (_) => const ReportsPage(),
            );
          case '/userTimeline':
            final args = settings.arguments;
            if (args is Map<String, dynamic>) {
              final userId = args['userId'] as String? ?? '';
              final userName = args['userName'] as String? ?? 'User';
              final userAvatar = args['userAvatar'] as String? ?? '';
              return MaterialPageRoute(
                builder: (_) => UserTimelinePage(
                  userId: userId,
                  userName: userName,
                  userAvatar: userAvatar,
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('User not found')),
                body: const Center(
                  child: Text('User information is missing'),
                ),
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Page Not Found')),
                body: Center(
                  child: Text('Route ${settings.name} not found'),
                ),
              ),
            );
        }
      },
    );
  }
}
