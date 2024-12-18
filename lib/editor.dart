import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:smartclock/util/config.dart';

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  TextEditingController? _controller;

  @override
  Widget build(BuildContext context) {
    final configModel = context.read<ConfigModel>();

    const encoder = JsonEncoder.withIndent("  ");
    final defaultInput = encoder.convert(configModel.config);
    _controller ??= TextEditingController(text: defaultInput);

    // Full screen text editor
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuration Editor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              final newConfig = jsonDecode(_controller!.text);
              configModel.setConfig(Config.fromJson(configModel.config.file, newConfig));
              Navigator.pop(context);
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            style: const TextStyle(color: Colors.black, fontFamily: 'RobotoMono'),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Enter JSON here",
              fillColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
