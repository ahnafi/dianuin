import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path/path.dart' as path;

class VideoAudioPage extends StatefulWidget {
  const VideoAudioPage({super.key});

  @override
  State<VideoAudioPage> createState() => _VideoAudioPageState();
}

class _VideoAudioPageState extends State<VideoAudioPage> {
  String inputPath = '';
  String status = '';

  String outputFormat = 'mp3';
  String bitrate = '';
  String sampleRate = '';

  final formats = ['mp3', 'wav', 'aac'];

  Future<void> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      inputPath = result.files.single.path ?? '';
      setState(() {});
    }
  }

  Future<void> pickSaveLocation() async {
    // Removed: will save after conversion
  }

  Future<void> convert() async {
    if (inputPath.isEmpty) return;

    status = 'Memproses';
    setState(() {});

    final bitrateCmd = bitrate.isNotEmpty ? '-b:a ${bitrate}k' : '';
    final sampleCmd = sampleRate.isNotEmpty ? '-ar $sampleRate' : '';

    // Use temporary output first
    final tempOutput = '${inputPath}_temp.$outputFormat';
    final cmd =
        '-i "$inputPath" -vn $bitrateCmd $sampleCmd "$tempOutput"';

    FFmpegKit.executeAsync(cmd, (session) async {
      // After conversion, pick save location with bytes
      final tempFile = File(tempOutput);
      if (await tempFile.exists()) {
        final bytes = await tempFile.readAsBytes();
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan Audio sebagai',
          fileName: 'audio.$outputFormat',
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
      appBar: AppBar(title: Text('Video to Audio')),
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
                message: 'Pilih format output audio',
                child: DropdownButton(
                  value: outputFormat,
                  items: formats.map((f) {
                    return DropdownMenuItem(value: f, child: Text(f));
                  }).toList(),
                  onChanged: (v) => setState(() => outputFormat = v.toString()),
                ),
              ),

              field('Bitrate kbps', 'contoh 128 (opsional)', (v) => bitrate = v),
              field('Sample Rate Hz', 'contoh 44100 (opsional)', (v) => sampleRate = v),

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
