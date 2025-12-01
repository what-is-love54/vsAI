/** @format */

import type {TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export interface Spec extends TurboModule {
	// Recording methods
	startRecording(): Promise<string>;
	stopRecording(): Promise<string>;
	pauseRecording(): Promise<void>;
	resumeRecording(): Promise<void>;
	cancelRecording(): Promise<void>;

	// Playback methods
	playRecording(filePath: string): Promise<void>;
	stopPlayback(): Promise<void>;
	pausePlayback(): Promise<void>;
	resumePlayback(): Promise<void>;

	// Status methods
	isRecording(): Promise<boolean>;
	isPlaying(): Promise<boolean>;
	getRecordingDuration(): Promise<number>;
	getPlaybackDuration(): Promise<number>;
	getPlaybackCurrentTime(): Promise<number>;

	// Permission methods
	requestPermissions(): Promise<boolean>;
	hasPermissions(): Promise<boolean>;

	// File management
	getRecordingsDirectory(): Promise<string>;
	deleteRecording(filePath: string): Promise<boolean>;

	// Event emitter support
	addListener(eventName: string): void;
	removeListeners(count: number): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('AudioRecorder');
