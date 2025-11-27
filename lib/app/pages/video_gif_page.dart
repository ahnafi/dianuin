import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path/path.dart' as path;

class VideoGifPage extends StatefulWidget {
  const VideoGifPage({super.key});

  @override
  State<VideoGifPage> createState() => _VideoGifPageState();
}

class _VideoGifPageState extends State<VideoGifPage> {
  String inputPath = '';
  String status = '';

  final frameRateController = TextEditingController(text: '15');
  final widthController = TextEditingController(text: '320');
  final startController = TextEditingController(text: '0');
  final durationController = TextEditingController(text: '5');
  final speedController = TextEditingController(text: '1');

  bool loopGif = true;

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

    final fps = frameRateController.text;
    final width = widthController.text;
    final ss = startController.text;
    final t = durationController.text;
    final speed = speedController.text;
    final loopCmd = loopGif ? '' : '-loop 0';

    final filter = '[0:v] fps=$fps,scale=$width:-1:flags=lanczos,split [a][b];[a] palettegen [p];[b][p] paletteuse,setpts=${1 / double.parse(speed)}*PTS';

    // Use temporary output first
    final tempOutput = '${inputPath}_temp.gif';
    final cmd =
        '-i "$inputPath" -filter_complex "$filter" -ss $ss -t $t $loopCmd "$tempOutput"';

    FFmpegKit.executeAsync(cmd, (session) async {
      // After conversion, pick save location with bytes
      final tempFile = File(tempOutput);
      if (await tempFile.exists()) {
        final bytes = await tempFile.readAsBytes();
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Pilih Tempat Simpan',
          fileName: 'output.gif',
          type: FileType.custom,
          allowedExtensions: ['gif'],
          bytes: bytes,
        );

        if (result != null) {
          // Copy to final location if needed, but saveFile already saves
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

  Widget numField(String label, TextEditingController c) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video to GIF')),
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

              SizedBox(height: 20),
              numField('Frame Rate fps', frameRateController),
              numField('Lebar Resolusi px', widthController),
              numField('Start detik', startController),
              numField('Durasi detik', durationController),
              numField('Kecepatan Playback 0.5 sampai 2', speedController),

              Row(
                children: [
                  Checkbox(
                    value: loopGif,
                    onChanged: (v) => setState(() => loopGif = v ?? true),
                  ),
                  Text('Loop')
                ],
              ),

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
