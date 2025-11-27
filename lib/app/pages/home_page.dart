import 'package:dianuin/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Row(
        children: [
          ElevatedButton(
            onPressed: () {
              Get.toNamed(AppRoutes.convertVideo);
            },
            child: const Text('Convert Video'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              Get.toNamed(AppRoutes.videogif);
            },
            child: const Text('Video to GIF'),
          ),
        ],
      ),
    );
  }

}