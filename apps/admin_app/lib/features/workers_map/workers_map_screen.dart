import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/app_config.dart';
import '../../core/models/worker_location.dart';
import '../../core/providers/worker_locations_provider.dart';

class WorkersMapScreen extends ConsumerStatefulWidget {
  const WorkersMapScreen({super.key});

  @override
  ConsumerState<WorkersMapScreen> createState() => _WorkersMapScreenState();
}

class _WorkersMapScreenState extends ConsumerState<WorkersMapScreen> {
  final _mapController = MapController();
  static const _defaultCenter = LatLng(30.0444, 31.2357); // Cairo

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(workerLocationsProvider);
    final workers = locations.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(workerLocationsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status bar ─────────────────────────────────────────────────
          if (workers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10,
                      color: workers.any((w) => w.isOnline) ? Colors.green : Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${workers.where((w) => w.isOnline).length} online / ${workers.length} workers',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text('Updates every 30s',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),

          // ── Map ────────────────────────────────────────────────────────
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: workers.isNotEmpty
                    ? LatLng(workers.first.lat, workers.first.lng)
                    : _defaultCenter,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.osmTileUrl,
                  userAgentPackageName: 'com.washly.admin',
                ),
                MarkerLayer(
                  markers: workers.map((w) => _buildMarker(context, w)).toList(),
                ),
              ],
            ),
          ),

          // ── Worker list ────────────────────────────────────────────────
          if (workers.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2)),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: workers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _WorkerTile(
                  worker: workers[i],
                  onTap: () => _mapController.move(
                    LatLng(workers[i].lat, workers[i].lng), 16,
                  ),
                ),
              ),
            ),

          if (workers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.location_off, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No worker locations received yet.',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Workers report their position every 30 seconds when active.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Marker _buildMarker(BuildContext context, WorkerLocation w) {
    final online = w.isOnline;
    return Marker(
      point: LatLng(w.lat, w.lng),
      width: 120,
      height: 64,
      child: GestureDetector(
        onTap: () => _showWorkerInfo(context, w),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: online ? Colors.blue[700] : Colors.grey[600],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                ],
              ),
              child: Text(
                w.name.split(' ').first,
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Icon(Icons.location_pin,
                color: online ? Colors.blue[700] : Colors.grey[600], size: 28),
          ],
        ),
      ),
    );
  }

  void _showWorkerInfo(BuildContext context, WorkerLocation w) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.circle,
                  size: 10, color: w.isOnline ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              Text(w.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text('Last seen: ${w.lastSeenLabel}',
                style: TextStyle(color: Colors.grey[600])),
            Text('Lat: ${w.lat.toStringAsFixed(6)}, Lng: ${w.lng.toStringAsFixed(6)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _WorkerTile extends StatelessWidget {
  final WorkerLocation worker;
  final VoidCallback onTap;
  const _WorkerTile({required this.worker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: worker.isOnline ? Colors.blue[100] : Colors.grey[200],
        child: Icon(Icons.engineering,
            size: 16,
            color: worker.isOnline ? Colors.blue[700] : Colors.grey[500]),
      ),
      title: Text(worker.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(worker.lastSeenLabel,
          style: TextStyle(
              fontSize: 12,
              color: worker.isOnline ? Colors.green[700] : Colors.grey[500])),
      trailing: Icon(
        worker.isOnline ? Icons.gps_fixed : Icons.gps_not_fixed,
        size: 16,
        color: worker.isOnline ? Colors.blue[600] : Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}
