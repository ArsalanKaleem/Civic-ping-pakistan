import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../models/report.dart';
import '../../widgets/badges.dart';

class ReportSuccessScreen extends StatelessWidget {
  const ReportSuccessScreen({super.key, required this.result});
  final SubmitResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = result.report;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.check_circle_outline,
                  size: 88, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text('Report submitted',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Thank you for helping improve your community. Track this '
                'report anytime using its ID.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              LuxCard(
                child: Column(children: [
                  _row(
                    context,
                    'Report ID',
                    report.reportCode,
                    trailing: IconButton(
                      tooltip: 'Copy',
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: report.reportCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Report ID copied.')));
                      },
                    ),
                  ),
                  const Divider(height: 28),
                  _row(context, 'Category', report.category.label),
                  const Divider(height: 28),
                  _row(context, 'Authority notified',
                      result.authorityContacted ?? 'Being routed'),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status'),
                      StatusBadge(report.status),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to CivicPing'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(children: [
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (trailing != null) trailing,
        ]),
      ],
    );
  }
}
