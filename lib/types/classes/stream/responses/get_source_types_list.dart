import 'package:obs_station/types/classes/api/source_type.dart';

import 'base.dart';

/// Get a list of all available sources types
class GetSourceTypesList extends BaseResponse {
  GetSourceTypesList(json) : super(json);

  List<SourceType> get types => (this.json['types'] as List<dynamic>)
      .map((type) => SourceType.fromJSON(type))
      .toList();
}
