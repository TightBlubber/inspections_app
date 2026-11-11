import 'dart:async';
import 'package:flutter/material.dart';
import '../services/db.dart';

enum _Status { checking, ok, failed }

/// Two dots (read / write) showing whether the database is reachable and writable.
class DbStatusIndicator extends StatefulWidget {
  const DbStatusIndicator({super.key});

  @override
  State<DbStatusIndicator> createState() => _DbStatusIndicatorState();
}

class _DbStatusIndicatorState extends State<DbStatusIndicator> {
  static const _interval = Duration(seconds: 60);
  static const _timeout = Duration(seconds: 8);

  _Status _read = _Status.checking;
  _Status _write = _Status.checking;
  String? _readError;
  String? _writeError;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(_interval, (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<String?> _run(Future<void> Function() fn) async {
    try {
      await fn().timeout(_timeout);
      return null;
    } on TimeoutException {
      return 'Timed out after ${_timeout.inSeconds}s';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _check() async {
    if (_running) return;
    _running = true;
    if (mounted) {
      setState(() {
        _read = _Status.checking;
        _write = _Status.checking;
      });
    }
    final readErr = await _run(DbService.checkRead);
    final writeErr = await _run(DbService.checkWrite);
    _running = false;
    if (!mounted) return;
    setState(() {
      _readError = readErr;
      _writeError = writeErr;
      _read = readErr == null ? _Status.ok : _Status.failed;
      _write = writeErr == null ? _Status.ok : _Status.failed;
    });
  }

  Widget _dot(String label, _Status status, String? error) {
    final color = switch (status) {
      _Status.ok => Colors.green,
      _Status.failed => Colors.red,
      _Status.checking => Colors.grey,
    };
    final message = switch (status) {
      _Status.ok => '$label: OK',
      _Status.failed => '$label failed: $error',
      _Status.checking => '$label: checking…',
    };
    return Tooltip(
      message: message,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _check,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot('Database read', _read, _readError),
            const SizedBox(width: 6),
            _dot('Database write', _write, _writeError),
          ],
        ),
      ),
    );
  }
}
