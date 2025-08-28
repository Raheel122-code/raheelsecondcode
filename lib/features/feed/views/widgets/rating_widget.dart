import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double currentRating;
  final Function(int) onRateVideo;

  const RatingWidget({
    Key? key,
    required this.currentRating,
    required this.onRateVideo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Current Rating', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text(
          currentRating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 32),
        Text('Rate this video', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            10,
            (index) => IconButton(
              icon: Icon(
                Icons.star,
                color:
                    index + 1 <= currentRating.round()
                        ? Colors.amber
                        : Colors.grey,
              ),
              onPressed: () => onRateVideo(index + 1),
              iconSize: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap a star to rate (1-10)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
