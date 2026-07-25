import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/report.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../widgets/badges.dart';
import 'detail/report_detail_screen.dart';
import 'map/map_screen.dart';
import 'report/report_flow_screen.dart';

/// Citizen web shell: top nav bar, map + feed views, prominent Report CTA.
class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;
  int _refreshTick = 0;

  Future<void> _report() async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReportFlowScreen()));
    setState(() => _refreshTick++);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final wide = MediaQuery.sizeOf(context).width > 760;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const BrandMark(),
        actions: [
          if (wide) ...[
            _navButton('Map', 0),
            _navButton('Reports', 1),
            const SizedBox(width: 16),
          ],
          FilledButton.icon(
            onPressed: _report,
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: const Text('Report an issue'),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: auth.displayName,
            icon: CircleAvatar(
              radius: 17,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.12),
              child: Text(
                auth.displayName.isEmpty
                    ? '?'
                    : auth.displayName[0].toUpperCase(),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(auth.isGuest ? 'Guest session' : auth.displayName),
              ),
              const PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
            onSelected: (v) {
              if (v == 'signout') auth.signOut();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _index == 0
          ? const MapScreen()
          : _FeedView(key: ValueKey(_refreshTick)),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.map_outlined), label: 'Map'),
                NavigationDestination(
                    icon: Icon(Icons.list_alt_outlined), label: 'Reports'),
              ],
            ),
    );
  }

  Widget _navButton(String label, int i) {
    final selected = _index == i;
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: () => setState(() => _index = i),
      child: Text(label,
          style: TextStyle(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          )),
    );
  }
}

class _FeedView extends StatefulWidget {
  const _FeedView({super.key});

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  late Future<List<Report>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ReportService>().list();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Report>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load reports',
              subtitle: '${snap.error}');
        }
        final reports = snap.data ?? [];
        if (reports.isEmpty) {
          return const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No reports yet',
              subtitle: 'Be the first to report an issue in your city.');
        }
        return LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 1200 ? 3 : (c.maxWidth > 760 ? 2 : 1);
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              mainAxisExtent: 148,
            ),
            itemCount: reports.length,
            itemBuilder: (_, i) => _ReportCard(report: reports[i]),
          );
        });
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LuxCard(
      padding: const EdgeInsets.all(18),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReportDetailScreen(code: report.reportCode))),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: report.status.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(report.category.icon, color: report.status.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(report.category.label,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(report.address ?? report.city ?? 'Location recorded',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Row(children: [
                  StatusBadge(report.status),
                  const Spacer(),
                  Text(
                    DateFormat.MMMd().format(report.createdAt.toLocal()),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
