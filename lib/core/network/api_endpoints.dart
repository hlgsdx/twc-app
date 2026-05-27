class ApiEndpoints {
  ApiEndpoints._();

  static final Uri baseUri = Uri.parse('https://tsukubawebcorpus.jp');
  static final Uri homeUri = baseUri.resolve('/');
  static final Uri searchUri = baseUri.resolve('/search/');

  static const String headwordListAll = '/headwordlist_all/';
  static const String patternFreqOrder = '/patternfreqorder/';
  static const String collocation = '/collocation/';
  static const String example = '/example/';
  static const String context = '/context/';

  static String basicInfo(String headwordId) => '/basicinfob/$headwordId/';
  static String basicInfoSj(String headwordId) => '/basicinfosj/$headwordId/';
  static String basicInfoKy(String headwordId) => '/basicinfoky/$headwordId/';
  static String basicInfoJs(String headwordId) => '/basicinfojs/$headwordId/';
  static String patternGroup(String group, String headwordId) =>
      '/pattern/$group/$headwordId/';
  static String headword(String headwordId) => '/headword/$headwordId/';
  static String contextByLocation(String fileId, int sentenceNo) =>
      '/context/$fileId.$sentenceNo/';
}
