/// The Web request timing interface which can be used to measure a web request manually
abstract class WebRequestTiming {
  /// Start the measurment of the web request. Call this before the request is started.
  void startWebRequestTiming();

  /// Stops the measurment of the web request. This needs to be called after the request is executed.
  /// The [responseCode] and [responseMessage] will be transfered and shown in the web UI.
  void stopWebRequestTiming(int responseCode, String? responseMessage);

  /// Returns the content for the header that is needed in order to track a request
  String getRequestTag();

  /// Returns the name for the header that is needed in order to track a request
  String getRequestTagHeader();
}
