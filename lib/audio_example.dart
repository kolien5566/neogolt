// ignore_for_file: avoid_print
import 'dart:async';
import 'package:neoglot/openai_client_singleton.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  OpenAIClientSingleton().initialize(
    apiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
  );
  final client = OpenAIClientSingleton().client;
  await _chatCompletions(client);
}

Future<void> _chatCompletions(final OpenAIClient client) async {
  final res = await client.createChatCompletion(
    request: const CreateChatCompletionRequest(
      model: ChatCompletionModel.model(
        ChatCompletionModels.gpt4oAudioPreview,
      ),
      modalities: [
        ChatCompletionModality.text,
        ChatCompletionModality.audio,
      ],
      audio: ChatCompletionAudioOptions(
        voice: ChatCompletionAudioVoice.alloy,
        format: ChatCompletionAudioFormat.wav,
      ),
      messages: [
        ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.parts([
            ChatCompletionMessageContentPart.text(
              text: 'Do what the recording says',
            ),
            ChatCompletionMessageContentPart.audio(
              inputAudio: ChatCompletionMessageInputAudio(
                data: 'UklGRoYZAQBXQVZFZm10I...//X//v8FAOj/GAD+/7z/',
                format: ChatCompletionMessageInputAudioFormat.wav,
              ),
            ),
          ]),
        ),
      ],
    ),
  );
  final choice = res.choices.first;
  final audio = choice.message.audio;
  print(audio?.id);
  print(audio?.transcript);
}
