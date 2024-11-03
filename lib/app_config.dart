import 'package:flutter/foundation.dart';
import 'package:http/io_client.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig extends ChangeNotifier {
  bool _useProxy = false;
  String _apiKey = '';
  String _language1 = 'Chinese';
  String _language2 = 'English';
  OpenAIClient? _openAIClient;
  late SharedPreferences _prefs;

  bool get useProxy => _useProxy;
  String get apiKey => _apiKey;
  String get language1 => _language1;
  String get language2 => _language2;
  OpenAIClient get openAIClient => _openAIClient!;

  // 初始化方法，从 SharedPreferences 加载配置
  Future<void> init() async {
    await dotenv.load(fileName: ".env");
    _prefs = await SharedPreferences.getInstance();
    _useProxy = _prefs.getBool('useProxy') ?? false;
    // _apiKey = _prefs.getString('apiKey') ?? '';
    _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    _language1 = _prefs.getString('language1') ?? 'Chinese';
    _language2 = _prefs.getString('language2') ?? 'English';
    _updateOpenAIClient();
    notifyListeners();
  }

  void setUseProxy(bool value) {
    if (_useProxy != value) {
      _useProxy = value;
      _prefs.setBool('useProxy', value);
      _updateOpenAIClient();
      notifyListeners();
    }
  }

  void setApiKey(String value) {
    if (_apiKey != value) {
      _apiKey = value;
      _prefs.setString('apiKey', value);
      _updateOpenAIClient();
      notifyListeners();
    }
  }

  void setLanguage1(String value) {
    if (value != _language2 && _language1 != value) {
      _language1 = value;
      _prefs.setString('language1', value);
      notifyListeners();
    }
  }

  void setLanguage2(String value) {
    if (value != _language1 && _language2 != value) {
      _language2 = value;
      _prefs.setString('language2', value);
      notifyListeners();
    }
  }

  void _updateOpenAIClient() {
    if (_apiKey.isNotEmpty) {
      HttpClient httpClient;
      if (_useProxy) {
        httpClient = HttpClient()
          ..findProxy = (uri) {
            return "PROXY localhost:7890;";
          };
      } else {
        httpClient = HttpClient();
      }
      final ioClient = IOClient(httpClient);

      _openAIClient?.endSession();
      _openAIClient = OpenAIClient(
        apiKey: _apiKey,
        client: ioClient,
      );
    }
  }

  void dispose() {
    _openAIClient?.endSession();
    super.dispose();
  }
}
