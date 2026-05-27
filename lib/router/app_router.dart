import 'package:go_router/go_router.dart';

import '../core/app/twc_app_services.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../features/detail/collocation_page.dart';
import '../features/detail/example_page.dart';
import '../features/detail/headword_detail_page.dart';
import '../features/favorite/favorite_page.dart';
import '../features/home/home_page.dart';
import '../features/search_result/search_result_page.dart';
import '../features/settings/settings_page.dart';

class AppRoutePaths {
  static const home = '/';
  static const search = '/search';
  static const headwordListAll = '/headwordlist_all';
  static const favorite = '/favorite';
  static const settings = '/settings';

  static String detail(String headwordId) => '/detail/$headwordId';
}

GoRouter buildAppRouter(
  TwcAppServices services, {
  String initialLocation = AppRoutePaths.home,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppBottomNav(
            currentIndex: _bottomNavIndex(state.uri.path),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutePaths.home,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: HomePage(services: services),
            ),
          ),
          GoRoute(
            path: AppRoutePaths.favorite,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const FavoritePage(),
            ),
          ),
          GoRoute(
            path: AppRoutePaths.settings,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutePaths.search,
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchResultPage(
            services: services,
            query: query,
            showAll: false,
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.headwordListAll,
        builder: (context, state) {
          return SearchResultPage(services: services, query: '', showAll: true);
        },
      ),
      GoRoute(
        path: '/detail/:headwordId',
        builder: (context, state) {
          return HeadwordDetailPage(
            services: services,
            headwordId: state.pathParameters['headwordId'] ?? '',
          );
        },
        routes: [
          GoRoute(
            path: 'collocations/:patternId',
            builder: (context, state) {
              final headwordId = state.pathParameters['headwordId'] ?? '';
              final patternId = state.pathParameters['patternId'] ?? '';
              return CollocationPage(
                services: services,
                headwordId: headwordId,
                patternId: patternId,
                title: state.uri.queryParameters['title'],
              );
            },
            routes: [
              GoRoute(
                path: 'examples/:collocationId',
                builder: (context, state) {
                  final headwordId = state.pathParameters['headwordId'] ?? '';
                  final patternId = state.pathParameters['patternId'] ?? '';
                  final collocationId =
                      state.pathParameters['collocationId'] ?? '';
                  return ExamplePage(
                    services: services,
                    headwordId: headwordId,
                    patternId: patternId,
                    collocationId: collocationId,
                    title: state.uri.queryParameters['title'],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

int _bottomNavIndex(String path) {
  if (path == AppRoutePaths.favorite) {
    return 1;
  }
  if (path == AppRoutePaths.settings) {
    return 2;
  }
  return 0;
}
