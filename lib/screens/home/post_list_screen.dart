import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/max_width_container.dart';
import '../../widgets/post_card.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final _scrollController = ScrollController();
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PostProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    setState(() => _loggingOut = true);
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    setState(() => _loggingOut = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text("You've been logged out.", style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final postProvider = context.watch<PostProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.isLoggedIn ? 'Welcome Back' : 'Public Blog Forum',
          style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.crimson,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: const Icon(Icons.forum_outlined),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: !auth.isLoggedIn
                ? null
                : _loggingOut
                    ? const Padding(
                        key: ValueKey('logout-loading'),
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: AppColors.crimson),
                        ),
                      )
                    : TextButton(
                      onPressed: _handleLogout, 
                      child: const Text('Log out', style: TextStyle(color: Colors.white)),
          ),)
        ],
      ),
      floatingActionButton: auth.isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/post/new'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New Post'),
            )
          : FloatingActionButton.extended(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login_outlined),
              label: const Text('Login'),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.crimson,
          onRefresh: () => context.read<PostProvider>().loadInitial(),
          child: MaxWidthContainer(child: _buildBody(postProvider)),
        ),
      ),
    );
  }

  Widget _buildBody(PostProvider postProvider) {
    if (postProvider.isLoadingInitial && postProvider.posts.isEmpty) {
      return const LoadingIndicator(size: 32);
    }

    if (postProvider.errorMessage != null && postProvider.posts.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.wifi_off_rounded,
            title: postProvider.errorMessage!,
          ),
        ],
      );
    }

    if (postProvider.posts.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.forum_outlined,
            title: 'No posts yet',
            subtitle: 'Be the first to start a discussion.',
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: postProvider.posts.length + (postProvider.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index >= postProvider.posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LoadingIndicator(),
          );
        }
        final post = postProvider.posts[index];
        return PostCard(
          post: post,
          onTap: () => context.push('/post/${post.id}'),
        );
      },
    );
  }
}