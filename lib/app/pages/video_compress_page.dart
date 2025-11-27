import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class VideoCompressPage extends StatefulWidget {
  const VideoCompressPage({super.key});

  @override
  State<VideoCompressPage> createState() => _VideoCompressPageState();
}

class _VideoCompressPageState extends State<VideoCompressPage> {
  String inputPath = '';
  String status = '';

  final videoBitrateController = TextEditingController();
  final audioBitrateController = TextEditingController();

  bool isProcessing = false;
  double progressValue = 0;

  String presetCompression = 'Manual';
  String resolution = '1280x720';

  final presetOptions = ['Manual', '50%', '70%'];
  final resolutionOptions = ['1920x1080', '1280x720', '854x480', '640x360'];

  int inputSize = 0;
  int estimatedSize = 0;

  Future<void> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      inputPath = result.files.single.path ?? '';
      inputSize = File(inputPath).lengthSync();
      setState(() {});
    }
  }

  void calculateEstimate() {
    if (presetCompression == '50%') {
      estimatedSize = (inputSize * 0.5).round();
    } else if (presetCompression == '70%') {
      estimatedSize = (inputSize * 0.7).round();
    } else {
      if (videoBitrateController.text.isNotEmpty) {
        estimatedSize = inputSize;
      }
    }
    setState(() {});
  }

  Future<void> compress() async {
    if (inputPath.isEmpty) return;

    status = 'Memproses';
    isProcessing = true;
    progressValue = 0;
    setState(() {});

    String videoBitrate = videoBitrateController.text;
    String audioBitrate = audioBitrateController.text;

    if (presetCompression == '50%') {
      videoBitrate = '1000';
      audioBitrate = '96';
    }
    if (presetCompression == '70%') {
      videoBitrate = '1500';
      audioBitrate = '128';
    }

    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/compressed.mp4');

    final cmd =
        '-i "$inputPath" -c:v libx264 -b:v ${videoBitrate}k -vf scale=$resolution -c:a aac -b:a ${audioBitrate}k -progress pipe:1 "${tempFile.path}"';

    FFmpegKit.executeAsync(cmd, (session) async {
      final returnCode = await session.getReturnCode();
      if (returnCode!.isValueSuccess()) {
        final bytes = await tempFile.readAsBytes();
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan hasil kompres',
          fileName: 'compressed.mp4',
          bytes: bytes,
        );
        if (result != null) {
          status = 'Berhasil disimpan ke $result';
        } else {
          status = 'Dibatalkan';
        }
      } else {
        status = 'Gagal memproses';
      }
      await tempFile.delete();
      isProcessing = false;
      setState(() {});
    }, (logs) {
      final log = logs.getMessage();
      if (log.contains('out_time_ms')) {
        final match = RegExp(r'out_time_ms=(\d+)').firstMatch(log);
        if (match != null) {
          final timeMs = double.parse(match.group(1) ?? '0');
          progressValue = (timeMs / 300000) % 1;
          setState(() {});
        }
      }
    }, (stats) {
      // progressValue = stats.getTime() / stats.getDuration();
      setState(() {});
    });
  }

  Widget estimateBox() {
    if (estimatedSize <= 0) return Container();

    return Text('Estimasi ukuran: ${(estimatedSize / 1024 / 1024).toStringAsFixed(2)} MB');
  }

  Widget field(String label, String hint, TextEditingController c) {
    return Tooltip(
      message: hint,
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label, hintText: hint),
        keyboardType: TextInputType.number,
        onChanged: (_) => calculateEstimate(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Compress Video')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: pickVideo,
                child: Text('Pilih Video'),
              ),
              Text(inputPath.isEmpty ? 'Belum ada file' : path.basename(inputPath)),
              if (inputSize > 0) Text('Ukuran asli: ${(inputSize / 1024 / 1024).toStringAsFixed(2)} MB'),

              Tooltip(
                message: 'Pilih preset kompresi',
                child: DropdownButton(
                  value: presetCompression,
                  items: presetOptions.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
                  onChanged: (v) {
                    presetCompression = v.toString();
                    calculateEstimate();
                  },
                ),
              ),

              Tooltip(
                message: 'Pilih resolusi output',
                child: DropdownButton(
                  value: resolution,
                  items: resolutionOptions.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (v) => setState(() => resolution = v.toString()),
                ),
              ),

              if (presetCompression == 'Manual') ...[
                field('Video Bitrate kbps', 'contoh 2000', videoBitrateController),
                field('Audio Bitrate kbps', 'contoh 128', audioBitrateController),
              ],

              estimateBox(),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isProcessing ? null : compress,
                child: Text('Compress'),
              ),

              if (isProcessing)
                Column(
                  children: [
                    SizedBox(height: 20),
                    LinearProgressIndicator(value: progressValue),
                    Text('Sedang memproses'),
                  ],
                ),

              SizedBox(height: 16),
              Text(status),
            ],
          ),
        ),
      ),
    );
  }
}
