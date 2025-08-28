import 'package:flutter/material.dart';
import 'package:frontend/features/creator/views/screens/upload_video_screen.dart';
import 'package:frontend/features/creator/views/widgets/stats_card.dart';
import 'package:frontend/features/creator/views/widgets/video_grid.dart';
import 'package:provider/provider.dart';
import '../../../../providers/creator_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../widgets/profile_header.dart';
import '../../theme/creator_theme.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String? userId;
  const CreatorProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  _CreatorProfileScreenState createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userId = widget.userId ?? context.read<AuthProvider>().user?.id;
    if (userId != null && mounted) {
      await context.read<CreatorProvider>().loadInitialData(userId);
    }
  }

  Future<void> _navigateToUpload() async {
    setState(() => _isLoading = true);

    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const UploadVideoScreen()),
      );

      if (result == true) {
        // Video uploaded successfully, refresh the feed
        await _loadData();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isOwnProfile = widget.userId == null || widget.userId == user?.id;

    if (!isOwnProfile && user?.role != 'creator') {
      return Theme(
        data: CreatorTheme.theme,
        child: Scaffold(
          backgroundColor: CreatorTheme.backgroundRed,
          body: Center(
            child: Text(
              'Access denied. Only creators can view this profile.',
              style: TextStyle(color: CreatorTheme.darkRed, fontSize: 16),
            ),
          ),
        ),
      );
    }

    if (user == null) {
      return Theme(
        data: CreatorTheme.theme,
        child: Scaffold(
          backgroundColor: CreatorTheme.backgroundRed,
          body: Center(
            child: Text(
              'Please sign in to access this profile',
              style: TextStyle(color: CreatorTheme.darkRed, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Theme(
      data: CreatorTheme.theme,
      child: Scaffold(
        backgroundColor: CreatorTheme.backgroundRed,
        appBar: AppBar(
          title: const Text('Creator Studio'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CreatorTheme.primaryRed, CreatorTheme.darkRed],
              ),
            ),
          ),
          elevation: 0,
          actions: [
            if (!_isLoading)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _navigateToUpload,
              ),
            if (_isLoading)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            const SizedBox(width: 16),
          ],
        ),
        body: Consumer<CreatorProvider>(
          builder: (context, provider, _) {
            if (provider.status == CreatorStatus.loading &&
                provider.posts.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    CreatorTheme.primaryRed,
                  ),
                ),
              );
            }

            if (provider.status == CreatorStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: CreatorTheme.darkRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.error ?? 'An error occurred',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CreatorTheme.darkRed,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              color: CreatorTheme.primaryRed,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: CreatorTheme.darkRed.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return Stack(
                                children: [
                                  ProfileHeader(
                                    user: user,
                                    onUpdateProfilePic: (image) async {
                                      try {
                                        await authProvider.updateProfilePicture(
                                          image,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Profile picture updated successfully',
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to update profile picture: ${e.toString()}',
                                              ),
                                              backgroundColor:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  if (authProvider.status == AuthStatus.loading)
                                    const Positioned.fill(
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          if (provider.stats != null) ...[
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Videos: ${provider.totalPosts}',
                                    style: TextStyle(
                                      color: CreatorTheme.darkRed,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (provider.totalPosts > 0)
                                    Text(
                                      'Average Rating: ${provider.stats!.averageRating.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        color: CreatorTheme.darkRed,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            StatsCard(stats: provider.stats!),
                            Divider(
                              color: CreatorTheme.lightRed,
                              thickness: 1,
                              height: 1,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  VideoGrid(
                    posts: provider.posts,
                    hasMore: provider.hasMore,
                    onLoadMore: () => provider.loadMore(user.id),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
