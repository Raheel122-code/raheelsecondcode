import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/feed_provider.dart';
import '../widgets/video_player_widget.dart';
import '../../../auth/models/user_model.dart';
import '../../models/media_model.dart';
import '../../../creator/theme/creator_theme.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({Key? key}) : super(key: key);

  void _showFullScreenDialog(BuildContext context, MediaModel post) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.7;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: (screenWidth - dialogWidth) / 2,
              vertical: 24,
            ),
            child: SingleChildScrollView(
              child: Container(
                width: dialogWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CreatorTheme.darkRed.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: VideoPlayerWidget(
                              media: post,
                              autoplay: true,
                              showControls: true,
                              expandedView: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    post.uploader.profilePic.isNotEmpty
                                        ? NetworkImage(post.uploader.profilePic)
                                        : const AssetImage(
                                              'assets/default_avatar.jpg',
                                            )
                                            as ImageProvider,
                                radius: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.title,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      post.uploader.username,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (post.caption.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              post.caption,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.star_border),
                                    onPressed: () {
                                      // TODO: Implement rating functionality
                                    },
                                  ),
                                  Text(
                                    post.averageRating.toStringAsFixed(1),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.comment_outlined),
                                    onPressed: () {
                                      // TODO: Implement comment functionality
                                    },
                                  ),
                                  Text(
                                    post.totalComments.toString(),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_outlined),
                                onPressed: () {
                                  // TODO: Implement share functionality
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: CreatorTheme.lightRed),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'Add a comment...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(12),
                                    ),
                                    maxLines: 1,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: () {
                                    // TODO: Implement send comment functionality
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CreatorTheme.theme,
      child: Scaffold(
        backgroundColor: CreatorTheme.backgroundRed,
        appBar: AppBar(
          title: const Text('For You'),
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
        ),
        body: Consumer<FeedProvider>(
          builder: (context, provider, _) {
            if (provider.status == FeedStatus.loading &&
                provider.posts.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    CreatorTheme.primaryRed,
                  ),
                ),
              );
            }

            if (provider.status == FeedStatus.error) {
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
                      onPressed: () => provider.refresh(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CreatorTheme.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              color: CreatorTheme.primaryRed,
              backgroundColor: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: provider.posts.length + (provider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= provider.posts.length) {
                    provider.loadMore();
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            CreatorTheme.primaryRed,
                          ),
                        ),
                      ),
                    );
                  }

                  final post = provider.posts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: InkWell(
                      onTap: () => _showFullScreenDialog(context, post),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: VideoPlayerWidget(media: post),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage:
                                            post.uploader.profilePic.isNotEmpty
                                                ? NetworkImage(
                                                  post.uploader.profilePic,
                                                )
                                                : const AssetImage(
                                                      'assets/default_avatar.jpg',
                                                    )
                                                    as ImageProvider,
                                        radius: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              post.title,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              post.uploader.username,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (post.caption.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      post.caption,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.star_border),
                                            onPressed: () {
                                              // TODO: Implement rating functionality
                                            },
                                          ),
                                          Text(
                                            post.averageRating.toStringAsFixed(
                                              1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.comment_outlined,
                                            ),
                                            onPressed: () {
                                              // TODO: Implement comment functionality
                                            },
                                          ),
                                          Text(post.totalComments.toString()),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share_outlined),
                                        onPressed: () {
                                          // TODO: Implement share functionality
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
