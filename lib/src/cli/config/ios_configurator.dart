import 'dart:io';
import 'package:dynatrace_flutter_plugin/src/agent/util/logger.dart';
import 'package:dynatrace_flutter_plugin/src/cli/config/model/cli_arguments.dart';
import 'package:xml/xml.dart' as xml;

import 'package:dynatrace_flutter_plugin/src/cli/config/model/ios_config.dart';

class IosConfigurator {
  late File _pListFile;

  IosConfigurator(CommandLineArguments arguments, File? pListFile) {
    if (pListFile == null) {
      _pListFile = File(arguments.plistPath!);
    } else {
      _pListFile = pListFile;
    }
  }

  /// Loads the [pathToPList] and checks if it is really a plist file. It removes the Dynatrace configuration
  /// and inserts the new configuration stored in [iosConfig].
  Future<void> modifyPListFile(IosConfiguration iosConfig,
      {bool? isUninstall = false}) async {
    if (!_pListFile.path.endsWith(".plist") || !await _pListFile.exists()) {
      throw FileSystemException(
          "Can't find .plist file. plist path must also include the plist file! : ${_pListFile.path}");
    }

    String pListContent = await _pListFile.readAsString();

    xml.XmlDocument document = xml.XmlDocument.parse(pListContent);

    // Check for Plist
    if (document.rootElement.name.local != "plist") {
      throw Exception("malformed document. First element should be <plist>");
    }

    await _removedXmlTextElements(document.rootElement.children);

    if (document.rootElement.children.length != 1 &&
        (document.rootElement.children[0] as xml.XmlElement).name.local !=
            "dict") {
      throw Exception(
          "malformed document. First element should under <plist> should be <dict>");
    }

    await _removedXmlTextElements(document.rootElement.children[0].children);
    await _removePListConfig(document.rootElement.children[0].children);

    if (iosConfig.getConfig() == null || iosConfig.getConfig()!.isEmpty) {
      Logger().i(
          "Can't write configuration of iOS agent because it is missing!",
          logType: LogType.Warning);
    } else {
      if (isUninstall!) {
        Logger().d("Removing Dynatrace properties from plist file!",
            logType: LogType.Info);
      } else {
        String insertConfig = iosConfig.getConfig()! +
            "<key>DTXFlavor</key>\n<string>flutter</string>";
        await _addAgentConfigToPListFile(
            document.rootElement.children[0].children, insertConfig);
      }
    }

    await _pListFile.writeAsString(document.toXmlString(pretty: true));
  }

  /// Removes all unnecessary Text elements from [dictElements]. Seems like the XML
  /// library is inserting them but the XML string can be built without it.
  Future<void> _removedXmlTextElements(List<xml.XmlNode> dictElements) async {
    for (int i = 0; i < dictElements.length; i++) {
      if (dictElements[i].nodeType == xml.XmlNodeType.TEXT) {
        dictElements.removeAt(i);
      }
    }
  }

  /// Removes all Dynatrace related plist configuration from [dictElements]
  Future<void> _removePListConfig(List<xml.XmlNode> dictElements) async {
    for (int i = 0; i < dictElements.length; i++) {
      // Search for Keys
      if (i % 2 == 0) {
        if ((dictElements[i] as xml.XmlElement).name.local == "key") {
          if (dictElements[i].text.startsWith("DTX")) {
            dictElements.removeAt(i);
            dictElements.removeAt(i);
            i = i - 1;
          }
        } else {
          throw Exception("malformed document. Expected <key>");
        }
      }
    }

    Logger().d("Removed old configuration in plist file");
  }

  /// Adds agent related [config] to the [dictElements].
  Future<void> _addAgentConfigToPListFile(
      List<xml.XmlNode> dictElements, String config) async {
    // Need a temporary root object
    xml.XmlDocument configDoc = xml.XmlDocument.parse("<root>$config</root>");
    await _removedXmlTextElements(configDoc.rootElement.children);

    for (int i = 0; i < configDoc.rootElement.children.length; i++) {
      xml.XmlNode node = configDoc.rootElement.children[i].copy();
      dictElements.add(node);
    }

    Logger().d("Added configuration in plist file!");
  }
}
