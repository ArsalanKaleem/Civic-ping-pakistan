import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/report.dart';
import '../../services/location_service.dart';
import '../../services/report_service.dart';
import 'report_success_screen.dart';

/// The 30-second flow, web edition:
/// photo (camera on mobile browsers, file picker on desktop) -> auto-GPS ->
/// category -> submit. The image is uploaded to the backend's /uploads
/// endpoint and its URL attached to the report.
class ReportFlowScreen extends StatefulWidget {
  const ReportFlowScreen({super.key});

  @override
  State<ReportFlowScreen> createState() => _ReportFlowScreenState();
}

class _ReportFlowScreenState extends State<ReportFlowScreen> {
  XFile? _photo;
  List<int>? _photoBytes;
  LocationResult? _location;
  String? _locationError;
  IssueCategory _category = IssueCategory.pothole;
  final _desc = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _desc.dispose();
    _address.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera, // falls back to file picker on desktop web
      imageQuality: 72,
      maxWidth: 1600,
    );
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    setState(() {
      _photo = photo;
      _photoBytes = bytes;
    });
  }

  Future<void> _fetchLocation() async {
    setState(() => _locationError = null);
    try {
      final loc = await context.read<LocationService>().current();
      if (mounted) setState(() => _location = loc);
    } on LocationException catch (e) {
      if (mounted) setState(() => _locationError = e.message);
    } catch (e) {
      if (mounted) setState(() => _locationError = 'Could not get location.');
    }
  }

  Future<void> _submit() async {
    if (_location == null) {
      _snack('A location is required — allow location access or retry.');
      return;
    }
    if (_photoBytes == null) {
      _snack('Please add a photo of the issue.');
      return;
    }
    setState(() => _submitting = true);
    final service = context.read<ReportService>();
    try {
      final upload = await service.uploadImage(
          _photoBytes!, _photo?.name ?? 'photo.jpg');
      final SubmitResult result = await service.submit(
        category: _category,
        latitude: _location!.latitude,
        longitude: _location!.longitude,
        description: _desc.text.trim(),
        imageUrl: upload['url'] as String,
        address: _address.text.trim(),
        city: _city.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ReportSuccessScreen(result: result)));
    } on ApiException catch (e) {
      _snack(e.message);
      setState(() => _submitting = false);
    } catch (e) {
      _snack('Could not submit the report. Please try again.');
      setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Report an issue')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _PhotoPicker(
                bytes: _photoBytes,
                onPick: _pickPhoto,
              ),
              const SizedBox(height: 20),
              LuxCard(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Icon(Icons.location_on_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _location != null
                        ? Text(
                            'Location captured  ·  '
                            '${_location!.latitude.toStringAsFixed(5)}, '
                            '${_location!.longitude.toStringAsFixed(5)}',
                            style: theme.textTheme.bodyMedium)
                        : _locationError != null
                            ? Text(_locationError!,
                                style: TextStyle(
                                    color: theme.colorScheme.error))
                            : const Text('Getting your location…'),
                  ),
                  if (_locationError != null)
                    IconButton(
                        onPressed: _fetchLocation,
                        icon: const Icon(Icons.refresh)),
                ]),
              ),
              const SizedBox(height: 24),
              Text('What kind of issue is this?',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IssueCategory.values
                    .map((c) => ChoiceChip(
                          selected: c == _category,
                          onSelected: (_) => setState(() => _category = c),
                          avatar: Icon(c.icon, size: 18),
                          label: Text(c.label),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _address,
                    decoration: const InputDecoration(
                        labelText: 'Street / area (optional)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _city,
                    decoration:
                        const InputDecoration(labelText: 'City'),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Add a note (optional)',
                  hintText: 'e.g. open manhole near the school gate',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined),
                label:
                    Text(_submitting ? 'Submitting…' : 'Submit report'),
              ),
              const SizedBox(height: 10),
              Text(
                'Your report is public. The photo and location will appear '
                'on the CivicPing map, and a formal complaint is prepared '
                'for the responsible authority.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.bytes, required this.onPick});
  final List<int>? bytes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(Lux.radius),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Lux.radius),
          border: Border.all(color: scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: bytes != null
            ? Stack(fit: StackFit.expand, children: [
                Image.memory(Uint8List.fromList(bytes!), fit: BoxFit.cover),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FilledButton.tonalIcon(
                    onPressed: onPick,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retake'),
                  ),
                ),
              ])
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 44, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text('Add a photo of the issue',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Camera on mobile · file picker on desktop',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
      ),
    );
  }
}
