import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../feed/models/media_model.dart';

class VideoDialog extends StatefulWidget {
  final MediaModel media;

  const VideoDialog({Key? key, required this.media}) : super(key: key);

  @override
  _VideoDialogState createState() => _VideoDialogState();
}

class _VideoDialogState extends State<VideoDialog> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  Stream<MediaModel>? _mediaStream;

  Stream<MediaModel> _getMediaUpdates() {
    return Stream.periodic(
      const Duration(seconds: 5),
      (_) => widget.media,
    ).asyncMap((media) async {
      // Here you would typically fetch the latest media data from your API
      // For now, we'll return the current media object
      return media;
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize video controller
    _controller = VideoPlayerController.network(widget.media.video)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });

    // Add mouse hover listener for desktop
    _controller.addListener(() {
      final bool isPlaying = _controller.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    });

    // Initialize media stream
    _mediaStream = _getMediaUpdates();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Video player with hover controls
            Expanded(
              flex: 3,
              child: MouseRegion(
                onEnter: (_) => setState(() {}),
                onExit: (_) => setState(() {}),
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isInitialized)
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      else
                        const CircularProgressIndicator(),
                      if (!_isPlaying)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(
                              Icons.play_arrow,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Video details
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.media.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.media.caption,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rating: ${widget.media.averageRating.toStringAsFixed(1)}/10',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Comments: ${widget.media.totalComments}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<MediaModel>(
                        stream: _getMediaUpdates(),
                        initialData: widget.media,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Text(
                              'Error loading comments: ${snapshot.error}',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.red),
                            );
                          }

                          final media = snapshot.data!;
                          final comments = media.comments;

                          if (comments.isEmpty) {
                            return Center(
                              child: Text(
                                'No comments yet',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${media.totalComments} Comments',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: comments.length,
                                separatorBuilder:
                                    (context, index) =>
                                        const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          comment.user.profilePic.isNotEmpty
                                              ? NetworkImage(
                                                comment.user.profilePic,
                                              )
                                              : const AssetImage(
                                                    'assets/default_avatar.png',
                                                  )
                                                  as ImageProvider,
                                      radius: 20,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          comment.user.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getTimeAgo(comment.createdAt),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(comment.text),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
