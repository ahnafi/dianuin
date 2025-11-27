import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/log.dart';
import 'package:ffmpeg_kit_flutter_new/session.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key, required this.title});

  final String title;

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  String logString = 'Logs will appear here...';
  bool isProcessing = false;
  String? selectedFilePath;
  String currentMode = '';
  String outputPath = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedFilePath ?? 'No file selected',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isProcessing ? null : selectFile,
                          child: const Text('Select Video File'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      logString,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ElevatedButton(
              onPressed:
                  isProcessing ? null : () => executeFFmpegCommand('software'),
              child: const Text('Software'),
            ),
            ElevatedButton(
              onPressed:
                  isProcessing ? null : () => executeFFmpegCommand('hardware'),
              child: const Text('Hardware'),
            ),
            ElevatedButton(
              onPressed:
                  isProcessing ? null : () => executeFFmpegCommand('test'),
              child: const Text('Test HW'),
            ),
            if (Platform.isIOS || Platform.isMacOS)
              ElevatedButton(
                onPressed:
                    isProcessing
                        ? null
                        : () => executeFFmpegCommand('videotoolbox'),
                child: const Text('VideoToolbox'),
              ),
            ElevatedButton(
              onPressed:
                  isProcessing
                      ? null
                      : () => executeFFmpegCommand('list_codecs'),
              child: const Text('List Codecs'),
            ),
            ElevatedButton(
              onPressed:
                  isProcessing
                      ? null
                      : () => executeFFmpegCommand('mediacodec'),
              child: const Text('MediaCodec'),
            ),
            ElevatedButton(
              onPressed:
                  isProcessing ? null : () => executeFFmpegCommand('convert_to_gif'),
              child: const Text('Convert to GIF'),
            ),
          ],
        ),
      ),
    );
  }

  void showSaveDialog(String gifPath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conversion Complete'),
          content: const Text('GIF has been created. Do you want to save it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await saveGifFile(gifPath);
              },
              child: const Text('Save GIF'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveGifFile(String gifPath) async {
    final gifFile = File(gifPath);
    final bytes = await gifFile.readAsBytes();

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save GIF File',
      fileName: 'output.gif',
      type: FileType.custom,
      allowedExtensions: ['gif'],
      bytes: bytes,
    );

    if (outputFile != null) {
      setState(() {
        logString += '\n✅ GIF saved to: $outputFile\n';
      });
      // Open the directory in file manager
      final directory = outputFile.substring(0, outputFile.lastIndexOf('/'));
      if (await canLaunchUrl(Uri.parse('file://$directory'))) {
        await launchUrl(Uri.parse('file://$directory'));
      }
    }
  }

  void selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() {
        selectedFilePath = result.files.single.path;
      });
    }
  }

  void executeFFmpegCommand(String mode) async {
    setState(() {
      isProcessing = true;
      logString = 'Starting FFmpeg processing...\n\n';
      currentMode = mode;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      File inputFile;

      if (selectedFilePath != null) {
        inputFile = File(selectedFilePath!);
      } else {
        final sampleVideoRoot = await rootBundle.load('assets/sample_video.mp4');
        inputFile = File('${tempDir.path}/sample_video.mp4');
        await inputFile.writeAsBytes(sampleVideoRoot.buffer.asUint8List());
      }

      final outputFile = File('${tempDir.path}/output.mp4');
      if (outputFile.existsSync()) await outputFile.delete();

      String command;
      String description;
      outputPath = '${tempDir.path}/output.mp4';

      switch (mode) {
        case 'software':
          command =
              '-i ${inputFile.path} -c:v mpeg4 -preset ultrafast ${outputFile.path}';
          description = 'Software encoding (MPEG-4)';
          break;
        case 'hardware':
          if (Platform.isAndroid) {
            command =
                '-i ${inputFile.path} -c:v h264_mediacodec -b:v 2M ${outputFile.path}';
            description = 'Hardware encoding (Android MediaCodec)';
          } else if (Platform.isIOS || Platform.isMacOS) {
            command =
                '-i ${inputFile.path} -c:v h264_videotoolbox -b:v 2M ${outputFile.path}';
            description = 'Hardware encoding (VideoToolbox)';
          } else {
            command =
                '-i ${inputFile.path} -c:v mpeg4 -preset ultrafast ${outputFile.path}';
            description = 'Software encoding (fallback)';
          }
          break;
        case 'test':
          command =
              '-f lavfi -i testsrc=duration=5:size=1280x720:rate=30 -c:v h264 -t 5 ${outputFile.path}';
          description = 'Hardware acceleration test';
          break;
        case 'videotoolbox':
          command =
              '-i ${inputFile.path} -c:v h264_videotoolbox -b:v 2M ${outputFile.path}';
          description = 'Hardware encoding (VideoToolbox)';
          break;
        case 'list_codecs':
          if (Platform.isAndroid) {
            command = '-hide_banner -encoders | grep -i mediacodec';
            description = 'List MediaCodec codecs';
          } else if (Platform.isIOS || Platform.isMacOS) {
            command = '-hide_banner -encoders | grep -i videotoolbox';
            description = 'List VideoToolbox codecs';
          } else {
            command = '-hide_banner -encoders';
            description = 'List all codecs';
          }
          break;
        case 'mediacodec':
          command = '-hide_banner -encoders | grep -i mediacodec';
          description = 'List MediaCodec codecs';
          break;
        case 'convert_to_gif':
          final outputGifFile = File('${tempDir.path}/output.gif');
          if (outputGifFile.existsSync()) await outputGifFile.delete();
          command = '-i ${inputFile.path} -vf "fps=15,scale=320:-1:flags=lanczos" ${outputGifFile.path}';
          description = 'Convert MP4 to GIF';
          outputPath = '${tempDir.path}/output.gif';
          break;
        default:
          command =
              '-i ${inputFile.path} -c:v mpeg4 -preset ultrafast ${outputFile.path}';
          description = 'Default encoding';
      }

      setState(() {
        logString += 'Mode: $description\n';
        logString += 'Command: $command\n\n';
        logString += 'Processing...\n';
      });

      /// Execute FFmpeg command
      await FFmpegKit.executeAsync(
        command,
        (Session session) async {
          final output = await session.getOutput();
          final returnCode = await session.getReturnCode();
          final duration = await session.getDuration();

          setState(() {
            logString += '\n✅ Processing completed!\n';
            logString += 'Return code: $returnCode\n';
            logString += 'Duration: ${duration}ms\n';
            logString += 'Output: $output\n';
            isProcessing = false;
          });

          if (currentMode == 'convert_to_gif') {
            showSaveDialog(outputPath);
          }

          debugPrint('session: $output');
        },
        (Log log) {
          setState(() {
            logString += log.getMessage();
          });
          debugPrint('log: ${log.getMessage()}');
        },
        (Statistics statistics) {
          setState(() {
            logString +=
                '\n📊 Progress: ${statistics.getSize()} bytes, ${statistics.getTime()}ms\n';
          });
          debugPrint('statistics: ${statistics.getSize()}');
        },
      );
    } catch (e) {
      setState(() {
        logString += '\n❌ Error: $e\n';
        isProcessing = false;
      });
    }
  }
}