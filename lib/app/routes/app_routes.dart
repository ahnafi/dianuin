import 'package:dianuin/app/pages/home_page.dart';
import 'package:dianuin/app/pages/video_convert_page.dart';
import 'package:dianuin/app/pages/video_gif_page.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const String home = '/';
  static const String convertVideo = '/convertvideo';
  static const String videogif = '/videogif';

  static final routes = [
    GetPage(name: home, page: () => HomePage()),
    GetPage(name: convertVideo, page: () => VideoConvertPage()),
    GetPage(name: videogif, page: () => VideoGifPage()),
  ];
}