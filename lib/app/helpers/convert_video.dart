import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';


class ConvertVideo {


void getVideoInfo() {


FFprobeKit.getMediaInformation('<file path or url>').then((session) async {  
    final information = await session.getMediaInformation();  
    if (information == null) {  
        // CHECK THE FOLLOWING ATTRIBUTES ON ERROR
        final state = FFmpegKitConfig.sessionStateToString(await session.getState());
        final returnCode = await session.getReturnCode();
        final failStackTrace = await session.getFailStackTrace();
        final duration = await session.getDuration();
        final output = await session.getOutput();
    }
});

}
}