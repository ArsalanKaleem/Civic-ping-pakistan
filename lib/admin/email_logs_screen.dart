import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/admin_service.dart';
import '../widgets/badges.dart';

/// Every complaint email the system generated, with its delivery status.
/// In dry-run mode entries are SKIPPED — the body is still fully generated
/// so you can inspect exactly what would be sent.
class EmailLogsScreen extends StatefulWidget {
  const EmailLogsScreen({super.key});

  @override
  State<EmailLogsScreen> createState() => _EmailLogsScreenState();
}

class _EmailLogsScreenState extends State<EmailLogsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminService>().emailLogs();
  }

  void _reload() => setState(
      () => _future = context.read<AdminService>().emailLogs());

  Color _statusColor(String s) => switch (s) {
        'sent' => const Color(0xFF1E7B4F),
        'failed' => const Color(0xFFC0392B),
        'skipped' => const Color(0xFFC9880A),
        _ => const Color(0xFF6B7280),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 8),
        child: Row(children: [
          Expanded(
              child:
                  Text('Email logs', style: theme.textTheme.displaySmall)),
          IconButton(
              tooltip: 'Refresh',
              onPressed: _reload,
              icon: const Icon(Icons.refresh)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Complaints generated for authorities. "Skipped" means dry-run '
          'is on — the email was composed but not delivered.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load email logs',
                  subtitle: '${snap.error}');
            }
            final logs = snap.data ?? [];
            if (logs.isEmpty) {
              return const EmptyState(
                  icon: Icons.mail_outline, title: 'No emails yet');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(32),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final log = logs[i];
                final status = log['status'] as String;
                final created =
                    DateTime.parse(log['created_at'] as String).toLocal();
                return LuxCard(
                  padding: const EdgeInsets.all(18),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    shape: const Border(),
                    title: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(status.toUpperCase(),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _statusColor(status))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(log['subject'] as String,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                    ]),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'To ${log['to_email']} · '
                        '${DateFormat.yMMMd().add_jm().format(created)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(Lux.radiusSm),
                        ),
                        child: SelectableText(log['body'] as String,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(height: 1.6)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}
