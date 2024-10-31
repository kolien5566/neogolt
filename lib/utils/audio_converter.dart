import 'dart:convert';
import 'dart:typed_data';

class AudioConverter {
  static Uint8List pcmToWav(List<int> pcmData, int sampleRate) {
    final int bitsPerSample = 16;
    final int bytesPerSample = bitsPerSample ~/ 8;
    final int numChannels = 1; // Mono
    final int headerSize = 44;
    final int dataSize = pcmData.length;
    final int fileSize = headerSize + dataSize;

    ByteData byteData = ByteData(fileSize);

    // RIFF chunk descriptor
    byteData.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    byteData.setUint32(4, fileSize - 8, Endian.little);
    byteData.setUint32(8, 0x57415645, Endian.big); // "WAVE"

    // "fmt " sub-chunk
    byteData.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
    byteData.setUint16(22, numChannels, Endian.little); // NumChannels
    byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
    byteData.setUint32(28, sampleRate * numChannels * bytesPerSample, Endian.little); // ByteRate
    byteData.setUint16(32, numChannels * bytesPerSample, Endian.little); // BlockAlign
    byteData.setUint16(34, bitsPerSample, Endian.little); // BitsPerSample

    // "data" sub-chunk
    byteData.setUint32(36, 0x64617461, Endian.big); // "data"
    byteData.setUint32(40, dataSize, Endian.little); // Subchunk2Size

    // Copy PCM data
    Uint8List wavFile = byteData.buffer.asUint8List();
    wavFile.setRange(headerSize, fileSize, pcmData);

    return wavFile;
  }
}
