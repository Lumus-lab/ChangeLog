import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TenWingDetailScreen extends StatelessWidget {
  final String title;
  final String content;

  const TenWingDetailScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 18,
              height: 1.8,
              letterSpacing: 1.5,
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
      ),
    );
  }
}
