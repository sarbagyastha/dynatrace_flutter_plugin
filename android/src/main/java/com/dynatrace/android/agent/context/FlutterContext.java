package com.dynatrace.android.agent.context;

import android.content.Context;

/**
 * Interface which provides the context to our plugin
 */
public interface FlutterContext {

	/**
	 * Returns the context of the flutter application
	 * @return Context
	 */
	Context getContext();

}