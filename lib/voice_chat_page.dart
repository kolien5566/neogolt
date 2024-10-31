import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:neoglot/utils/audio_converter.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:neoglot/openai_client_singleton.dart';

class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({super.key});

  @override
  _VoiceChatPageState createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage> {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isProcessing = false;
  String _recordingPath = '';
  String _transcript = '';

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
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });
      await _processAudio();
    } catch (e) {
      print('Error stopping recording: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processAudio() async {
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
      final resStream = await client.createChatCompletionStream(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.model(ChatCompletionModels.gpt4oAudioPreview),
          modalities: [ChatCompletionModality.text, ChatCompletionModality.audio],
          audio: const ChatCompletionAudioOptions(
            voice: ChatCompletionAudioVoice.alloy,
            format: ChatCompletionAudioFormat.pcm16,
          ),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts([
                const ChatCompletionMessageContentPart.text(
                  text: 'translate this Chinese into English',
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

      List<int> audioBuffer = [];
      String partialTranscript = '';

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
            final decodedAudio = base64Decode(choice.delta.audio!.data!);
            audioBuffer.addAll(decodedAudio);

            // 当积累了足够的音频数据时，转换并播放它
            if (audioBuffer.length > 0) {
              // 可以调整这个阈值
              final wavData = AudioConverter.pcmToWav(audioBuffer, 24000);
              await _playAudioChunk(wavData);
              audioBuffer.clear();
            }
          }
        }
      }

      // 处理剩余的音频数据
      if (audioBuffer.isNotEmpty) {
        final wavData = AudioConverter.pcmToWav(audioBuffer, 24000);
        await _playAudioChunk(wavData);
      }
    } catch (e) {
      print('Error processing audio: $e');
    }
  }

  Future<void> _playAudioChunk(Uint8List audioData) async {
    try {
      final audioSource = MemoryAudioSource(audioData);
      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio chunk: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
            _isRecording ? 'Recording...' : (_isProcessing ? 'Processing...' : 'Hold to Record'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Transcript: $_transcript',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MemoryAudioSource extends StreamAudioSource {
  final Uint8List bytes;

  MemoryAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}
