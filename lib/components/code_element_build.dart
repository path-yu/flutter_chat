import 'package:flutter/material.dart';
import 'package:flutter_chat/provider/current_brightness.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';

    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      language = lg.substring(9);
    }
    return Builder(builder: (context) {
      return Container(
        width: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
            .size
            .width,
        color: Colors.red,
        child: HighlightView(
          // The original code to be highlighted
          element.textContent,

          // Specify language
          // It is recommended to give it a value for performance
          language: language,

          // Specify highlight theme
          // All available themes are listed in `themes` folder
          theme: context.watch<CurrentBrightness>().value == Brightness.light
              ? atomOneLightTheme
              : atomOneDarkTheme,

          // Specify padding
          padding: const EdgeInsets.all(4),

          // Specify text style
          textStyle: GoogleFonts.robotoMono(),
        ),
      );
    });
  }
}
