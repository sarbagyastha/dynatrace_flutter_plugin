import 'dart:convert';
import 'dart:io';

import 'package:dynatrace_flutter_plugin/src/agent/agent_impl.dart';
import 'package:dynatrace_flutter_plugin/src/agent/interface/web_request_timing.dart';

class DynatraceHttpClientRequest implements HttpClientRequest {
  HttpClientRequest _httpClientRequest;
  DynatraceImpl? _dynatrace;

  DynatraceHttpClientRequest(
      this._httpClientRequest, this._dynatrace, String? _headerValue) {
    _addDynatraceHeader(_headerValue);
  }

  void _addDynatraceHeader(String? headerValue) {
    if (headerValue != null && this.headers.value("x-dynatrace") == null) {
      this.headers.add("x-dynatrace", headerValue);
    }
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    _httpClientRequest.addError(exception!, stackTrace);
  }

  @override
  bool get bufferOutput => _httpClientRequest.bufferOutput;

  @override
  set bufferOutput(bool value) => _httpClientRequest.bufferOutput = value;

  @override
  int get contentLength => _httpClientRequest.contentLength;

  @override
  set contentLength(int value) => _httpClientRequest.contentLength = value;

  @override
  Encoding get encoding => _httpClientRequest.encoding;

  @override
  set encoding(Encoding value) => _httpClientRequest.encoding = value;

  @override
  bool get followRedirects => _httpClientRequest.followRedirects;

  @override
  set followRedirects(bool value) => _httpClientRequest.followRedirects = value;

  @override
  int get maxRedirects => _httpClientRequest.maxRedirects;

  @override
  set maxRedirects(int value) => _httpClientRequest.maxRedirects = value;

  @override
  bool get persistentConnection => _httpClientRequest.persistentConnection;

  @override
  set persistentConnection(bool value) =>
      _httpClientRequest.persistentConnection = value;

  @override
  void add(List<int> data) => _httpClientRequest.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _httpClientRequest.addError(error, stackTrace);

  @override
  Future addStream(Stream<List<int>> stream) =>
      _httpClientRequest.addStream(stream);

  @override
  Future<HttpClientResponse> close() async {
    if (this.headers.value("x-dynatrace") != null) {
      WebRequestTiming timing = _dynatrace!.createWebRequestTiming(
          this.headers.value("x-dynatrace")!,
          _httpClientRequest.uri.toString());

      timing.startWebRequestTiming();
      try {
        HttpClientResponse response = await _httpClientRequest.close();
        timing.stopWebRequestTiming(response.statusCode, response.reasonPhrase);

        return response;
      } catch (error) {
        timing.stopWebRequestTiming(-1, error.toString());

        throw error;
      }
    } else {
      return await _httpClientRequest.close();
    }
  }

  @override
  HttpConnectionInfo? get connectionInfo => _httpClientRequest.connectionInfo;

  @override
  List<Cookie> get cookies => _httpClientRequest.cookies;

  @override
  Future<HttpClientResponse> get done => _httpClientRequest.done;

  @override
  Future flush() => _httpClientRequest.flush();

  @override
  HttpHeaders get headers => _httpClientRequest.headers;

  @override
  String get method => _httpClientRequest.method;

  @override
  Uri get uri => _httpClientRequest.uri;

  @override
  void write(Object? obj) => _httpClientRequest.write(obj);

  @override
  void writeAll(Iterable objects, [String separator = ""]) =>
      _httpClientRequest.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) =>
      _httpClientRequest.writeCharCode(charCode);

  @override
  void writeln([Object? obj = ""]) => _httpClientRequest.writeln(obj);
}
