import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models/enums.dart';
import '../models/report.dart';
import '../services/admin_service.dart';
import '../services/report_service.dart';
import '../widgets/badges.dart';

/// Report management: filterable table with inline status changes.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<Report>> _future;
  ReportStatus? _status;
  IssueCategory? _category;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = context
      .read<ReportService>()
      .list(status: _status, category: _category, limit: 500);

  void _reload() => setState(_load);

  Future<void> _changeStatus(Report r, ReportStatus s) async {
    try {
      await context.read<AdminService>().updateReportStatus(r.reportCode, s);
      _reload();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('Reports', style: theme.textTheme.displaySmall)),
            IconButton(
                tooltip: 'Refresh',
                onPressed: _reload,
                icon: const Icon(Icons.refresh)),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: [
            DropdownMenu<ReportStatus?>(
              label: const Text('Status'),
              width: 200,
              onSelected: (v) {
                _status = v;
                _reload();
              },
              dropdownMenuEntries: <DropdownMenuEntry<ReportStatus?>>[
                const DropdownMenuEntry<ReportStatus?>(
                    value: null, label: 'All'),
                ...ReportStatus.values.map((s) =>
                    DropdownMenuEntry<ReportStatus?>(
                        value: s, label: s.label)),
              ],
            ),
            DropdownMenu<IssueCategory?>(
              label: const Text('Category'),
              width: 220,
              onSelected: (v) {
                _category = v;
                _reload();
              },
              dropdownMenuEntries: <DropdownMenuEntry<IssueCategory?>>[
                const DropdownMenuEntry<IssueCategory?>(
                    value: null, label: 'All'),
                ...IssueCategory.values.map((c) =>
                    DropdownMenuEntry<IssueCategory?>(
                        value: c, label: c.label)),
              ],
            ),
          ]),
        ]),
      ),
      Expanded(
        child: FutureBuilder<List<Report>>(
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
                  icon: Icons.inbox_outlined, title: 'No reports match');
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Report')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('City')),
                    DataColumn(label: Text('Severity')),
                    DataColumn(label: Text('Reported')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (final r in reports)
                      DataRow(cells: [
                        DataCell(Text(r.reportCode,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600))),
                        DataCell(Row(children: [
                          Icon(r.category.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(r.category.label),
                        ])),
                        DataCell(Text(r.city ?? '—')),
                        DataCell(SeverityBadge(r.severity)),
                        DataCell(Text(DateFormat.yMMMd()
                            .format(r.createdAt.toLocal()))),
                        DataCell(
                          PopupMenuButton<ReportStatus>(
                            tooltip: 'Change status',
                            initialValue: r.status,
                            onSelected: (s) => _changeStatus(r, s),
                            itemBuilder: (_) => ReportStatus.values
                                .map((s) => PopupMenuItem(
                                    value: s, child: Text(s.label)))
                                .toList(),
                            child: StatusBadge(r.status),
                          ),
                        ),
                      ]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
