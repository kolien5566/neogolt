import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:neoglot/openai_client_singleton.dart';

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
  void initState() {
    super.initState();
    _audioPlayer.openPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.closePlayer();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
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
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });
    await _processAudio();
  }

  Future<void> _processAudio() async {
    // 打开录音文件
    final client = OpenAIClientSingleton().client;
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
      // 初始化播放器并开始从流中播放
      await _audioPlayer.startPlayerFromStream(
        codec: Codec.pcm16, // 指定解码器
        numChannels: 1, // 通道数，1 为单声道，2 为立体声
        sampleRate: 24000, // 采样率，与音频数据保持一致
        whenFinished: () {
          if (_isStreamDone == true) {
            _audioPlayer.stopPlayer();
          }
        },
      );
      // 向openai发送请求
      final resStream = await client.createChatCompletionStream(
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
      // 处理返回的音频流
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                _transcript,
                style: const TextStyle(fontSize: 16),
              ),
            ),
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
