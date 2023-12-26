import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';

Widget buildBaseImage(
    {double? width = 40, double? height = 40, required String url}) {
  return OctoImage(
    width: width,
    height: height,
    fit: BoxFit.cover,
    image: CachedNetworkImageProvider(url),
  );
}

Widget buildBaseCircleImage(
    {double? width = 40, double? height = 40, required String url}) {
  return OctoImage.fromSet(
    width: width,
    height: height,
    fit: BoxFit.cover,
    image: CachedNetworkImageProvider(url),
    octoSet: OctoSet.circleAvatar(
      backgroundColor: Colors.white54,
      text: const Text(""),
    ),
  );
}
