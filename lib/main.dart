import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';

void main() {
  runApp(const ProviderScope(child: WmsApp()));
}

class WmsApp extends ConsumerWidget {
  const WmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            networkStatus.when(
              data: (status) {
                final isOnline = status == NetworkStatus.online;
                return Container(
                  width: double.infinity,
                  color: isOnline ? Colors.green.shade100 : Colors.red.shade100,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isOnline ? 'Online' : 'Offline',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          isOnline ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Connectivity check failed: $error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: Text('WMS App Skeleton')),
          ],
        ),
      ),
    );
  }
}
