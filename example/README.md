[![N|Solid](https://assets.dynatrace.com/content/dam/dynatrace/misc/dynatrace_web.png)](https://dynatrace.com)

# Example for the Dynatrace Flutter Plugin

This example should demonstrate how to use the plugin in combination with a Flutter application. It includes several buttons which trigger certain features of the plugin. Take a look at the *lib/main.dart* to learn more about the different API calls or simply run the application and click on the buttons and see how the data looks like in the Dynatrace WebUI.

# Starting Example

The following steps are only valid for this example application. If you want to setup your own application please follow the main documentation which contains several extra steps. Those extra steps are already implemented here.

1. Create a mobile app in Dynatrace and open **Mobile app settings**. Go to Flutter configuration, download the `dynatrace.config.yaml` file and replace it with the file which is already in the root folder of this example.

2. Run `flutter pub run dynatrace_flutter_plugin` in the root of the example project. This configures both Android and iOS projects with settings from `dynatrace.config.yaml`.

3. Call `flutter run` and the application starts including Dynatrace OneAgent.




