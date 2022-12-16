import 'package:flutter/material.dart';
import 'package:flutter_chat/components/build_base_image.dart';
import 'package:flutter_chat/components/common.dart';
import 'package:flutter_chat/components/hide_key_bord.dart';

import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_3.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_4.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatPage extends StatefulWidget {
  final List? parentMessageList;
  const ChatPage({super.key, this.parentMessageList});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List messageList = [];

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    print(widget.parentMessageList);
  }

  @override
  Widget build(BuildContext context) {
    return HideKeyboard(
      child: Scaffold(
        appBar: buildAppBar('Chat page', context),
        body: Column(
          children: <Widget>[
            Expanded(
                child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                var ele = ChatBubble(
                  clipper: ChatBubbleClipper4(
                      type: index.isOdd
                          ? BubbleType.receiverBubble
                          : BubbleType.sendBubble),
                  backGroundColor: const Color(0xffE7E7ED),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: const Text(
                      "what are you doing?",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                );
                return Container(
                  padding: EdgeInsets.all(ScreenUtil().setWidth(10)),
                  child: Row(
                    mainAxisAlignment: index.isOdd
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (index.isOdd)
                        ClipOval(
                          child: buildBaseCircleImage(
                              url:
                                  'https://avatars.githubusercontent.com/u/52821367?v=4'),
                        ),
                      if (index.isOdd)
                        Transform.translate(
                          offset: const Offset(5, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    left: ScreenUtil().setWidth(10)),
                                child: const Text(
                                  'path-yu',
                                  style: TextStyle(color: Colors.black45),
                                ),
                              ),
                              ele
                            ],
                          ),
                        )
                      else
                        Transform.translate(
                          offset: const Offset(-5, 0),
                          child: ele,
                        ),
                      if (index.isEven)
                        buildBaseCircleImage(
                            url:
                                'https://avatars.githubusercontent.com/u/52821367?v=4')
                    ],
                  ),
                );
              },
              itemCount: 50,
            )),
            Container(
                padding: EdgeInsets.all(ScreenUtil().setWidth(5)),
                decoration: BoxDecoration(
                    border: Border(
                  top: BorderSide(
                      color: const Color(
                        0xFFDFDFDF,
                      ),
                      width: ScreenUtil().setWidth(1)),
                )),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  buildIconButton(Icons.image, () {},
                      size: 20, iconColor: Colors.blue),

                  // First child is enter comment text input
                  Expanded(
                    child: TextFormField(
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'some message',
                        isDense: true,
                        contentPadding: EdgeInsets.all(10),
                        fillColor: Colors.white,
                        filled: true, // dont forget this line
                      ),
                    ),
                  ),
                  // Second child is button
                  buildIconButton(Icons.send, () {},
                      size: 20, iconColor: Colors.blue),
                ])),
          ],
        ),
      ),
    );
  }
}
