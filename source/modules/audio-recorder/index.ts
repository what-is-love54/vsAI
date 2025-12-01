/** @format */

import {NativeEventEmitter, NativeModules} from 'react-native';
import NativeAudioRecorder from './NativeAudioRecorder';

export type AudioRecorderEvent =
	| 'onRecordingStarted'
	| 'onRecordingStopped'
	| 'onRecordingPaused'
	| 'onRecordingResumed'
	| 'onRecordingProgress'
	| 'onRecordingError'
	| 'onPlaybackStarted'
	| 'onPlaybackStopped'
	| 'onPlaybackPaused'
	| 'onPlaybackResumed'
	| 'onPlaybackProgress'
	| 'onPlaybackCompleted'
	| 'onPlaybackError';

export interface RecordingProgressEvent {
	duration: number;
	filePath: string;
}

export interface PlaybackProgressEvent {
	currentTime: number;
	duration: number;
	filePath: string;
}

export interface ErrorEvent {
	message: string;
	code: string;
}

class AudioRecorderModule {
	private eventEmitter: NativeEventEmitter;
	private listeners: Map<string, Set<(...args: unknown[]) => void>> = new Map();

	constructor() {
		this.eventEmitter = new NativeEventEmitter(
			NativeModules.AudioRecorder ?? NativeAudioRecorder,
		);
	}

	// Recording methods
	async startRecording(): Promise<string> {
		return NativeAudioRecorder.startRecording();
	}

	async stopRecording(): Promise<string> {
		return NativeAudioRecorder.stopRecording();
	}

	async pauseRecording(): Promise<void> {
		return NativeAudioRecorder.pauseRecording();
	}

	async resumeRecording(): Promise<void> {
		return NativeAudioRecorder.resumeRecording();
	}

	async cancelRecording(): Promise<void> {
		return NativeAudioRecorder.cancelRecording();
	}

	// Playback methods
	async playRecording(filePath: string): Promise<void> {
		return NativeAudioRecorder.playRecording(filePath);
	}

	async stopPlayback(): Promise<void> {
		return NativeAudioRecorder.stopPlayback();
	}

	async pausePlayback(): Promise<void> {
		return NativeAudioRecorder.pausePlayback();
	}

	async resumePlayback(): Promise<void> {
		return NativeAudioRecorder.resumePlayback();
	}

	// Status methods
	async isRecording(): Promise<boolean> {
		return NativeAudioRecorder.isRecording();
	}

	async isPlaying(): Promise<boolean> {
		return NativeAudioRecorder.isPlaying();
	}

	async getRecordingDuration(): Promise<number> {
		return NativeAudioRecorder.getRecordingDuration();
	}

	async getPlaybackDuration(): Promise<number> {
		return NativeAudioRecorder.getPlaybackDuration();
	}

	async getPlaybackCurrentTime(): Promise<number> {
		return NativeAudioRecorder.getPlaybackCurrentTime();
	}

	// Permission methods
	async requestPermissions(): Promise<boolean> {
		return NativeAudioRecorder.requestPermissions();
	}

	async hasPermissions(): Promise<boolean> {
		return NativeAudioRecorder.hasPermissions();
	}

	// File management
	async getRecordingsDirectory(): Promise<string> {
		return NativeAudioRecorder.getRecordingsDirectory();
	}

	async deleteRecording(filePath: string): Promise<boolean> {
		return NativeAudioRecorder.deleteRecording(filePath);
	}

	// Event handling
	addEventListener(
		event: AudioRecorderEvent,
		callback: (...args: unknown[]) => void,
	): () => void {
		if (!this.listeners.has(event)) {
			this.listeners.set(event, new Set());
		}
		this.listeners.get(event)!.add(callback);

		const subscription = this.eventEmitter.addListener(event, callback);

		return () => {
			subscription.remove();
			this.listeners.get(event)?.delete(callback);
		};
	}

	removeAllListeners(event?: AudioRecorderEvent): void {
		if (event) {
			this.eventEmitter.removeAllListeners(event);
			this.listeners.delete(event);
		} else {
			const events: AudioRecorderEvent[] = [
				'onRecordingStarted',
				'onRecordingStopped',
				'onRecordingPaused',
				'onRecordingResumed',
				'onRecordingProgress',
				'onRecordingError',
				'onPlaybackStarted',
				'onPlaybackStopped',
				'onPlaybackPaused',
				'onPlaybackResumed',
				'onPlaybackProgress',
				'onPlaybackCompleted',
				'onPlaybackError',
			];

			events.forEach(e => this.eventEmitter.removeAllListeners(e));
			this.listeners.clear();
		}
	}
}

export const AudioRecorder = new AudioRecorderModule();
export default AudioRecorder;
