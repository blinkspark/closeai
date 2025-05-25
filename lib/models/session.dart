import 'package:isar/isar.dart';
import 'message.dart';

part 'session.g.dart';

@Collection()
class Session {
  Id id = Isar.autoIncrement;
  late String title;
  String? description;
  DateTime createTime = DateTime.now();
  DateTime updateTime = DateTime.now();
  
  // 通过反向链接获取消息
  @Backlink(to: 'session')
  final messages = IsarLinks<Message>();
}
