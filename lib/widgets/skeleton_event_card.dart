import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonEventCard extends StatelessWidget {
  const SkeletonEventCard({super.key});

  @override
  Widget build(BuildContext context) {
    // We wrap the whole thing in Shimmer
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, // The main gray color
      highlightColor: Colors.grey[100]!, // The lighter shimmering wave
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        elevation: 0, // No shadow for skeleton
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Placeholder
              Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white, // Color doesn't matter, Shimmer overrides it
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(width: 16),

              // 2. Content Placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Date
                    Container(width: 120, height: 12, color: Colors.white),
                    const SizedBox(height: 6),
                    // Title (Two lines)
                    Container(width: double.infinity, height: 16, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(width: 150, height: 16, color: Colors.white),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.white), // Icon
                        const SizedBox(width: 4),
                        Container(width: 100, height: 12, color: Colors.white),
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
  }
}