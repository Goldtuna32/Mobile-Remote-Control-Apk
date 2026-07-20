// widgets/wifi_discovery_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bonsoir/bonsoir.dart';
import '../services/wifi_discovery_provider.dart';

const _surface = Color(0xFF13131A);
const _accent = Color(0xFF6C63FF);
const _accentDim = Color(0x336C63FF);
const _textPrimary = Color(0xFFF0F0F8);
const _textSecondary = Color(0xFF8888AA);
const _border = Color(0xFF2A2A3A);

class WifiDiscoveryWidget extends ConsumerWidget {
  final Function(BonsoirService) onDeviceSelected;

  const WifiDiscoveryWidget({super.key, required this.onDeviceSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(bonsoirDiscoveryProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Wi-Fi Search',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Discovering active network appliances',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
              ),
              if (scanState.isScanning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: _accent,
                    strokeWidth: 2,
                  ),
                )
              else
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(bonsoirDiscoveryProvider.notifier).triggerScan();
                  },
                  icon: const Icon(
                    Icons.radar_rounded,
                    color: _accent,
                    size: 18,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _accentDim,
                    padding: const EdgeInsets.all(8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!scanState.isWifiConnected)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.amberAccent,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Connect to Wi-Fi to scan local space',
                    style: TextStyle(color: _textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else if (scanState.resolvedDevices.isEmpty && !scanState.isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No smart hardware responding to broadcasts.',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: scanState.resolvedDevices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final service = scanState.resolvedDevices[index];

                  String hostDisplay = 'Resolving target location...';

                  // Safe processing using the standard non-array host target
                  if (service is ResolvedBonsoirService) {
                    final String? networkHost = service.host;

                    if (networkHost != null && networkHost.isNotEmpty) {
                      hostDisplay = networkHost;
                    }
                  }
                  return InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onDeviceSelected(service);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _border.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tv_rounded,
                            color: _accent,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Address: $hostDisplay:${service.port}',
                                  style: const TextStyle(
                                    color: _textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: _textSecondary,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
