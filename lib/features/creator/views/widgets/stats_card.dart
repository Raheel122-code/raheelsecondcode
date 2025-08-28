import 'package:flutter/material.dart';
import '../../../../providers/creator_provider.dart';
import '../../theme/creator_theme.dart';

class StatsCard extends StatelessWidget {
  final PostStats stats;

  const StatsCard({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, CreatorTheme.lightRed.withOpacity(0.1)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistics',
                style: TextStyle(
                  color: CreatorTheme.darkRed,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    context,
                    'Comments',
                    stats.totalComments.toString(),
                    Icons.comment,
                    CreatorTheme.primaryRed,
                  ),
                  _buildStat(
                    context,
                    'Ratings',
                    stats.totalRatings.toString(),
                    Icons.star,
                    CreatorTheme.primaryRed,
                  ),
                  _buildStat(
                    context,
                    'Average',
                    stats.averageRating.toStringAsFixed(1),
                    Icons.star_half,
                    CreatorTheme.primaryRed,
                  ),
                ],
              ),
              if (stats.ratingDistribution.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Rating Distribution',
                  style: TextStyle(
                    color: CreatorTheme.darkRed,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRatingDistribution(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: CreatorTheme.darkRed,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: CreatorTheme.darkRed.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDistribution(BuildContext context) {
    final maxCount =
        stats.ratingDistribution.values
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

    return Column(
      children:
          stats.ratingDistribution.entries.map((entry) {
            final percentage =
                maxCount > 0 ? (entry.value / maxCount) * 100 : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: CreatorTheme.darkRed,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: CreatorTheme.lightRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage / 100,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: CreatorTheme.primaryRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        color: CreatorTheme.darkRed,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
