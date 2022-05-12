import 'dart:io';
import 'package:dynatrace_flutter_plugin/src/agent/agent_impl.dart';
import 'http_request.dart';

class DynatraceHttpClient implements HttpClient {
  HttpClient _httpClient;
  DynatraceImpl? _dynatrace;

  DynatraceHttpClient(this._httpClient, this._dynatrace);

  Future<HttpClientRequest> _wrapRequest(
      Future<HttpClientRequest> httpClientRequest, String url) async {
    // We need to fetch the header at the beginning as it can not be set after a body write
    String? header = await _dynatrace!.getHTTPTagForWebRequest(url);

    return Future.value(DynatraceHttpClientRequest(
        await httpClientRequest, _dynatrace, header));
  }

  @override
  void close({bool force = false}) => _httpClient.close(force: force);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _wrapRequest(_httpClient.delete(host, port, path),
          Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) =>
      _wrapRequest(_httpClient.deleteUrl(url), url.toString());

  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      _wrapRequest(_httpClient.getUrl(url), url.toString());

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _wrapRequest(_httpClient.head(host, port, path),
          Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> headUrl(Uri url) =>
      _wrapRequest(_httpClient.headUrl(url), url.toString());

  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      _wrapRequest(_httpClient.open(method, host, port, path),
          Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _wrapRequest(_httpClient.openUrl(method, url), url.toString());

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _wrapRequest(_httpClient.patch(host, port, path),
          Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> patchUrl(Uri url) =>
      _wrapRequest(_httpClient.patchUrl(url), url.toString());

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _wrapRequest(_httpClient.post(host, port, path),
          Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> postUrl(Uri url) =>
      _wrapRequest(_httpClient.postUrl(url), url.toString());

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _wrapRequest(_httpClient.put(host, port, path),
          Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> putUrl(Uri url) =>
      _wrapRequest(_httpClient.putUrl(url), url.toString());

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _wrapRequest(_httpClient.get(host, port, path),
          Uri(host: host, port: port, path: path).toString());

  // NOT USED FUNCTIONS

  @override
  bool get autoUncompress => _httpClient.autoUncompress;

  @override
  set autoUncompress(bool value) => _httpClient.autoUncompress = value;

  @override
  Duration? get connectionTimeout => _httpClient.connectionTimeout;

  @override
  set connectionTimeout(Duration? value) =>
      _httpClient.connectionTimeout = value;

  @override
  Duration get idleTimeout => _httpClient.idleTimeout;

  @override
  set idleTimeout(Duration value) => _httpClient.idleTimeout = value;

  @override
  int? get maxConnectionsPerHost => _httpClient.maxConnectionsPerHost;

  @override
  set maxConnectionsPerHost(int? value) =>
      _httpClient.maxConnectionsPerHost = value;

  @override
  String? get userAgent => _httpClient.userAgent;

  @override
  set userAgent(String? value) => _httpClient.userAgent = value;

  @override
  void addCredentials(
          Uri url, String realm, HttpClientCredentials credentials) =>
      _httpClient.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(String host, int port, String realm,
          HttpClientCredentials credentials) =>
      _httpClient.addProxyCredentials(host, port, realm, credentials);

  @override
  set authenticate(
          Future<bool> Function(Uri url, String scheme, String? realm)? f) =>
      _httpClient.authenticate = f;

  @override
  set authenticateProxy(
          Future<bool> Function(
                  String host, int port, String scheme, String? realm)?
              f) =>
      _httpClient.authenticateProxy = f;

  @override
  set badCertificateCallback(
          bool Function(X509Certificate cert, String host, int port)?
              callback) =>
      _httpClient.badCertificateCallback = callback;

  @override
  set findProxy(String Function(Uri url)? f) => _httpClient.findProxy = f;

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
        f,
  ) {
    _httpClient.connectionFactory = f;
  }

  @override
  set keyLog(Function(String line)? callback) {
    _httpClient.keyLog = callback;
  }
}
