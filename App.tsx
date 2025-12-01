/** @format */

import React, {useState, useEffect} from 'react';
import {View, Button, Text, PermissionsAndroid, Platform} from 'react-native';
import {useInit} from '~/hooks';
import AudioRecorder from '~/modules/audio-recorder';

const App = () => {
	useInit();

	const [isRecording, setIsRecording] = useState(false);
	const [recordedFile, setRecordedFile] = useState<string | null>(null);
	const [duration, setDuration] = useState(0);

	const requestPermissions = async () => {
		if (Platform.OS === 'android') {
			const granted = await PermissionsAndroid.request(
				PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
			);

			return granted === PermissionsAndroid.RESULTS.GRANTED;
		} else {
			return await AudioRecorder.requestPermissions();
		}
	};

	const handleStartRecording = async () => {
		try {
			const filePath = await AudioRecorder.startRecording();

			setIsRecording(true);
			setRecordedFile(filePath);
		} catch (error) {
			console.error('Failed to start recording:', error);
		}
	};

	const handleStopRecording = async () => {
		try {
			const filePath = await AudioRecorder.stopRecording();

			setIsRecording(false);
			setRecordedFile(filePath);
		} catch (error) {
			console.error('Failed to stop recording:', error);
		}
	};

	const handlePlayRecording = async () => {
		if (recordedFile) {
			try {
				await AudioRecorder.playRecording(recordedFile);
			} catch (error) {
				console.error('Failed to play recording:', error);
			}
		}
	};

	useEffect(() => {
		requestPermissions();

		// Subscribe to events
		const progressListener = AudioRecorder.addEventListener(
			'onRecordingProgress',
			event => {
				setDuration(event.duration);
			},
		);

		const completedListener = AudioRecorder.addEventListener(
			'onPlaybackCompleted',
			() => {
				console.log('Playback completed');
			},
		);

		return () => {
			progressListener();
			completedListener();
		};
	}, []);

	return (
		<View style={{flex: 1, justifyContent: 'center', alignItems: 'center'}}>
			<Text>Duration: {duration.toFixed(1)}s</Text>

			{!isRecording ? (
				<Button
					title="Start Recording"
					onPress={handleStartRecording}
				/>
			) : (
				<Button
					title="Stop Recording"
					onPress={handleStopRecording}
				/>
			)}

			{recordedFile && !isRecording && (
				<Button
					title="Play Recording"
					onPress={handlePlayRecording}
				/>
			)}
		</View>
	);
};

export default App;
