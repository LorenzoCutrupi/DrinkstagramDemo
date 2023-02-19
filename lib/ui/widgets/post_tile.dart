import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provauth/beans/post.dart';
import 'package:provauth/ui/main/profile/post_screen.dart';
import 'package:video_player/video_player.dart';

import 'custom_image.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  bool isVideo() {
    String url = post.mediaUrl;
    if (url.contains('.mp4') || url.contains('.mov') || url.contains('.avi')) {
      return true;
    }
    return false;
  }

  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PostScreen(
                  postId: post.postId,
                  userId: post.ownerId,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => showPost(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: isVideo()
              ? Chewie(
                  controller: ChewieController(
                    showControls: false,
                      autoPlay: true,
                      looping: true,
                      videoPlayerController:
                          VideoPlayerController.network(post.mediaUrl)),
                )
              : cachedNetworkImage(post.mediaUrl),
        ) //cachedNetworkImage(post.mediaUrl),
        );
  }
}
