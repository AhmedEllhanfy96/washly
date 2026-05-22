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
    String? testResult;
    bool testing = false;

    await showDialog(
      context: context,
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
              ),
              const SizedBox(height: 10),
              // Presets
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Emulator'),
                    avatar: const Icon(Icons.phone_android, size: 14),
                    onPressed: () =>
                        setState(() => ctrl.text = 'http://10.0.2.2:3000'),
                  ),
                  ActionChip(
                    label: const Text('Localhost'),
                    avatar: const Icon(Icons.computer, size: 14),
                    onPressed: () =>
                        setState(() => ctrl.text = 'http://localhost:3000'),
                  ),
                ],
              ),
              if (testResult != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Icon(
                    testResult!.startsWith('✓')
                        ? Icons.check_circle
                        : Icons.error_outline,
                    size: 16,
                    color: testResult!.startsWith('✓')
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: testResult!.startsWith('✓')
                              ? Colors.green[700]
                              : Colors.red[700],
                        )),
                  ),
                ]),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: testing
                  ? null
                  : () async {
                      setState(() {
                        testing = true;
                        testResult = null;
                      });
                      try {
                        final url =
                            ctrl.text.trim().replaceAll(RegExp(r'/+$'), '');
                        final dio = createDio();
                        await saveServerUrl(url);
                        await dio.get('/health').timeout(
                              const Duration(seconds: 5));
                        setState(() => testResult = '✓ Connected to $url');
                      } catch (e) {
                        setState(() => testResult = '✗ ${e.toString().split('\n').first}');
                      } finally {
                        setState(() => testing = false);
                      }
                    },
              child: testing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Test'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final url =
                    ctrl.text.trim().replaceAll(RegExp(r'/+$'), '');
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
