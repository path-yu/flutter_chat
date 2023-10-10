import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/common/show_toast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gallery_saver/gallery_saver.dart';

class PhotoView extends StatefulWidget {
  final List<String> pics;
  final int showIndex;
  const PhotoView({super.key, required this.pics, required this.showIndex});

  @override
  State<PhotoView> createState() => _PhotoViewState();
}

enum SampleItem { save }

class _PhotoViewState extends State<PhotoView> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      currentIndex = widget.showIndex;
    });
  }

  bool saveLook = false;
  @override
  Widget build(BuildContext context) {
    SampleItem? selectedMenu;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(
          color: Colors.white,
        ),
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<SampleItem>(
            initialValue: selectedMenu,
            position: PopupMenuPosition.under,
            // Callback that sets the selected popup menu item.
            onSelected: (SampleItem item) {
              setState(() {
                selectedMenu = item;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SampleItem>>[
              PopupMenuItem<SampleItem>(
                value: SampleItem.save,
                height: ScreenUtil().setHeight(20),
                onTap: () {
                  if (saveLook) return;
                  saveLook = true;
                  GallerySaver.saveImage(widget.pics[currentIndex]).then((res) {
                    showToast('Image is saved');
                    saveLook = false;
                  });
                },
                child: const Text('save'),
              ),
            ],
            child: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
          ),
        ],
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
              tag: url,
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
