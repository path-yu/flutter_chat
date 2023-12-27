// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js';
import 'dart:typed_data';

import 'package:universal_html/html.dart';

class WebAudioRecorder {
  MediaRecorder? _mediaRecorder;
  final List<Blob> _recordedChunks = [];
  Completer<Uint8List>? _metadataCompleter;
  Future<void> start() async {
    final stream = await window.navigator.mediaDevices?.getUserMedia({
      'audio': true,
    });
    print(stream);
    _mediaRecorder = MediaRecorder(stream!);
    _mediaRecorder!.addEventListener('dataavailable', _handleDataAvailable);
    _mediaRecorder!.addEventListener('stop', _handleStop);
    _mediaRecorder!.start();
  }

  void _handleStop(event) async {
    final audioBlob = Blob(_recordedChunks, 'audio/mp4');
    final audioUrl = Url.createObjectUrl(audioBlob);
    _metadataCompleter!.complete(await blobToUint8List(audioBlob));
    // Do something with the recorded audio URL, like playing or downloading
    print('Recorded Audio URL: $audioUrl');
    // Clear recorded chunks for the next recording
    _recordedChunks.clear();
  }

  getBlobUrl() {
    final audioBlob = Blob(_recordedChunks, 'audio/mp4');
    final audioUrl = Url.createObjectUrl(audioBlob);
    return audioUrl;
  }

  Future<Uint8List> stop() async {
    _metadataCompleter = Completer<Uint8List>();

    if (_mediaRecorder != null) {
      _mediaRecorder!.stop();
      _mediaRecorder!.stream!.getTracks().forEach((track) {
        track.stop();
      });
    }

    // Wait for metadata and return it
    return _metadataCompleter!.future;
  }

  void resume() {
    if (_mediaRecorder != null) {
      _mediaRecorder!.resume();
    }
  }

  void pause() {
    if (_mediaRecorder != null) {
      _mediaRecorder!.pause();
    }
  }

  void dispose() {
    if (_mediaRecorder != null) {
      _mediaRecorder!.stop();
      _mediaRecorder = null;
      _recordedChunks.clear();
      _mediaRecorder!
          .removeEventListener('dataavailable', _handleDataAvailable);
      _mediaRecorder!.removeEventListener('stop', _handleStop);
    }
  }

  void _handleDataAvailable(event) {
    print("datavailable ${event.runtimeType}");
    final Blob blob = JsObject.fromBrowserObject(event)['data'];
    print("blob size: ${blob.size}");
    if (blob.size > 0) {
      _recordedChunks.add(blob);
    }
  }

  Future<Uint8List> getMetaData() {
    return blobToUint8List(Blob(_recordedChunks, 'audio/mp4'));
  }

  void download(String path) {
    // Simple download code for web testing
    final anchor = document.createElement('a') as AnchorElement
      ..href = path
      ..style.display = 'none'
      ..download = 'audio${DateTime.now().millisecondsSinceEpoch}.mp4';
    document.body!.children.add(anchor);
    anchor.click();
    document.body!.children.remove(anchor);
  }
}

Future<Uint8List> blobToUint8List(Blob blob) async {
  Completer<Uint8List> completer = Completer<Uint8List>();
  FileReader reader = FileReader();

  reader.onLoadEnd.listen((ProgressEvent event) {
    print('load end');
    if (reader.result is Uint8List) {
      completer.complete(reader.result as Uint8List);
    } else {
      completer.completeError('Failed to convert Blob to Uint8List');
    }
  });

  reader.onError.listen((Event event) {
    completer.completeError('Error reading Blob: ${reader.error}');
  });

  reader.readAsArrayBuffer(blob);

  return completer.future;
}
