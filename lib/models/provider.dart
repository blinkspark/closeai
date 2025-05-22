import 'package:isar/isar.dart';

import 'model.dart';

part 'provider.g.dart';

@Collection()
class Provider {
  // Provider();

  Id id = Isar.autoIncrement;
  late String name;
  String? baseUrl;
  String? apiKey;
  @Backlink(to: 'provider')
  final models = IsarLinks<Model>();

  // factory Provider.newProvider(String name) {
  //   return Provider()
  //     ..name = name
  //     ..baseUrl = ''
  //     ..apiKey = '';
  // }
}
