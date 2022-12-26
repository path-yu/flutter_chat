import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';

Widget buildBaseImage(
    {double? width = 40, double? height = 40, required String url}) {
  return ExtendedImage.network(
    width: width,
    height: height,
    fit: BoxFit.cover,
    cache: true,
    borderRadius: const BorderRadius.all(Radius.circular(30.0)),
    url,
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
