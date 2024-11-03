import 'package:flutter/material.dart';
import 'package:neoglot/openai_client_singleton.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:neoglot/voice_chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initializeOpenAIClient();
  }

  Future<void> _initializeOpenAIClient() async {
    await dotenv.load(fileName: ".env");
    String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    OpenAIClientSingleton().initialize(apiKey: apiKey);
  }

  @override
  Widget build(BuildContext context) {
    return const VoiceChatPage();
  }
}
