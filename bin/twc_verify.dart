import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:app/core/network/api_result.dart';
import 'package:app/core/network/cookie/cookie_bootstrapper.dart';
import 'package:app/core/network/cookie/cookie_store.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/data/repositories/twc_repository.dart';
import 'package:app/data/models/headword_card.dart';
import 'package:app/data/models/headword_detail.dart';
import 'package:app/data/sources/twc_collocation_source.dart';
import 'package:app/data/sources/twc_context_source.dart';
import 'package:app/data/sources/twc_detail_source.dart';
import 'package:app/data/sources/twc_example_source.dart';
import 'package:app/data/sources/twc_search_source.dart';
import 'package:app/data/sources/twc_session_source.dart';
import 'package:app/core/network/transport/request_executor.dart';
import 'package:app/core/network/interceptors/auth_header_interceptor.dart';
import 'package:app/core/network/csrf/csrf_interceptor.dart';
import 'package:app/core/network/csrf/csrf_manager.dart';

Future<void> main(List<String> args) async {
  final options = _VerifyOptions.parse(args);

  stdout.writeln('TWC verification CLI');
  stdout.writeln('This tool sends live requests to tsukubawebcorpus.jp.');
  stdout.writeln('');

  final cookieStore = CookieStore.inMemory();
  final csrfManager = CsrfManager(cookieStore);
  await csrfManager.seedFromCookies(
    ApiEndpoints.baseUri,
    _buildSessionCookies(),
  );
  final dio = _buildClient(
    cookieStore,
    csrfManager: csrfManager,
    verbose: options.verbose,
  );
  final repository = RemoteTwcRepository(
    sessionSource: TwcSessionSource(
      cookieBootstrapper: CookieBootstrapper(
        dio: dio,
        cookieStore: cookieStore,
      ),
    ),
    searchSource: TwcSearchSource(
      requestExecutor: RequestExecutor(dio),
    ),
    detailSource: TwcDetailSource(
      requestExecutor: RequestExecutor(dio),
    ),
    collocationSource: TwcCollocationSource(
      requestExecutor: RequestExecutor(dio),
    ),
    exampleSource: TwcExampleSource(
      requestExecutor: RequestExecutor(dio),
    ),
    contextSource: TwcContextSource(
      requestExecutor: RequestExecutor(dio),
    ),
  );

  await _step('1. Bootstrap session', () async {
    stdout.writeln('Opening /search/ to seed cookies and CSRF state...');
    await repository.bootstrapSession();
    stdout.writeln('Session ready.');
  });

  final keyword = options.keyword ?? _prompt('Search keyword');
  final page = options.page;
  final rows = options.rows;

  await _step('2. Search headwords', () async {
    stdout.writeln('Fetching search results for "$keyword"...');
    final result = await repository.searchHeadwords(
      keyword: keyword,
      page: page,
      rows: rows,
    );
    await result.fold(
      (pageResult) async {
        if (pageResult.rows.isEmpty) {
          stdout.writeln('No results found.');
          return;
        }

        stdout.writeln(
          'Page ${pageResult.page} of ${pageResult.total} (records: ${pageResult.records ?? 'unknown'})',
        );
        _printHeadwordRows(pageResult.rows);

        final selected = await _chooseHeadword(
          pageResult.rows,
          fallbackHeadwordId: options.headwordId,
        );
        if (selected != null) {
          await _runDetailFlow(repository, dio, selected);
        }
      },
      (error) async {
        stdout.writeln('Search failed: $error');
      },
    );
  });

  if (options.contextFileId != null && options.contextSentenceNo != null) {
    await _step('4. Context lookup', () async {
      await _printContext(
        repository,
        fileId: options.contextFileId!,
        sentenceNo: options.contextSentenceNo!,
        targetSentenceId: options.targetSentenceId,
      );
    });
  } else if (_askYesNo('Open a context example now?')) {
    final fileId = _prompt('Context fileId (e.g. 021-040.001.13372)');
    final sentenceNo = int.parse(_prompt('Sentence number'));
    await _step('4. Context lookup', () async {
      await _printContext(
        repository,
        fileId: fileId,
        sentenceNo: sentenceNo,
        targetSentenceId: options.targetSentenceId,
      );
    });
  }

  stdout.writeln('');
  stdout.writeln('Verification run complete.');
}

Dio _buildClient(
  CookieStore cookieStore, {
  required CsrfManager csrfManager,
  required bool verbose,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUri.toString(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const <String, Object?>{},
    ),
  );
  dio.interceptors.addAll([
    CookieManager(cookieStore.jar),
    const AuthHeaderInterceptor(),
    CsrfInterceptor(csrfManager),
    if (verbose)
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        logPrint: stdout.writeln,
      ),
  ]);
  return dio;
}

List<Cookie> _buildSessionCookies() {
  const seed = 'twc-cli-session';
  final token = 'twc-test-csrf-${base64Url.encode(utf8.encode(seed))}';
  return [
    Cookie('csrftoken', token),
    Cookie('agreed', 'true'),
  ];
}

Future<void> _runDetailFlow(
  TwcRepository repository,
  Dio dio,
  String headwordId,
) async {
  await _step('3. Detail drill-down', () async {
    stdout.writeln('Opening detail for $headwordId...');
    await _loadDetailTemplates(dio, headwordId);
    final detailResult = await repository.fetchHeadwordDetail(headwordId);
    await detailResult.fold(
      (bundle) async {
        final info = bundle.basicInfo;
        stdout.writeln(
          'Headword: ${info?.headword ?? '(missing)'} | freq: ${info?.freq ?? 0}',
        );
        stdout.writeln(
          'Views: shojikei=${bundle.basicInfoViews.shojikei != null}, katuyokei=${bundle.basicInfoViews.katuyokei != null}, jodoshisetuzoku=${bundle.basicInfoViews.jodoshisetuzoku != null}',
        );
        _printShojikeiView(bundle.basicInfoViews.shojikei);
        _printKatuyokeiView(bundle.basicInfoViews.katuyokei);
        _printJodoshisetuzokuView(bundle.basicInfoViews.jodoshisetuzoku);
        stdout.writeln('Pattern frequency rows: ${bundle.patternFrequency.length}');
        stdout.writeln('Pattern groups: ${bundle.patternGroups.keys.join(', ')}');
        if (bundle.issues.isNotEmpty) {
          stdout.writeln('Non-fatal issues:');
          for (final issue in bundle.issues) {
            stdout.writeln('  - $issue');
          }
        }
      },
      (error) async {
        stdout.writeln('Detail fetch failed: $error');
      },
    );
  });
}

Future<void> _loadDetailTemplates(Dio dio, String headwordId) async {
  const templatePaths = <String>[
    '/static/templates/shojikei.tpl',
    '/static/templates/katuyokei.tpl',
    '/static/templates/jodoshisetuzoku.tpl',
  ];

  for (final path in templatePaths) {
    await dio.get<String>(
      path,
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'Accept': '*/*',
          'Referer': 'https://tsukubawebcorpus.jp/headword/$headwordId/',
          'X-Requested-With': 'XMLHttpRequest',
        },
        extra: {
          'skipCsrfHeader': true,
        },
      ),
    );
  }
}

Future<void> _printContext(
  TwcRepository repository, {
  required String fileId,
  required int sentenceNo,
  String? targetSentenceId,
}) async {
  stdout.writeln('Opening context for $fileId.$sentenceNo ...');
  final contextResult = await repository.fetchContext(
    fileId: fileId,
    sentenceNo: sentenceNo,
    targetSentenceId: targetSentenceId,
  );
  await contextResult.fold(
    (snippets) async {
      stdout.writeln('Context snippets: ${snippets.length}');
      for (final snippet in snippets) {
        final marker = snippet.isTarget ? '*' : ' ';
        stdout.writeln('$marker ${snippet.sentenceId}: ${snippet.text}');
      }
    },
    (error) async {
      stdout.writeln('Context fetch failed: $error');
    },
  );
}

void _printHeadwordRows(List<HeadwordCard> rows) {
  final limit = rows.length < 10 ? rows.length : 10;
  for (var i = 0; i < limit; i++) {
    final row = rows[i];
    stdout.writeln(
      '[${i + 1}] ${row.headword} (${row.yomiDisplay}) ${row.headwordId} freq=${_formatInt(row.freq)}',
    );
  }
  if (rows.length > limit) {
    stdout.writeln('... ${rows.length - limit} more rows');
  }
}

void _printShojikeiView(HeadwordShojikeiView? view) {
  if (view == null) {
    stdout.writeln('Shojikei: (missing)');
    return;
  }
  stdout.writeln('Shojikei rows: ${view.shojikei.length}');
  for (final item in view.shojikei.take(5)) {
    stdout.writeln('  - ${item.name} | freq=${item.freq} | pct=${item.percentage}');
  }
}

void _printKatuyokeiView(HeadwordKatuyokeiView? view) {
  if (view == null) {
    stdout.writeln('Katuyokei: (missing)');
    return;
  }
  stdout.writeln('Katuyokei rows: ${view.katuyokei.length}');
  for (final item in view.katuyokei.take(5)) {
    stdout.writeln('  - ${item.name} | freq=${item.freq} | pct=${item.percentage}');
  }
}

void _printJodoshisetuzokuView(HeadwordJodoshisetuzokuView? view) {
  if (view == null) {
    stdout.writeln('Jodoshisetuzoku: (missing)');
    return;
  }
  stdout.writeln('Jodoshisetuzoku rows: ${view.setuzoku.length}');
  for (final item in view.setuzoku.take(5)) {
    stdout.writeln(
      '  - ${item.name} | freq=${item.jodoshiFreq} | pct=${item.jodoshiPercentage} | doshi=${item.doshiJodoshi.length}',
    );
    for (final doshi in item.doshiJodoshi.take(3)) {
      stdout.writeln(
        '      * ${doshi.name} | freq=${doshi.freq} | pct=${doshi.doshiJodoshiPercentage}',
      );
    }
  }
}

Future<String?> _chooseHeadword(
  List<HeadwordCard> rows, {
  String? fallbackHeadwordId,
}) async {
  if (fallbackHeadwordId != null && fallbackHeadwordId.isNotEmpty) {
    return fallbackHeadwordId;
  }

  final choice = _prompt(
    'Choose a row number, enter a headword id, or press Enter to skip',
    allowEmpty: true,
  );
  if (choice.isEmpty) {
    return null;
  }

  final index = int.tryParse(choice);
  if (index != null && index >= 1 && index <= rows.length) {
    return rows[index - 1].headwordId;
  }

  return choice;
}

Future<void> _step(String title, Future<void> Function() action) async {
  stdout.writeln('');
  stdout.writeln('== $title ==');
  await action();
}

String _prompt(String label, {bool allowEmpty = false}) {
  while (true) {
    stdout.write('$label: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    if (input.isNotEmpty || allowEmpty) {
      return input;
    }
    stdout.writeln('Please enter a value.');
  }
}

bool _askYesNo(String question) {
  stdout.write('$question [y/N]: ');
  final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  return input == 'y' || input == 'yes';
}

String _formatInt(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );
}

class _VerifyOptions {
  _VerifyOptions({
    required this.keyword,
    required this.page,
    required this.rows,
    required this.headwordId,
    required this.contextFileId,
    required this.contextSentenceNo,
    required this.targetSentenceId,
    required this.verbose,
  });

  final String? keyword;
  final int page;
  final int rows;
  final String? headwordId;
  final String? contextFileId;
  final int? contextSentenceNo;
  final String? targetSentenceId;
  final bool verbose;

  factory _VerifyOptions.parse(List<String> args) {
    String? keyword;
    String? headwordId;
    String? contextFileId;
    String? targetSentenceId;
    int page = 1;
    int rows = 100;
    int? contextSentenceNo;
    bool verbose = false;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      String nextValue() {
        if (i + 1 >= args.length) {
          throw ArgumentError('Missing value for $arg');
        }
        return args[++i];
      }

      switch (arg) {
        case '--keyword':
        case '-k':
          keyword = nextValue();
          break;
        case '--headword-id':
          headwordId = nextValue();
          break;
        case '--context-file-id':
          contextFileId = nextValue();
          break;
        case '--context-sentence-no':
          contextSentenceNo = int.parse(nextValue());
          break;
        case '--target-sentence-id':
          targetSentenceId = nextValue();
          break;
        case '--page':
          page = int.parse(nextValue());
          break;
        case '--rows':
          rows = int.parse(nextValue());
          break;
        case '--verbose':
        case '-v':
          verbose = true;
          break;
        case '--help':
        case '-h':
          _printHelpAndExit();
        default:
          if (arg.startsWith('--keyword=')) {
            keyword = arg.substring('--keyword='.length);
          } else if (arg.startsWith('--headword-id=')) {
            headwordId = arg.substring('--headword-id='.length);
          } else if (arg.startsWith('--context-file-id=')) {
            contextFileId = arg.substring('--context-file-id='.length);
          } else if (arg.startsWith('--context-sentence-no=')) {
            contextSentenceNo = int.parse(arg.substring('--context-sentence-no='.length));
          } else if (arg.startsWith('--target-sentence-id=')) {
            targetSentenceId = arg.substring('--target-sentence-id='.length);
          } else if (arg.startsWith('--page=')) {
            page = int.parse(arg.substring('--page='.length));
          } else if (arg.startsWith('--rows=')) {
            rows = int.parse(arg.substring('--rows='.length));
          } else {
            throw ArgumentError('Unknown option: $arg');
          }
      }
    }

    return _VerifyOptions(
      keyword: keyword,
      page: page,
      rows: rows,
      headwordId: headwordId,
      contextFileId: contextFileId,
      contextSentenceNo: contextSentenceNo,
      targetSentenceId: targetSentenceId,
      verbose: verbose,
    );
  }

  static Never _printHelpAndExit() {
    stdout.writeln('Usage: dart run bin/twc_verify.dart [options]');
    stdout.writeln('');
    stdout.writeln('Options:');
    stdout.writeln('  --keyword, -k <word>            Search keyword');
    stdout.writeln('  --headword-id <id>              Skip chooser and open this headword');
    stdout.writeln('  --context-file-id <fileId>      Open a context example');
    stdout.writeln('  --context-sentence-no <n>       Context sentence number');
    stdout.writeln('  --target-sentence-id <sid>      Highlight a specific sentence id');
    stdout.writeln('  --page <n>                      Search page number (default 1)');
    stdout.writeln('  --rows <n>                      Search rows per page (default 100)');
    stdout.writeln('  --verbose                       Enable network logging');
    stdout.writeln('  --help                          Show this help');
    exit(0);
  }
}
