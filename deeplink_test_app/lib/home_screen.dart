import 'dart:async';

import 'package:flutter/material.dart';

import 'deeplink_listener.dart';
import 'deeplink_parser.dart';
import 'received_deeplink.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.listener});

  final DeeplinkListener? listener;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final _testUris = <String, Uri>{
    'Test Home': Uri.parse('deeplinktest://home'),
    'Test Profile': Uri.parse('deeplinktest://profile'),
    'Test Transfer': Uri.parse('deeplinktest://transfer?id=123&amount=500'),
    'Test Product': Uri.parse('deeplinktest://product/42?source=deeplink_book'),
  };

  StreamSubscription<Uri>? _subscription;
  ReceivedDeeplink? _lastReceived;
  Object? _lastError;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _startListening() async {
    final listener = widget.listener;
    if (listener == null) {
      return;
    }

    try {
      final initialUri = await listener.getInitialUri();
      if (!mounted) {
        return;
      }
      if (initialUri != null) {
        _processUri(initialUri);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _lastError = error;
        });
      }
    }

    _subscription = listener.uriStream.listen(
      _processUri,
      onError: (Object error) {
        if (mounted) {
          setState(() {
            _lastError = error;
          });
        }
      },
    );
  }

  void _processUri(Uri uri) {
    setState(() {
      _lastError = null;
      _lastReceived = parseDeeplink(uri);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Deeplink Test App')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Status:', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_statusText),
          if (_lastError != null) ...[
            const SizedBox(height: 8),
            Text('Listener error: $_lastError'),
          ],
          const SizedBox(height: 24),
          Text('Last received deeplink:', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          _DeeplinkDetails(received: _lastReceived),
          const SizedBox(height: 24),
          Text('Parser test buttons:', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _testUris.entries)
                OutlinedButton(
                  onPressed: () => _processUri(entry.value),
                  child: Text(entry.key),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String get _statusText {
    if (_lastReceived == null) {
      return 'Waiting for deeplink';
    }

    return 'Received deeplink';
  }
}

class _DeeplinkDetails extends StatelessWidget {
  const _DeeplinkDetails({required this.received});

  final ReceivedDeeplink? received;

  @override
  Widget build(BuildContext context) {
    final received = this.received;
    if (received == null) {
      return const Text('Waiting for deeplink');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(label: 'Raw URI', value: received.uri.toString()),
        _DetailRow(label: 'Scheme', value: _emptyLabel(received.uri.scheme)),
        _DetailRow(label: 'Host', value: _emptyLabel(received.uri.host)),
        _DetailRow(label: 'Path', value: _emptyLabel(received.uri.path)),
        _ParameterSection(
          title: 'Query Parameters',
          values: received.uri.queryParameters,
        ),
        _ParameterSection(
          title: 'Path Parameters',
          values: received.pathParameters,
        ),
        _DetailRow(label: 'Mapped Screen', value: received.destination),
        _DetailRow(label: 'Received At', value: received.receivedAt.toString()),
      ],
    );
  }

  String _emptyLabel(String value) {
    return value.isEmpty ? '(empty)' : value;
  }
}

class _ParameterSection extends StatelessWidget {
  const _ParameterSection({required this.title, required this.values});

  final String title;
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          if (values.isEmpty)
            const Text('(empty)')
          else
            for (final entry in values.entries)
              Text('${entry.key} = ${entry.value}'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}
