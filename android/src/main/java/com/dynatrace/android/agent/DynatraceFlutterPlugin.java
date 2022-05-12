package com.dynatrace.android.agent;

import android.location.Location;
import android.content.Context;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import java.net.MalformedURLException;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.LinkedList;

import com.dynatrace.android.agent.conf.ConfigurationFactory;
import com.dynatrace.android.agent.conf.DataCollectionLevel;
import com.dynatrace.android.agent.conf.DynatraceConfigurationBuilder;
import com.dynatrace.android.agent.conf.UserPrivacyOptions;
import com.dynatrace.android.agent.context.BindingContext;
import com.dynatrace.android.agent.context.RegistrarContext;
import com.dynatrace.android.agent.crash.PlatformType;

/**
 * Android implementation for Flutter plugin
 */
public class DynatraceFlutterPlugin implements FlutterPlugin {

  private static MethodChannel channel;

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    channel = new MethodChannel(registrar.messenger(), "dynatrace_flutter_plugin/dynatrace");
    channel.setMethodCallHandler(new DynatraceMethodCallHandler(new RegistrarContext(registrar)));
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), "dynatrace_flutter_plugin/dynatrace");
    channel.setMethodCallHandler(new DynatraceMethodCallHandler(new BindingContext(binding)));
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
    if(channel != null){
      channel.setMethodCallHandler(null);
    }
  }
}