import 'package:flutter/material.dart';

import '../models/enums.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) => _Pill(
        color: status.color,
        label: status.label,
        dot: true,
      );
}

class SeverityBadge extends StatelessWidget {
  const SeverityBadge(this.severity, {super.key});
  final Severity severity;

  @override
  Widget build(BuildContext context) =>
      _Pill(color: severity.color, label: '${severity.label} severity');
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.label, this.dot = false});
  final Color color;
  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Wordmark used across both apps.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 22, this.light = false});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = light ? Colors.white : scheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 1.35,
          height: size * 1.35,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(Icons.campaign_outlined,
              color: Colors.white, size: size * 0.85),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: 'Civic',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: size, color: color)),
            TextSpan(
                text: 'Ping',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: size,
                    color: scheme.secondary,
                    fontStyle: FontStyle.italic)),
          ]),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key, required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}
