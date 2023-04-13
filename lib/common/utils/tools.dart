import 'package:intl/intl.dart';

// 10位的时间戳转字符串
String formatTimestampToString(int timestamp) {
  if (timestamp.toString().length == 10) {
    timestamp = timestamp * 1000;
  }

  if (timestamp.toString().length != 13) {
    return "输入的时间戳不是10位或者13位的整数";
  }

  return DateFormat.yMd('zh_CN')
      .add_Hms()
      .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
}
