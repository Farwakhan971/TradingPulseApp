import 'dart:io';
import 'dart:async';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'audio_common.dart';
import 'main.dart';
class AudioRecorderPage extends StatefulWidget {
  final FlutterSoundRecorder? recorder;
  final FlutterSoundPlayer? player;
  final Function(String) onRecordingComplete;
  final UploadFileFunction uploadFile;
  final Function(bool) onRecordingStateChanged;


  const AudioRecorderPage({
    Key? key,
    required this.recorder,
    required this.player,
    required this.onRecordingComplete,
    required this.uploadFile,
    required this.onRecordingStateChanged, // Add this line
// Add this line
  }) : super(key: key);

  @override
  AudioRecorderPageState createState() => AudioRecorderPageState();
}


class AudioRecorderPageState extends State<AudioRecorderPage> with AutomaticKeepAliveClientMixin {
  final _folderPath = Directory('/storage/emulated/0/Recordings/');
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamSubscription? _timerSubscription;
  String _currentFilePath = '', _recordedFilePath = '';
  bool _isRecording = false;
  bool _recorderInit = false, _playerInit = false;


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    initRecorder();
    initPlayer();
  }

  @override
  void dispose() {
    if (_recorder != null) {
      _recorder!.closeAudioSession();
      _recorder = null;
    }
    if (_player != null) {
      _player!.closeAudioSession();
      _player = null;
    }
    _timerSubscription?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.only(top: 75.0),
      child: Column(
        children: [
          AvatarGlow(
            animate: _isRecording,
            glowColor: Colors.white24,
            endRadius: 90,
            duration: const Duration(milliseconds: 2000),
            repeat: true,
            child: SizedBox(
              height: 150,
              width: 150,
              child: Tooltip(
                message: _isRecording ? 'Tap to Stop Recording' : 'Tap to Start Recording',
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: TextStyle(color: Colors.white),
                child: RawMaterialButton(
                  elevation: 12.0,
                  shape: const CircleBorder(),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white54,
                          Colors.white30.withOpacity(0.2), // Pink with some transparency
                        ],
                        stops: [0.0, 0.5],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 4.0,
                      ),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: _isRecording
                            ? const Icon(Icons.stop, color: Colors.red, size: 50, key: ValueKey('recording'))
                            : const Icon(Icons.mic_none_rounded, color: Colors.white, size: 50, key: ValueKey('not_recording')),
                      ),
                    ),
                  ),
                  onPressed: _toggleRecording,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15.0), // Adds a smaller padding to reduce space.
            child: Text(
              _isRecording ? 'Recording...' : '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      if (_isRecording) {
        stopRecording();
        widget.onRecordingStateChanged(false); // Recording stopped
      } else {
        startRecording();
        widget.onRecordingStateChanged(true); // Recording started
      }
      _isRecording = !_isRecording;
    });
  }



  void initRecorder() async {
    await Permission.microphone.request().then((value) async {
      if (value == PermissionStatus.granted) {
        _recorder = widget.recorder;
        await _recorder!.openAudioSession().then((value) => this._recorderInit = true);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission not granted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void initPlayer() async {
    _player = widget.player;
    await _player!.openAudioSession().then((value) => this._playerInit = true);
  }
  String? getRecordedFilePath() {
    return _recordedFilePath;
  }


  bool get isRecorderInit => _recorderInit;
  bool get isPlayerInit => _playerInit;

  void startRecording() async {
    if (!_recorderInit) return;
    await Permission.storage.request().then((status) async {
      if (status.isGranted) {
        if (!(await _folderPath.exists())) {
          _folderPath.create();
        }
        final _fileName = 'AUDIO_${DateTime.now().millisecondsSinceEpoch.toString()}.aac';
        _currentFilePath = '${_folderPath.path}$_fileName';
        setState(() {});
        _recorder!.startRecorder(toFile: _currentFilePath).then((value) {
          setState(() {
            this._isRecording = true;
          });
        });
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission not granted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
  Future<String> stopRecording() async {
    if (!_recorderInit) return '';
    String? recordPath = await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
      _recordedFilePath = recordPath!;
    });
    if (recordPath != null) {
      String audioUrl = await widget.uploadFile(File(recordPath));
      widget.onRecordingComplete(audioUrl); // Trigger the callback
      return audioUrl;
    }
    return '';
  }
  Future<Track> loadTrack(BuildContext context) async {
    Track track = Track();
    var file = File(_recordedFilePath);
    if (file.existsSync()) {
      track = Track(trackPath: file.path);
    }
    return track;
  }
}
