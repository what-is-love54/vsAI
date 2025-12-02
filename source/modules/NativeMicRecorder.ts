/** @format */

import type {TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export interface Spec extends TurboModule {
	/**
	 * Starts microphone recording.
	 * Rejects if permission is denied or recording is already in progress.
	 */
	start(): Promise<void>;

	/**
	 * Stops recording and immediately plays back the last recorded audio.
	 */
	stop(): Promise<void>;
}

/**
 * JS access point for the TurboModule.
 */
const NativeMicRecorder =
	TurboModuleRegistry.getEnforcing<Spec>('NativeMicRecorder');

export default NativeMicRecorder;
