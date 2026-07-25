import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/enums.dart';
import '../models/social_post.dart';
import '../services/admin_service.dart';
import '../widgets/badges.dart';

/// Manual publishing workflow:
///   1. Every submitted report generates X + Facebook drafts (status READY).
///   2. You review each: copy the text, open the platform's compose page,
///      attach the report photo, and publish by hand.
///   3. Paste the live post URL back here and mark it POSTED (or skip it).
/// The human-in-the-loop is deliberate: nothing goes public without you.
class SocialQueueScreen extends StatefulWidget {
  const SocialQueueScreen({super.key});

  @override
  State<SocialQueueScreen> createState() => _SocialQueueScreenState();
}

class _SocialQueueScreenState extends State<SocialQueueScreen> {
  SocialPostStatus _tab = SocialPostStatus.ready;
  late Future<List<SocialPost>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      _future = context.read<AdminService>().socialPosts(status: _tab);

  void _reload() => setState(_load);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child:
                    Text('Social queue', style: theme.textTheme.displaySmall)),
            IconButton(
                tooltip: 'Refresh',
                onPressed: _reload,
                icon: const Icon(Icons.refresh)),
          ]),
          const SizedBox(height: 6),
          Text(
            'Generated posts wait here for your review. Copy, publish '
            'manually, then record the URL.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          SegmentedButton<SocialPostStatus>(
            segments: const [
              ButtonSegment(
                  value: SocialPostStatus.ready,
                  label: Text('Awaiting review'),
                  icon: Icon(Icons.hourglass_top, size: 16)),
              ButtonSegment(
                  value: SocialPostStatus.posted,
                  label: Text('Posted'),
                  icon: Icon(Icons.check, size: 16)),
              ButtonSegment(
                  value: SocialPostStatus.skipped,
                  label: Text('Skipped'),
                  icon: Icon(Icons.block, size: 16)),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() {
              _tab = s.first;
              _load();
            }),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: FutureBuilder<List<SocialPost>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load the queue',
                  subtitle: '${snap.error}');
            }
            final posts = snap.data ?? [];
            if (posts.isEmpty) {
              return EmptyState(
                icon: _tab == SocialPostStatus.ready
                    ? Icons.task_alt
                    : Icons.inbox_outlined,
                title: _tab == SocialPostStatus.ready
                    ? 'Queue is clear'
                    : 'Nothing here yet',
                subtitle: _tab == SocialPostStatus.ready
                    ? 'New reports will generate drafts automatically.'
                    : null,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(32),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (_, i) =>
                  _PostCard(post: posts[i], onChanged: _reload),
            );
          },
        ),
      ),
    ]);
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post, required this.onChanged});
  final SocialPost post;
  final VoidCallback onChanged;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _busy = false;

  SocialPost get post => widget.post;

  Future<void> _review(SocialPostStatus status,
      {String? url, String? note}) async {
    setState(() => _busy = true);
    try {
      await context.read<AdminService>().reviewSocialPost(
          id: post.id, status: status, postUrl: url, note: note);
      widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markPostedDialog() async {
    final urlCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as posted'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  'Paste the URL of the published post so it can be linked '
                  'from the report.'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Post URL',
                  hintText: 'https://x.com/…/status/…'),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark posted')),
        ],
      ),
    );
    final url = urlCtrl.text.trim();
    if (ok == true) {
      if (url.isEmpty || !url.startsWith('http')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('A valid post URL is required.')));
        }
        return;
      }
      await _review(SocialPostStatus.posted, url: url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = post.report;
    final isX = post.platform == SocialPlatform.x;
    return LuxCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Report photo (the image to attach manually).
        if (report?.imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Lux.radiusSm),
              child: CachedNetworkImage(
                imageUrl: report!.imageUrl!,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 150,
                  height: 150,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(isX ? Icons.alternate_email : Icons.facebook,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(post.platform.label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              if (report != null)
                Text('· ${report.reportCode}',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text(
                DateFormat.yMMMd().add_jm().format(post.createdAt.toLocal()),
                style: TextStyle(
                    fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Lux.radiusSm),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: SelectableText(post.content,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
            ),
            const SizedBox(height: 14),
            if (post.status == SocialPostStatus.ready)
              Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton.tonalIcon(
                  onPressed: _busy
                      ? null
                      : () {
                          Clipboard.setData(
                              ClipboardData(text: post.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Post text copied.')));
                        },
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Copy text'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => launchUrl(Uri.parse(post.platform.composeUrl),
                          mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text('Open ${isX ? "X" : "Facebook"}'),
                ),
                if (report?.imageUrl != null)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => launchUrl(Uri.parse(report!.imageUrl!),
                            mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Open photo'),
                  ),
                FilledButton.icon(
                  onPressed: _busy ? null : _markPostedDialog,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Mark posted'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _review(SocialPostStatus.skipped),
                  child: const Text('Skip'),
                ),
              ])
            else
              Row(children: [
                Icon(
                  post.status == SocialPostStatus.posted
                      ? Icons.check_circle_outline
                      : Icons.block,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(post.status.label,
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant)),
                if (post.postUrl != null) ...[
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(post.postUrl!),
                        mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View post'),
                  ),
                ],
              ]),
          ]),
        ),
      ]),
    );
  }
}
