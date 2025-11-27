import 'package:dianuin/app/pages/home_page.dart';
import 'package:dianuin/app/pages/video_page.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const String home = '/';
  static const String video = '/video';

  static final routes = [
    GetPage(name: home, page: () => HomePage()),
    GetPage(name: video, page: () => VideoPage(title: 'Video',)),
  ];
}