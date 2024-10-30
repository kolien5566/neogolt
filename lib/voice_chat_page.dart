import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:neoglot/openai_client_singleton.dart';

class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({Key? key}) : super(key: key);

  @override
  _VoiceChatPageState createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage> {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String _recordingPath = '';

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _recordingPath = '${directory.path}/audio.wav';
        await _audioRecorder.start(const RecordConfig(), path: _recordingPath);
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      await _processAudio();
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _processAudio() async {
    final client = OpenAIClientSingleton().client;
    final audioFile = File(_recordingPath);
    final audioBytes = await audioFile.readAsBytes();
    final audioBase64 = base64Encode(audioBytes);

    try {
      final res = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.model(ChatCompletionModels.gpt4oAudioPreview),
          modalities: [ChatCompletionModality.text, ChatCompletionModality.audio],
          audio: const ChatCompletionAudioOptions(
            voice: ChatCompletionAudioVoice.alloy,
            format: ChatCompletionAudioFormat.wav,
          ),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts([
                const ChatCompletionMessageContentPart.text(
                  text: 'Do what the recording says',
                ),
                ChatCompletionMessageContentPart.audio(
                  inputAudio: ChatCompletionMessageInputAudio(
                    data: audioBase64,
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
      if (audio != null) {
        final audioData = base64Decode(audio.data);
        final tempDir = await getTemporaryDirectory();
        final tempAudioFile = File('${tempDir.path}/response_audio.wav');
        await tempAudioFile.writeAsBytes(audioData);
        await _audioPlayer.setFilePath(tempAudioFile.path);
        await _audioPlayer.play();
      }
    } catch (e) {
      print('Error processing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Chat')),
      body: Center(
        child: GestureDetector(
          onLongPressStart: (_) => _startRecording(),
          onLongPressEnd: (_) => _stopRecording(),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }
}
