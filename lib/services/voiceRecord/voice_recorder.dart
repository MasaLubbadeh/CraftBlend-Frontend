import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class VoiceRecorder {
  FlutterSoundRecorder? _recorder;
  String? _filePath;

  VoiceRecorder() {
    _recorder = FlutterSoundRecorder();
  }

  Future<void> initRecorder() async {
    await _recorder!.openRecorder();
  }

  Future<String?> startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath =
        '${directory.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: _filePath);
    return _filePath;
  }

  Future<void> stopRecording() async {
    await _recorder!.stopRecorder();
  }

  void dispose() {
    _recorder!.closeRecorder();
  }

  String? get filePath => _filePath;
}
