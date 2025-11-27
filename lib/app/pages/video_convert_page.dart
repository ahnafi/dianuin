import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path/path.dart' as path;

class VideoConvertPage extends StatefulWidget {
  @override
  State<VideoConvertPage> createState() => _VideoConvertPageState();
}

class _VideoConvertPageState extends State<VideoConvertPage> {
  String inputPath = '';
  String status = '';

  String outputFormat = 'mp4';
  String resolution = '1280x720';
  String frameRate = '30';
  String crf = '23';

  bool removeAudio = false;
  bool removeSubtitle = false;

  final formats = ['mp4', 'mkv', 'mov', 'avi'];
  final resolutions = ['Asli', '640x360', '854x480', '1280x720', '1920x1080'];
  final fpsList = ['24', '30', '60'];

  String originalResolution = '';

  // Opsi lanjutan
  String codecVideo = 'libx264';
  String bitrate = '';
  String trimStart = '';
  String trimDuration = '';
  String preset = 'medium';

  final codecOptions = ['libx264', 'libx265'];
  final presetOptions = ['ultrafast', 'veryfast', 'fast', 'medium', 'slow', 'slower'];

  Future<void> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      inputPath = result.files.single.path ?? '';
      await getVideoInfo();
      setState(() {});
    }
  }

  Future<void> getVideoInfo() async {
    if (inputPath.isEmpty) return;

    final cmd = '-i "$inputPath" -v quiet -print_format json -show_format -show_streams';

    FFmpegKit.executeAsync(cmd, (session) async {
      final output = await session.getOutput();
      if (output != null) {
        // Parse JSON to get width and height
        // For simplicity, use regex or simple parse
        final widthMatch = RegExp(r'"width":\s*(\d+)').firstMatch(output);
        final heightMatch = RegExp(r'"height":\s*(\d+)').firstMatch(output);
        if (widthMatch != null && heightMatch != null) {
          originalResolution = '${widthMatch.group(1)}x${heightMatch.group(1)}';
          setState(() {});
        }
      }
    });
  }

  Future<void> pickSaveLocation() async {
    // Removed: will save after conversion
  }

  Future<void> convert() async {
    if (inputPath.isEmpty) return;

    status = 'Memproses';
    setState(() {});

    final audioCmd = removeAudio ? '-an' : '';
    final subCmd = removeSubtitle ? '-sn' : '';
    final bitrateCmd = bitrate.isNotEmpty ? '-b:v ${bitrate}k' : '';
    final startCmd = trimStart.isNotEmpty ? '-ss $trimStart' : '';
    final durationCmd = trimDuration.isNotEmpty ? '-t $trimDuration' : '';

    // Use temporary output first
    final tempOutput = '${inputPath}_temp.$outputFormat';
    final res = resolution == 'Asli' ? originalResolution : resolution;

    final cmd =
        '-i "$inputPath" $startCmd $durationCmd -c:v $codecVideo $bitrateCmd -preset $preset -vf scale=$res -r $frameRate -crf $crf $audioCmd $subCmd "$tempOutput"';

    FFmpegKit.executeAsync(cmd, (session) async {
      // After conversion, pick save location with bytes
      final tempFile = File(tempOutput);
      if (await tempFile.exists()) {
        final bytes = await tempFile.readAsBytes();
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan hasil sebagai',
          fileName: 'output.$outputFormat',
          type: FileType.custom,
          allowedExtensions: [outputFormat],
          bytes: bytes,
        );

        if (result != null) {
          status = 'Selesai disimpan di $result';
        } else {
          status = 'Dibatalkan';
        }
        await tempFile.delete(); // Clean up temp file
      } else {
        status = 'Gagal convert';
      }
      setState(() {});
    });
  }

  Widget field(String label, String hint, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(labelText: label, hintText: hint),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Convert Video')),
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

              Tooltip(
                message: 'Pilih format output video',
                child: DropdownButton(
                  value: outputFormat,
                  items: formats.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
                  onChanged: (v) => setState(() => outputFormat = v.toString()),
                ),
              ),

              Tooltip(
                message: 'Pilih resolusi output',
                child: DropdownButton(
                  value: resolution,
                  items: resolutions.map((e) {
                    String display = e;
                    if (e == 'Asli' && originalResolution.isNotEmpty) {
                      display = 'Asli ($originalResolution)';
                    }
                    return DropdownMenuItem(value: e, child: Text(display));
                  }).toList(),
                  onChanged: (v) => setState(() => resolution = v.toString()),
                ),
              ),

              Tooltip(
                message: 'Pilih frame rate output',
                child: DropdownButton(
                  value: frameRate,
                  items: fpsList.map((e) {
                    return DropdownMenuItem(value: e, child: Text('$e fps'));
                  }).toList(),
                  onChanged: (v) => setState(() => frameRate = v.toString()),
                ),
              ),

              TextField(
                decoration: InputDecoration(
                  labelText: 'CRF (Constant Rate Factor)',
                  hintText: '1 sampai 31, lebih rendah = kualitas lebih baik',
                ),
                controller: TextEditingController(text: crf),
                onChanged: (v) => crf = v,
                keyboardType: TextInputType.number,
              ),

              Row(
                children: [
                  Tooltip(
                    message: 'Hapus audio dari video output',
                    child: Checkbox(
                      value: removeAudio,
                      onChanged: (v) => setState(() => removeAudio = v ?? false),
                    ),
                  ),
                  Text('Hapus Audio'),
                ],
              ),

              Row(
                children: [
                  Tooltip(
                    message: 'Hapus subtitle dari video output',
                    child: Checkbox(
                      value: removeSubtitle,
                      onChanged: (v) => setState(() => removeSubtitle = v ?? false),
                    ),
                  ),
                  Text('Hapus Subtitle'),
                ],
              ),

              Tooltip(
                message: 'Pilih codec video',
                child: DropdownButton(
                  value: codecVideo,
                  items: codecOptions.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (v) => setState(() => codecVideo = v.toString()),
                ),
              ),

              Tooltip(
                message: 'Pilih preset encoding (pengaruh kecepatan dan ukuran)',
                child: DropdownButton(
                  value: preset,
                  items: presetOptions.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (v) => setState(() => preset = v.toString()),
                ),
              ),

              field('Bitrate k', 'contoh 1500 (opsional)', (v) => bitrate = v),
              field('Trim start detik', 'contoh 0 (opsional)', (v) => trimStart = v),
              field('Trim durasi detik', 'contoh 10 (opsional)', (v) => trimDuration = v),

              ElevatedButton(
                onPressed: convert,
                child: Text('Convert'),
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
