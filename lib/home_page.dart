import 'package:flutter/material.dart';
import 'package:neoglot/config_drawer.dart';
import 'package:neoglot/voice_chat_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("RealTime Traslator"),
        centerTitle: true,
      ),
      body: const VoiceChatPage(),
      drawer: ConfigDrawer(),
    );
  }
}
