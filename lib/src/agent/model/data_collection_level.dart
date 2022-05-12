/// The data collection level decides about the amount of data
/// which gets captured by the agent. For more information look
/// into the documenation.
enum DataCollectionLevel {
  /// The agent does not capture data.
  Off,

  /// The agent only captures anonymous performance data. But it does
  /// not capture data that would identify the user or custom value reporting.
  Performance,

  /// The agent captures performance and user data. This mode allows
  /// the agent to tag visits and it uses the same visitor id for every visit.
  UserBehavior,

  /// The agent captures performance and user data. This mode allows
  /// the agent to tag visits and it uses the same visitor id for every visit.
  @Deprecated("Replaced by UserBehavior")
  User
}
