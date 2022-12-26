import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class PhotoView extends StatefulWidget {
  final List<String> pics;
  final int showIndex;
  const PhotoView({super.key, required this.pics, required this.showIndex});

  @override
  State<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> {
  int currentIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      currentIndex = widget.showIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.black,
      body: ExtendedImageGesturePageView.builder(
        itemBuilder: (BuildContext context, int index) {
          var url = widget.pics[index];
          Widget image = ExtendedImage.network(
            url,
            fit: BoxFit.contain,
            mode: ExtendedImageMode.gesture,
            cache: true,
          );
          image = Container(
            padding: const EdgeInsets.all(5.0),
            child: image,
          );
          if (index == currentIndex) {
            return Hero(
              tag: url + index.toString(),
              child: image,
            );
          } else {
            return image;
          }
        },
        itemCount: widget.pics.length,
        onPageChanged: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
        controller: ExtendedPageController(
          initialPage: currentIndex,
        ),
        scrollDirection: Axis.horizontal,
      ),
    );
  }
}
