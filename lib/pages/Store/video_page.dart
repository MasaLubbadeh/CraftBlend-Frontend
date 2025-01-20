import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../configuration/config.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({Key? key}) : super(key: key);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc('groupId')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final videoFile = data['videoFile'];

        if (videoFile == null || videoFile.isEmpty) {
          return const Center(child: Text('No videos found!'));
        }

        return ListView.builder(
          itemCount: videoFile.length,
          itemBuilder: (ctx, index) {
            return VideoPlayerWidget(videoFileName: videoFile[index]);
          },
        );
      },
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoFileName;

  const VideoPlayerWidget({Key? key, required this.videoFileName})
      : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = await _getDownloadURL(widget.videoFileName);
    if (url.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    _videoPlayerController = VideoPlayerController.network(url);

    _initializeVideoPlayerFuture =
        _videoPlayerController!.initialize().then((_) {
      setState(() => _isLoading = false);
    }).catchError((error) {
      setState(() => _isLoading = false);
    });
  }

  Future<String> _getDownloadURL(String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('videos/$fileName');
      final downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_videoPlayerController == null) {
      return const Center(child: Text('Error loading video.'));
    }

    return FutureBuilder<void>(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error initializing video: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          // The video is ready: we use a Stack to float the button on top.
          return AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: Stack(
              children: [
                // The video itself
                VideoPlayer(_videoPlayerController!),

                // A centered play/pause button
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      iconSize: 64,
                      color: Colors.grey,
                      icon: Icon(
                        _videoPlayerController!.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_videoPlayerController!.value.isPlaying) {
                            _videoPlayerController!.pause();
                          } else {
                            _videoPlayerController!.play();
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Still initializing...
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
