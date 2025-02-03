import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../configuration/config.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../configuration/config.dart';

class VideoPage extends StatefulWidget {
  final String videoFile;

  const VideoPage({Key? key, required this.videoFile}) : super(key: key);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  VideoPlayerController? _videoPlayerController;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final url = await _getDownloadURL(widget.videoFile);
    if (url.isEmpty) {
      // Fallback to a default video if the URL is empty
      final fallbackVideo =
          await _getDownloadURL('addProduct.mp4'); // Default video
      if (fallbackVideo.isNotEmpty) {
        _videoPlayerController = VideoPlayerController.network(fallbackVideo);
      }
    } else {
      _videoPlayerController = VideoPlayerController.network(url);
    }

    if (_videoPlayerController != null) {
      _initializeVideoPlayerFuture = _videoPlayerController!.initialize();
    }
    setState(() {});
  }

  Future<String> _getDownloadURL(String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('videos/$fileName');
      return await ref.getDownloadURL();
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tutorial Video',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white70,
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: _videoPlayerController == null
          ? const Center(child: Text(''))
          : Center(
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController!),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
      floatingActionButton: _videoPlayerController != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  if (_videoPlayerController!.value.isPlaying) {
                    _videoPlayerController!.pause();
                  } else {
                    _videoPlayerController!.play();
                  }
                });
              },
              child: Icon(
                _videoPlayerController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
