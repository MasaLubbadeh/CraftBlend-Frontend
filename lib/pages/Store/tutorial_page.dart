/*import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoButtonPage extends StatelessWidget {
  // Your static/public URL from Storage
  final String videoUrl =
      'https://firebasestorage.googleapis.com/v0/b/craftblend-c388a.firebasestorage.app/o/videos%2FaddNewProduct.mp4?alt=media&token=98b7dc21-8854-40a9-bfb9-2f12a4bb270a';

  VideoButtonPage({Key? key}) : super(key: key);

  Future<void> _openVideo() async {
    final uri = Uri.parse(videoUrl);
    // Attempt to launch in an external application
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $videoUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Launcher'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _openVideo,
          child: const Text('Open Video'),
        ),
      ),
    );
  }
}

*/
/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({Key? key}) : super(key: key);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  @override
  Widget build(BuildContext context) {
    print('VideoPage: Building StreamBuilder...');
    return StreamBuilder<DocumentSnapshot>(
      // Replace 'groupId' with your actual doc ID
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc('groupId')
          .snapshots(),
      builder: (context, snapshot) {
        print('VideoPage: Snapshot state: ${snapshot.connectionState}');
        if (snapshot.hasError) {
          print('VideoPage: Snapshot error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          print('VideoPage: No data or doc does not exist. Showing loader.');
          return const Center(child: CircularProgressIndicator());
        }

        // Assuming your Firestore doc has a field called "videoFile"
        // that is an array of filenames.
        final data = snapshot.data!;
        final videoFile = data['videoFile'];

        print('VideoPage: Document data => ${data.data()}');
        print('VideoPage: videoFile => $videoFile');

        if (videoFile == null || videoFile.isEmpty) {
          print('VideoPage: videoFile is null or empty.');
          return const Center(child: Text('No videos found!'));
        }

        return ListView.builder(
          itemCount: videoFile.length,
          itemBuilder: (ctx, index) {
            print(
                'VideoPage: Building VideoPlayerWidget => ${videoFile[index]}');
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
  // Make both the controller and initialization future nullable
  VideoPlayerController? _videoPlayerController;
  Future<void>? _initializeVideoPlayerFuture;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    print('VideoPlayerWidget: _initVideo() for ${widget.videoFileName}');
    final url = await _getDownloadURL(widget.videoFileName);

    if (url.isEmpty) {
      print(
          'VideoPlayerWidget: URL is empty! Possibly an error with Storage path or permissions.');
      setState(() => _isLoading = false);
      return;
    }

    print('VideoPlayerWidget: Got URL => $url');
    _videoPlayerController = VideoPlayerController.network(url);

    // Initialize the controller
    _initializeVideoPlayerFuture =
        _videoPlayerController!.initialize().then((_) {
      print('VideoPlayerWidget: VideoPlayerController initialized. '
          'Size: ${_videoPlayerController?.value.size}');
      setState(() => _isLoading = false);
    }).catchError((error) {
      print(
          'VideoPlayerWidget: Error initializing VideoPlayerController => $error');
      setState(() => _isLoading = false);
    });
  }

  Future<String> _getDownloadURL(String fileName) async {
    try {
      // e.g., your video is stored in Firebase Storage under "videos/addNewProduct.mp4"
      // so you just store "addNewProduct.mp4" in Firestore.
      final ref = FirebaseStorage.instance.ref().child('videos/$fileName');
      final downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } on FirebaseException catch (e) {
      print('VideoPlayerWidget: FirebaseException => $e');
      return '';
    } catch (e) {
      print('VideoPlayerWidget: Unknown error => $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we're still loading the URL or controller initialization, show progress
    if (_isLoading) {
      print(
          'VideoPlayerWidget: Still loading. Showing CircularProgressIndicator.');
      return const Center(child: CircularProgressIndicator());
    }

    // If the controller is null, we can't show the video
    if (_videoPlayerController == null) {
      print('VideoPlayerWidget: Controller is null. Cannot play video.');
      return const Center(
          child: Text('Error: Unable to load video controller.'));
    }

    // Use a FutureBuilder to wait on the controller's initialize() future
    return FutureBuilder<void>(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        print(
            'VideoPlayerWidget: FutureBuilder state => ${snapshot.connectionState}');
        if (snapshot.hasError) {
          print('VideoPlayerWidget: FutureBuilder error => ${snapshot.error}');
          return Center(
              child: Text('Error initializing video: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          print('VideoPlayerWidget: ConnectionState.done => video ready.');
          // Now the video is ready; build a widget to display it.
          return AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          );
        } else {
          // Still loading...
          print(
              'VideoPlayerWidget: FutureBuilder waiting => ${snapshot.connectionState}');
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  void dispose() {
    // Dispose the controller to free resources
    print(
        'VideoPlayerWidget: Disposing controller for ${widget.videoFileName}');
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
*/