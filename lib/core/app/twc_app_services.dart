import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/twc_repository.dart';
import '../../data/sources/twc_collocation_source.dart';
import '../../data/sources/twc_context_source.dart';
import '../../data/sources/twc_detail_source.dart';
import '../../data/sources/twc_example_source.dart';
import '../../data/sources/twc_search_source.dart';
import '../../data/sources/twc_session_source.dart';
import '../../features/home/search_history_controller.dart';
import '../network/cookie/cookie_bootstrapper.dart';
import '../network/cookie/cookie_store.dart';
import '../network/dio_client.dart';
import '../network/transport/request_executor.dart';
import '../../features/home/search_history_store.dart';

class TwcAppServices {
  TwcAppServices({
    required this.repository,
    required this.searchHistoryStore,
    required this.searchHistoryController,
  });

  final TwcRepository repository;
  final SearchHistoryStore searchHistoryStore;
  final SearchHistoryController searchHistoryController;

  static Future<TwcAppServices> create({bool enableLogging = false}) async {
    final cookieDirectory = await getTemporaryDirectory();
    final cookieStore = await CookieStore.persistent(
      directory: cookieDirectory,
    );
    final dioClient = await DioClient.create(
      cookieStore: cookieStore,
      enableLogging: enableLogging,
    );
    final requestExecutor = RequestExecutor(dioClient.dio);
    final repository = RemoteTwcRepository(
      sessionSource: TwcSessionSource(
        cookieBootstrapper: CookieBootstrapper(
          dio: dioClient.dio,
          cookieStore: dioClient.cookieStore,
        ),
      ),
      searchSource: TwcSearchSource(requestExecutor: requestExecutor),
      detailSource: TwcDetailSource(requestExecutor: requestExecutor),
      collocationSource: TwcCollocationSource(requestExecutor: requestExecutor),
      exampleSource: TwcExampleSource(requestExecutor: requestExecutor),
      contextSource: TwcContextSource(requestExecutor: requestExecutor),
    );

    final prefs = await SharedPreferences.getInstance();
    final searchHistoryStore = SharedPreferencesSearchHistoryStore(prefs);
    final searchHistoryController = SearchHistoryController(searchHistoryStore);
    return TwcAppServices(
      repository: repository,
      searchHistoryStore: searchHistoryStore,
      searchHistoryController: searchHistoryController,
    );
  }
}
