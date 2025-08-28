import 'package:flutter/material.dart';
import 'package:frontend/features/creator/views/widgets/video_dialog.dart';
import '../../../feed/models/media_model.dart';
import '../../theme/creator_theme.dart';

class VideoGrid extends StatelessWidget {
  final List<MediaModel> posts;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const VideoGrid({
    Key? key,
    required this.posts,
    required this.hasMore,
    required this.onLoadMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 64, color: CreatorTheme.darkRed),
              const SizedBox(height: 16),
              Text(
                'No videos yet',
                style: TextStyle(
                  color: CreatorTheme.darkRed,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your first video to get started',
                style: TextStyle(color: CreatorTheme.primaryRed, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 3 / 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= posts.length) {
            if (hasMore) {
              onLoadMore();
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    CreatorTheme.primaryRed,
                  ),
                ),
              );
            }
            return null;
          }

          final post = posts[index];
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => VideoDialog(media: post),
              );
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(post.thumbnail, fit: BoxFit.cover),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            post.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              Text(
                                post.averageRating.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.comment,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.totalComments}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: posts.length + (hasMore ? 1 : 0)),
      ),
    );
  }
}
