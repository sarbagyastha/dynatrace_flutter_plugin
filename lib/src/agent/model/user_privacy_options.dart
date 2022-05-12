import './data_collection_level.dart';

/// Represents the privacy settings that the user can select
class UserPrivacyOptions {
  DataCollectionLevel dataCollectionLevel;
  bool crashReportingOptedIn;

  UserPrivacyOptions(
      DataCollectionLevel dataCollectionLevel, bool crashReportingOptedIn)
      : this.crashReportingOptedIn = crashReportingOptedIn,
        this.dataCollectionLevel = dataCollectionLevel;
}
