import 'dart:async';

import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/widgets/sidebar/error_info_widget.dart';
import 'package:smartclock/config/config.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class StickyNote extends StatelessWidget {
  const StickyNote({super.key, required this.memory, required this.size});

  final alexa.Memory memory;
  final double size;

  String _collapseNewlines(String text) {
    return text.replaceAll(RegExp(r'[\r\n]+'), '\n');
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigModel>().config;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.all(config.clock.padding),
      child: Center(
        child: Text(
          _collapseNewlines(memory.value!),
          style: TextStyle(
            fontSize: config.alexa.noteFontSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 4,
        ),
      ),
    );
  }
}

class StickyNotes extends StatefulWidget {
  const StickyNotes({super.key});

  @override
  State<StickyNotes> createState() => _StickyNotesState();
}

class _StickyNotesState extends State<StickyNotes> {
  StreamSubscription<void>? _subscription;
  Future<List<alexa.Memory>>? _futureMemories;
  alexa.QueryClient? _client;
  Config? _config;

  @override
  void initState() {
    super.initState();
    _client = context.read<alexa.QueryClient>();
    _config = context.read<ConfigModel>().config;
    _futureMemories = _fetchMemories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = context.read<StreamController<ClockEvent>>().stream;
    _subscription?.cancel();
    _subscription = stream.listen((event) {
      if (event.event == ClockEvents.refetch) {
        setState(() {
          _futureMemories = _fetchMemories();
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  Future<List<alexa.Memory>> _fetchMemories() async {
    if (_config == null) return List.empty();
    final memories = await _client?.getMemories(_config!.alexa.userId);
    memories?.sort((b, a) => a.updatedDateTime!.compareTo(b.updatedDateTime!));
    return memories ?? List.empty();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigModel>().config;

    return FutureBuilder(
      future: _futureMemories,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorInfoWidget(title: "Sticky Notes", message: "Error loading sticky notes: ${snapshot.error}");
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = config.alexa.noteColumns;
            final size = (constraints.maxWidth - ((columns - 1) * config.clock.padding)) / columns;
            final notes = snapshot.data!.take(columns).map((memory) => StickyNote(memory: memory, size: size)).toList();

            return Container(
              height: size,
              margin: EdgeInsets.only(bottom: config.clock.padding),
              child: Row(
                children: [
                  for (final memory in notes) ...[
                    memory,
                    if (memory != notes.last) SizedBox(width: config.clock.padding),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
