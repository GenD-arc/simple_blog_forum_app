import 'package:go_router/go_router.dart';

import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/post_list_screen.dart';
import '../screens/post/post_detail_screen.dart';
import '../screens/post/post_form_screen.dart';

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final needsAuth = state.matchedLocation == '/post/new' ||
          state.matchedLocation.endsWith('/edit');

      if (needsAuth && !authProvider.isLoggedIn) {
        return '/login';
      }
      if (loggingIn && authProvider.isLoggedIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PostListScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/post/new',
        builder: (context, state) => const PostFormScreen(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/post/:id/edit',
        builder: (context, state) => PostFormScreen(
          postId: state.pathParameters['id']!,
          initialPost: state.extra as PostModel?,
        ),
      ),
    ],
  );
}
