import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:provider/provider.dart';
import 'app_config.dart';

class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({super.key});

  @override
  _VoiceChatPageState createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage> {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isStreamDone = false;
  String _recordingPath = '';
  String _transcript = '';

  @override
  void initState() async {
    super.initState();
    await _audioRecorder.hasPermission();
    _audioPlayer.openPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.closePlayer();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final appConfig = Provider.of<AppConfig>(context, listen: false);
    if (appConfig.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set your API key in the configuration drawer.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (await _audioRecorder.hasPermission()) {
      _audioPlayer.stopPlayer();
      final directory = await getTemporaryDirectory();
      _recordingPath = '${directory.path}/audio.wav';
      const recordConfig = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        bitRate: 128000,
      );
      await _audioRecorder.start(recordConfig, path: _recordingPath);
      setState(() {
        _isRecording = true;
        _transcript = '';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording == true) {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });
      await _processAudio();
    }
  }

  Future<void> _processAudio() async {
    final appConfig = Provider.of<AppConfig>(context, listen: false);
    final audioFile = File(_recordingPath);
    if (!await audioFile.exists()) {
      print('Audio file does not exist');
      return;
    }
    final audioBytes = await audioFile.readAsBytes();
    if (audioBytes.isEmpty) {
      print('Audio file is empty');
      return;
    }
    final audioBase64 = base64Encode(audioBytes);

    try {
      await _audioPlayer.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 24000,
        whenFinished: () {
          if (_isStreamDone == true) {
            _audioPlayer.stopPlayer();
          }
        },
      );

      final resStream = await appConfig.openAIClient.createChatCompletionStream(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.model(ChatCompletionModels.gpt4oAudioPreview),
          modalities: [ChatCompletionModality.text, ChatCompletionModality.audio],
          audio: const ChatCompletionAudioOptions(
            voice: ChatCompletionAudioVoice.echo,
            format: ChatCompletionAudioFormat.pcm16,
          ),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts([
                const ChatCompletionMessageContentPart.text(
                  text: 'Translate to Chinese if English, to English if Chinese.',
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

      String partialTranscript = '';
      _isStreamDone = false;
      await for (final chunk in resStream) {
        final choice = chunk.choices.first;
        if (choice.delta.audio != null) {
          if (choice.delta.audio!.transcript != null) {
            partialTranscript += choice.delta.audio!.transcript!;
            setState(() {
              _transcript = partialTranscript;
            });
          }
          if (choice.delta.audio!.data != null) {
            _isProcessing = false;
            final decodedAudio = base64Decode(choice.delta.audio!.data!);
            _audioPlayer.foodSink!.add(FoodData(decodedAudio));
          }
        }
      }
      _isStreamDone = true;
    } catch (e) {
      print('Error processing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing audio: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              if (_transcript.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close, size: 24),
                  onPressed: () {
                    _audioPlayer.stopPlayer();
                    setState(() {
                      _transcript = '';
                    });
                  },
                ),
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    _transcript,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : (_isProcessing ? Colors.orange : Colors.blue),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : (_isProcessing ? Icons.hourglass_empty : Icons.mic_none),
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isRecording ? 'Recording' : (_isProcessing ? 'Processing' : 'Hold to Record'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
