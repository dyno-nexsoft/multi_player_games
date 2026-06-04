import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:party_game_hub/l10n/app_localizations.dart';
import '../data/connection_repository.dart';
import 'lobby_provider.dart';
import '../../../router.dart';

/// Màn hình quét QR code để join phòng host mà không cần mDNS discovery.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _processing = false;

  Future<void> _onDetect(String rawValue) async {
    if (_processing) return;
    setState(() => _processing = true);

    final l10n = AppLocalizations.of(context)!;
    try {
      final data = jsonDecode(rawValue) as Map<String, dynamic>;
      final ip = data['ip'] as String;
      // 5.5 — Fallback to kPort constant for consistency.
      final port = (data['port'] as int?) ?? ConnectionRepository.kPort;

      final lobby = context.read<LobbyProvider>();
      await lobby.joinRoomByAddress(ip, port);
      if (mounted) const RoomRoute().go(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.invalidQrCode)));
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanQrTitle)),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final raw = capture.barcodes.firstOrNull?.rawValue;
              if (raw != null) _onDetect(raw);
            },
          ),
          if (_processing) const Center(child: CircularProgressIndicator()),
          // Overlay khung ngắm
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
