import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final Telephony telephony = Telephony.instance;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Forwarder',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  String _status = 'Starting...';
  int _messagesSeen = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
    _initSms();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('server_url') ?? '';
    });
  }

  Future<void> _saveUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _urlController.text.trim());
    setState(() {
      _status = 'Server URL saved';
    });
  }

  Future<void> _initSms() async {
    try {
      setState(() => _status = 'Requesting permission...');
      bool? granted = await telephony.requestPhoneAndSmsPermissions;

      setState(() => _status = 'Permission result: $granted');

      if (granted != true) {
        setState(() => _status = 'SMS permission denied (granted=$granted)');
        return;
      }

      setState(() => _status = 'Setting up SMS listener...');

      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          setState(() {
            _messagesSeen++;
          });
          _forwardSms(message);
        },
        listenInBackground: false,
      );

      setState(() {
        _status = 'Listening for SMS (setup complete)';
      });
    } catch (e) {
      setState(() {
        _status = 'ERROR during SMS setup: $e';
      });
    }
  }

  Future<void> _forwardSms(SmsMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('server_url');
    if (url == null || url.isEmpty) {
      setState(() => _status = 'Got SMS but no URL saved!');
      return;
    }

    try {
      setState(() => _status = 'Sending to server...');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': message.address,
          'body': message.body,
        }),
      );
      setState(() {
        _status = 'Forwarded! Server responded: ${response.statusCode}';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to forward: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMS Forwarder')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Server URL to receive forwarded SMS:'),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'https://yourserver.com/receive-sms',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveUrl,
              child: const Text('Save URL'),
            ),
            const SizedBox(height: 24),
            Text('Status: $_status'),
            const SizedBox(height: 12),
            Text('Messages received by listener: $_messagesSeen'),
          ],
        ),
      ),
    );
  }
}
