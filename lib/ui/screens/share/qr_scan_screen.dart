import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../services/share/share_link.dart';
import '../../widgets/show_msg.dart';
import '../../widgets/cc_app_bar.dart';

/// Builds the camera view; [onText] gets every text the camera reads. Replaced
/// in tests, where there is no camera.
typedef ScannerBuilder = Widget Function(void Function(String text) onText);

Widget _cameraScanner(void Function(String) onText) => MobileScanner(
      onDetect: (capture) {
        for (final b in capture.barcodes) {
          final v = b.rawValue;
          if (v != null) onText(v);
        }
      },
    );

/// Reads a QR code of a share and returns its [ShareLink]; any other code is
/// ignored with a short notice.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, this.scannerBuilder = _cameraScanner, this.allowLoopback = false});

  final ScannerBuilder scannerBuilder;
  final bool allowLoopback;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _done = false;
  DateTime? _lastNotice;

  void _onText(String text) {
    if (_done) return;
    final link = parseShareLink(text, allowLoopback: widget.allowLoopback);
    if (link != null) {
      _done = true;
      Navigator.of(context).pop(link);
      return;
    }
    final now = DateTime.now();
    if (_lastNotice == null || now.difference(_lastNotice!) > const Duration(seconds: 3)) {
      _lastNotice = now;
      showMsg(context, context.l10n.scanNotCodecore);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: CcAppBar(title: l.scanTitle),
      body: widget.scannerBuilder(_onText),
    );
  }
}

/// Asks for the camera, then opens the scanner. Without the permission it says
/// why and offers the app settings. Returns the link read, or null.
Future<ShareLink?> scanShareLink(BuildContext context) async {
  final l = context.l10n;
  final status = await Permission.camera.request();
  if (!context.mounted) return null;
  if (!status.isGranted) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.scanCameraDenied),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(ctx);
            },
            child: Text(l.scanOpenSettings),
          ),
        ],
      ),
    );
    return null;
  }
  return Navigator.of(context).push<ShareLink>(MaterialPageRoute(builder: (_) => const QrScanScreen()));
}
