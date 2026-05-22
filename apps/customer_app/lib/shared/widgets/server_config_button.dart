import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/services/api_client.dart';

class ServerConfigButton extends StatelessWidget {
  const ServerConfigButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.dns_outlined),
      tooltip: 'Server settings',
      onPressed: () => _showDialog(context),
    );
  }

  Future<void> _showDialog(BuildContext context) async {
    final current = await getApiUrl();
    if (!context.mounted) return;

    final ctrl = TextEditingController(text: current);
    String? statusMsg;
    bool statusOk = false;
    bool scanning = false;
    double scanProgress = 0;

    await showDialog(
      context: context,
      barrierDismissible: !scanning,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.dns_outlined, size: 20),
            SizedBox(width: 8),
            Text('Server URL'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'API URL',
                  hintText: 'http://192.168.1.x:3000',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                enabled: !scanning,
              ),
              const SizedBox(height: 10),

              // Presets
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Emulator'),
                    avatar: const Icon(Icons.phone_android, size: 14),
                    onPressed: scanning
                        ? null
                        : () => setState(() => ctrl.text = 'http://10.0.2.2:3000'),
                  ),
                  ActionChip(
                    label: const Text('Localhost'),
                    avatar: const Icon(Icons.computer, size: 14),
                    onPressed: scanning
                        ? null
                        : () => setState(() => ctrl.text = 'http://localhost:3000'),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Scan button + progress
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: scanning
                      ? null
                      : () async {
                          setState(() {
                            scanning = true;
                            scanProgress = 0;
                            statusMsg = 'Scanning network…';
                            statusOk = false;
                          });
                          final found = await discoverServer(
                            onProgress: (done, total) {
                              setState(() => scanProgress = done / total);
                            },
                          );
                          if (found != null) {
                            await saveServerUrl(found);
                            setState(() {
                              ctrl.text = found;
                              statusMsg = '✓ Found server at $found';
                              statusOk = true;
                              scanning = false;
                            });
                          } else {
                            setState(() {
                              statusMsg = '✗ No Washly server found on this network';
                              statusOk = false;
                              scanning = false;
                            });
                          }
                        },
                  icon: scanning
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_find, size: 18),
                  label: Text(scanning ? 'Scanning…' : 'Scan Network'),
                ),
              ),

              if (scanning)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: LinearProgressIndicator(value: scanProgress),
                ),

              // Status message
              if (statusMsg != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Icon(
                    statusOk ? Icons.check_circle : Icons.error_outline,
                    size: 16,
                    color: statusOk ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      statusMsg!,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusOk ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ]),
              ],
            ],
          ),
          actions: [
            // Test connection
            TextButton(
              onPressed: scanning
                  ? null
                  : () async {
                      setState(() {
                        statusMsg = 'Testing…';
                        statusOk = false;
                      });
                      final url = ctrl.text.trim().replaceAll(RegExp(r'/+$'), '');
                      try {
                        final dio = Dio(BaseOptions(
                          connectTimeout: const Duration(seconds: 4),
                          receiveTimeout: const Duration(seconds: 4),
                        ));
                        await dio.get('$url/health');
                        await saveServerUrl(url);
                        setState(() {
                          statusMsg = '✓ Connected to $url';
                          statusOk = true;
                        });
                      } catch (e) {
                        setState(() {
                          statusMsg = '✗ ${e.toString().split('\n').first}';
                          statusOk = false;
                        });
                      }
                    },
              child: const Text('Test'),
            ),
            TextButton(
              onPressed: scanning ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: scanning
                  ? null
                  : () async {
                      final url = ctrl.text.trim().replaceAll(RegExp(r'/+$'), '');
                      await saveServerUrl(url);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }
}
