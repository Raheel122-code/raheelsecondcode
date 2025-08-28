import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/media_model.dart';
import '../../../../providers/feed_provider.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/comments_list.dart';
import '../widgets/rating_widget.dart';

class VideoDetailScreen extends StatefulWidget {
  final MediaModel media;

  const VideoDetailScreen({Key? key, required this.media}) : super(key: key);

  @override
  _VideoDetailScreenState createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.media.title),
        actions: [
          if (widget.media.ageRating == '18 plus')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('18+'),
            ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: VideoPlayerWidget(media: widget.media, autoplay: true),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [Tab(text: 'Comments'), Tab(text: 'Rate')],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        CommentsList(
                          comments: widget.media.comments,
                          onAddComment: (text) {
                            context.read<FeedProvider>().addComment(
                              widget.media.id,
                              text,
                            );
                          },
                        ),
                        RatingWidget(
                          currentRating: widget.media.averageRating,
                          onRateVideo: (rating) {
                            context.read<FeedProvider>().addRating(
                              widget.media.id,
                              rating,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
