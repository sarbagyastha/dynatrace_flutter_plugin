package com.dynatrace.android.agent.context;

import android.content.Context;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * Class which wraps the Binding class to get the context from it.
 * @author matthias.hochrieser
 */
public class BindingContext implements FlutterContext {
	
	private final FlutterPlugin.FlutterPluginBinding binding;

	public BindingContext(FlutterPlugin.FlutterPluginBinding binding){
		this.binding = binding;
	}

	@Override
	public Context getContext() {
		return binding.getApplicationContext();
	}
}
