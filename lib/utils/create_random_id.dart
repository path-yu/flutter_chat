import 'dart:math';

int createRandomId() {
  final random = Random();

  // 生成一个 8 位随机数
  final randomInt = random.nextInt((pow(10, 8) - 1).toInt());

  // 生成一个随机的一位整数作为前导数字
  final leadingDigit = random.nextInt(9) + 1;
  return int.parse('$leadingDigit$randomInt');
}
