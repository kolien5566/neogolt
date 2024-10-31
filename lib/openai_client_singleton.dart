import 'dart:io';
import 'package:http/io_client.dart';
import 'package:openai_dart/openai_dart.dart';

class OpenAIClientSingleton {
  static final OpenAIClientSingleton _instance = OpenAIClientSingleton._internal();

  factory OpenAIClientSingleton() {
    return _instance;
  }

  OpenAIClientSingleton._internal();

  late OpenAIClient _client;
  OpenAIClient get client => _client;

  void initialize({required String apiKey, String? baseUrl}) {
    final client = HttpClient()
      ..findProxy = (uri) {
        return "PROXY localhost:7890;";
      };
    final ioClient = IOClient(client);

    _client = OpenAIClient(
      apiKey: apiKey,
      baseUrl: baseUrl,
      client: ioClient,
    );
  }

  void endSession() async {
    _client.endSession();
  }
}
                // ChatCompletionMessageContentPart.audio(
                //   inputAudio: ChatCompletionMessageInputAudio(
                //     data: audioBase64,
                //     format: ChatCompletionMessageInputAudioFormat.wav,
                //   ),
                // ),