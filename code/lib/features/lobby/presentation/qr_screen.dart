import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import '../data/connection_repository.dart';
import 'lobby_provider.dart';

/// Màn hình hiển thị QR code để client quét vào phòng.
class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  String? _qrData;

  @override
  void initState() {
    super.initState();
    _loadQrData();
  }

  Future<void> _loadQrData() async {
    final lobby = context.read<LobbyProvider>();
    final ip = await lobby.getHostIp();
    if (mounted) {
      setState(() {
        _qrData = jsonEncode({
          'ip': ip ?? '?',
          'port': ConnectionRepository.kPort,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.qrDialogTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Center(
        child: _qrData == null
            ? const CircularProgressIndicator()
            : QrImageView(data: _qrData!, size: 280),
      ),
    );
  }
}
