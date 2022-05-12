package com.dynatrace.android.agent.context;

import android.content.Context;
import io.flutter.plugin.common.PluginRegistry;

/**
 * Class which wraps the Registrar class to get the context from it.
 * @author matthias.hochrieser
 */
public class RegistrarContext implements FlutterContext {

	private final PluginRegistry.Registrar registrar;

	public RegistrarContext(PluginRegistry.Registrar registrar){
		this.registrar = registrar;
	}

	@Override
	public Context getContext() {
		return this.registrar.activeContext();
	}
}
