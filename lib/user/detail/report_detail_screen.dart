import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../widgets/badges.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.code});
  final String code;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Future<Report> _future;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<ReportService>().getByCode(widget.code);
  }

  void _reload() => setState(
      () => _future = context.read<ReportService>().getByCode(widget.code));

  Future<void> _confirm(ConfirmationType type) async {
    setState(() => _acting = true);
    try {
      await context
          .read<ReportService>()
          .confirm(code: widget.code, type: type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Thanks — your input was recorded.')));
        _reload();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: FutureBuilder<Report>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EmptyState(
                icon: Icons.error_outline,
                title: 'Report not found',
                subtitle: '${snap.error}');
          }
          final r = snap.data!;
          final theme = Theme.of(context);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (r.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Lux.radius),
                      child: CachedNetworkImage(
                        imageUrl: r.imageUrl!,
                        height: 320,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Icon(r.category.icon,
                        color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(r.category.label,
                          style: theme.textTheme.headlineMedium),
                    ),
                    StatusBadge(r.status),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    SeverityBadge(r.severity),
                    const SizedBox(width: 10),
                    Text('${r.confirmationsCount} confirmations',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 20),
                  if (r.description != null &&
                      r.description!.isNotEmpty) ...[
                    Text(r.description!,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(height: 1.6)),
                    const SizedBox(height: 20),
                  ],
                  LuxCard(
                    child: Column(children: [
                      _info(context, Icons.tag, 'Report ID', r.reportCode),
                      _info(context, Icons.place_outlined, 'Address',
                          r.address ?? r.city ?? '—'),
                      _info(context, Icons.my_location, 'Coordinates',
                          '${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}'),
                      if (r.authorityName != null)
                        _info(context, Icons.account_balance_outlined,
                            'Authority', r.authorityName!),
                      _info(
                          context,
                          Icons.schedule,
                          'Reported',
                          DateFormat.yMMMd()
                              .add_jm()
                              .format(r.createdAt.toLocal())),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  Text('Community verification',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Seen this issue yourself? Help keep the map accurate.',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _acting
                            ? null
                            : () =>
                                _confirm(ConfirmationType.confirmExists),
                        icon: const Icon(Icons.thumb_up_alt_outlined),
                        label: const Text('Still there'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _acting
                            ? null
                            : () => _confirm(ConfirmationType.markFixed),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('It\'s fixed'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _info(
      BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(label,
              style:
                  TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
