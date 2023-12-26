// ignore_for_file: file_names

import 'dart:io';

import 'package:flutter/foundation.dart';

var defaultAvatar = 'https://avatars.githubusercontent.com/u/59117479?v=4';
var defaultSuggest = "There's nothing here";
//web
const googleOAuthWebClientId =
    '928535285999-i9qetp9cncn8nrbjglud9qpbfpnta7ku.apps.googleusercontent.com';
// android
const googleOAuthAndroidClientId =
    '928535285999-h4mm4c4ngdgsg1571js752k9ut252802.apps.googleusercontent.com';
//ios
const googleOAuthIosClientId =
    '928535285999-4nops9nmapsplpp9relpo0vuthpc4h0u.apps.googleusercontent.com';

final googleOAuthClientId = kIsWeb
    ? googleOAuthWebClientId
    : Platform.isAndroid
        ? googleOAuthAndroidClientId
        : googleOAuthIosClientId;
