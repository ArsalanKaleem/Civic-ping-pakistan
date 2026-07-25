import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../detail/report_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<Report>> _future;
  ReportStatus? _filter;
  static final _center = LatLng(30.3753, 69.3451); // Pakistan

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      _future = context.read<ReportService>().list(status: _filter);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      FutureBuilder<List<Report>>(
        future: _future,
        builder: (context, snap) {
          final reports = snap.data ?? [];
          return FlutterMap(
            options: MapOptions(initialCenter: _center, initialZoom: 5.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'pk.civicping.web',
              ),
              MarkerLayer(markers: [
                for (final r in reports)
                  Marker(
                    point: LatLng(r.latitude, r.longitude),
                    width: 42,
                    height: 42,
                    child: _Pin(report: r),
                  ),
              ]),
            ],
          );
        },
      ),
      Positioned(
        top: 16,
        left: 16,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _chip('All', null),
              for (final s in ReportStatus.values) _chip(s.label, s),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _chip(String label, ReportStatus? value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        avatar: value == null
            ? null
            : CircleAvatar(backgroundColor: value.color, radius: 5),
        label: Text(label),
        onSelected: (_) => setState(() {
          _filter = value;
          _load();
        }),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${report.category.label} · ${report.status.label}',
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ReportDetailScreen(code: report.reportCode))),
        child: Container(
          decoration: BoxDecoration(
            color: report.status.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2)),
            ],
          ),
          child:
              Icon(report.category.icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
