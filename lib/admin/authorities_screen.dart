import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models/authority.dart';
import '../models/enums.dart';
import '../services/admin_service.dart';
import '../widgets/badges.dart';

/// Authority routing database: which department receives which issue type in
/// which city. Verify every email before enabling real delivery.
class AuthoritiesScreen extends StatefulWidget {
  const AuthoritiesScreen({super.key});

  @override
  State<AuthoritiesScreen> createState() => _AuthoritiesScreenState();
}

class _AuthoritiesScreenState extends State<AuthoritiesScreen> {
  late Future<List<Authority>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = context.read<AdminService>().authorities();
  void _reload() => setState(_load);

  Future<void> _edit([Authority? existing]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AuthorityDialog(existing: existing),
    );
    if (result == null || !mounted) return;
    final service = context.read<AdminService>();
    try {
      if (existing == null) {
        await service.createAuthority(result);
      } else {
        await service.updateAuthority(existing.id, result);
      }
      _reload();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _delete(Authority a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete authority?'),
        content: Text(
            '${a.departmentName} (${a.issueType.label}, ${a.city ?? "national"}) '
            'will no longer receive routed reports.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await context.read<AdminService>().deleteAuthority(a.id);
        _reload();
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
        child: Row(children: [
          Expanded(
              child:
                  Text('Authorities', style: theme.textTheme.displaySmall)),
          FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add authority'),
          ),
          const SizedBox(width: 8),
          IconButton(
              tooltip: 'Refresh',
              onPressed: _reload,
              icon: const Icon(Icons.refresh)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Unverified rows use placeholder emails — verify each address '
          'before turning off email dry-run.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: FutureBuilder<List<Authority>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load authorities',
                  subtitle: '${snap.error}');
            }
            final rows = snap.data ?? [];
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Scope')),
                    DataColumn(label: Text('Issue type')),
                    DataColumn(label: Text('Department')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Verified')),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (final a in rows)
                      DataRow(cells: [
                        DataCell(Text(a.city == null
                            ? 'National'
                            : (a.district == null
                                ? a.city!
                                : '${a.city} · ${a.district}'))),
                        DataCell(Row(children: [
                          Icon(a.issueType.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(a.issueType.label),
                        ])),
                        DataCell(SizedBox(
                            width: 240,
                            child: Text(a.departmentName,
                                overflow: TextOverflow.ellipsis))),
                        DataCell(Text(a.email)),
                        DataCell(Icon(
                          a.isVerified
                              ? Icons.verified_outlined
                              : Icons.warning_amber_outlined,
                          size: 18,
                          color: a.isVerified
                              ? const Color(0xFF1E7B4F)
                              : const Color(0xFFC9880A),
                        )),
                        DataCell(Row(children: [
                          IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18),
                              onPressed: () => _edit(a)),
                          IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline,
                                  size: 18),
                              onPressed: () => _delete(a)),
                        ])),
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

class _AuthorityDialog extends StatefulWidget {
  const _AuthorityDialog({this.existing});
  final Authority? existing;

  @override
  State<_AuthorityDialog> createState() => _AuthorityDialogState();
}

class _AuthorityDialogState extends State<_AuthorityDialog> {
  late final TextEditingController _city;
  late final TextEditingController _district;
  late final TextEditingController _dept;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late IssueCategory _issue;
  late bool _verified;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _city = TextEditingController(text: e?.city ?? '');
    _district = TextEditingController(text: e?.district ?? '');
    _dept = TextEditingController(text: e?.departmentName ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _issue = e?.issueType ?? IssueCategory.garbage;
    _verified = e?.isVerified ?? false;
  }

  @override
  void dispose() {
    for (final c in [_city, _district, _dept, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.existing == null ? 'Add authority' : 'Edit authority'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _city,
                      decoration: const InputDecoration(
                          labelText: 'City (blank = national)'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: _district,
                      decoration: const InputDecoration(
                          labelText: 'District (optional)'))),
            ]),
            const SizedBox(height: 14),
            DropdownMenu<IssueCategory>(
              width: 460,
              initialSelection: _issue,
              label: const Text('Issue type'),
              onSelected: (v) => _issue = v ?? _issue,
              dropdownMenuEntries: IssueCategory.values
                  .map((c) => DropdownMenuEntry(value: c, label: c.label))
                  .toList(),
            ),
            const SizedBox(height: 14),
            TextField(
                controller: _dept,
                decoration:
                    const InputDecoration(labelText: 'Department name')),
            const SizedBox(height: 14),
            TextField(
                controller: _email,
                decoration:
                    const InputDecoration(labelText: 'Official email')),
            const SizedBox(height: 14),
            TextField(
                controller: _phone,
                decoration:
                    const InputDecoration(labelText: 'Phone (optional)')),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Email verified'),
              subtitle: const Text(
                  'Only verified addresses should receive real complaints.'),
              value: _verified,
              onChanged: (v) => setState(() => _verified = v),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_dept.text.trim().isEmpty || _email.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Department name and email are required.')));
              return;
            }
            Navigator.pop(context, {
              'city':
                  _city.text.trim().isEmpty ? null : _city.text.trim(),
              'district': _district.text.trim().isEmpty
                  ? null
                  : _district.text.trim(),
              'issue_type': _issue.wire,
              'department_name': _dept.text.trim(),
              'email': _email.text.trim(),
              'phone':
                  _phone.text.trim().isEmpty ? null : _phone.text.trim(),
              'is_verified': _verified,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
