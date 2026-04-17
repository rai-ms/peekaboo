import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:peekaboo/peekaboo.dart';

void main() {
  // Example-level configuration: silence the socket channel here and
  // forward every error to an imaginary analytics sink.
  Peekaboo.configure(PeekabooConfig(
    enabledChannels: const {LogChannel.api, LogChannel.app},
    onCapture: (entry) {
      if (entry.level.isError) {
        // pretend this is Sentry / Crashlytics / your own pipeline
        debugPrint('[analytics] ${entry.title}');
      }
    },
  ));
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'peekaboo example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      builder: (ctx, child) => PeekabooOverlay(
        theme: PeekabooTheme.defaults.copyWith(
          floatingButtonColor: const Color(0xFF7B1F70),
          panelAccent: const Color(0xFFEC135B),
          chipBackgroundSelected: const Color(0xFFEC135B),
        ),
        child: child ?? const SizedBox(),
      ),
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'))
    ..interceptors.add(PeekabooDioInterceptor());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('peekaboo example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tap the floating eye in the bottom-left to inspect logs.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                Peekaboo.d('fetching posts…');
                try {
                  await _dio.get<dynamic>('/posts/1');
                } catch (_) {/* interceptor already logged */}
              },
              child: const Text('GET /posts/1'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                Peekaboo.d('creating post…');
                await _dio.post<dynamic>(
                  '/posts',
                  data: {'title': 'hello', 'body': 'from peekaboo'},
                );
              },
              child: const Text('POST /posts'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () async {
                Peekaboo.w('deliberate 404 to show error styling');
                try {
                  await _dio.get<dynamic>('/nope/does-not-exist');
                } catch (_) {}
              },
              child: const Text('GET /nope (404)'),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Peekaboo.i('app event', body: 'User tapped the info button'),
              child: const Text('Log app event'),
            ),
            OutlinedButton(
              onPressed: () => Peekaboo.e(
                'synthetic error',
                body: 'Stack trace would go here…',
              ),
              child: const Text('Log app error'),
            ),
          ],
        ),
      ),
    );
  }
}
