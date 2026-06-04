import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../data/connection_repository.dart';
import 'lobby_provider.dart';

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

    try {
      final data = jsonDecode(rawValue) as Map<String, dynamic>;
      final ip = data['ip'] as String;
      // 5.5 — Fallback to kPort constant for consistency.
      final port = (data['port'] as int?) ?? ConnectionRepository.kPort;

      final lobby = context.read<LobbyProvider>();
      await lobby.joinRoomByAddress(ip, port);
      if (mounted) context.go('/room');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('QR không hợp lệ')));
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR để vào phòng')),
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
