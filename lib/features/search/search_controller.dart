import '../../core/network/api_result.dart';
import '../../data/models/headword_card.dart';
import '../../data/models/jqgrid_response.dart';
import '../../data/repositories/twc_repository.dart';

class SearchController {
  SearchController(this._repository);

  final TwcRepository _repository;

  Future<JqGridResponse<HeadwordCard>> search(String keyword) async {
    final result = await _repository.searchHeadwords(
      keyword: keyword,
      page: 1,
      rows: 100,
    );
    return result.fold((data) => data, (error) => throw error);
  }
}
