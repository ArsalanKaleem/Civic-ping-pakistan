import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/authority.dart';
import '../services/admin_service.dart';
import '../widgets/badges.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<AdminStats> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminService>().stats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<AdminStats>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load stats',
              subtitle: '${snap.error}');
        }
        final s = snap.data!;
        final total = s.totalReports == 0 ? 1 : s.totalReports;
        return ListView(
          padding: const EdgeInsets.all(32),
          children: [
            Text('Overview', style: theme.textTheme.displaySmall),
            const SizedBox(height: 6),
            Text('The state of civic reports across the platform.',
                style:
                    TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            Wrap(spacing: 20, runSpacing: 20, children: [
              _Stat(
                  label: 'Total reports',
                  value: '${s.totalReports}',
                  icon: Icons.stacked_bar_chart),
              _Stat(
                  label: 'Last 7 days',
                  value: '${s.reportsLast7Days}',
                  icon: Icons.calendar_today_outlined),
              _Stat(
                  label: 'Awaiting social review',
                  value: '${s.pendingSocialPosts}',
                  icon: Icons.campaign_outlined,
                  accent: true),
            ]),
            const SizedBox(height: 36),
            Text('Resolution pipeline',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            LuxCard(
              child: Column(children: [
                _bar(context, 'Unresolved', s.unresolved, total,
                    const Color(0xFFC0392B)),
                const SizedBox(height: 18),
                _bar(context, 'Under review', s.underReview, total,
                    const Color(0xFFC9880A)),
                const SizedBox(height: 18),
                _bar(context, 'Resolved', s.resolved, total,
                    const Color(0xFF1E7B4F)),
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _bar(
      BuildContext context, String label, int value, int total, Color c) {
    final frac = value / total;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('$value',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: LinearProgressIndicator(
          value: frac,
          minHeight: 10,
          backgroundColor: c.withOpacity(0.10),
          valueColor: AlwaysStoppedAnimation(c),
        ),
      ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.label,
      required this.value,
      required this.icon,
      this.accent = false});
  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 260,
      child: LuxCard(
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (accent ? scheme.secondary : scheme.primary)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: accent ? Lux.gold : scheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: Theme.of(context).textTheme.headlineMedium),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5, color: scheme.onSurfaceVariant)),
          ]),
        ]),
      ),
    );
  }
}
