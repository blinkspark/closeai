import 'package:isar/isar.dart';

import 'model.dart';

part 'provider.g.dart';

@Collection()
class Provider {
  final Id id = Isar.autoIncrement;
  late String name;
  String? baseUrl;
  String? apiKey;
  @Backlink(to: 'provider')
  final models = IsarLinks<Model>();
}
