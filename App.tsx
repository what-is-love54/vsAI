/** @format */

// Example: App.tsx
import React from 'react';
import {Button, Text, View} from 'react-native';
import {useInit} from '~/hooks';
import NativeMicRecorder from '~/modules/NativeMicRecorder';
import {SafeAreaProvider} from 'react-native-safe-area-context';

export default function App() {
	useInit();

	const [recording, setRecording] = React.useState(false);
	const [error, setError] = React.useState<string | null>(null);

	const handleToggleRecord = async () => {
		setError(null);
		try {
			if (!recording) {
				await NativeMicRecorder.start();
				setRecording(true);
			} else {
				await NativeMicRecorder.stop(); // stops & plays
				setRecording(false);
			}
		} catch (e: unknown) {
			setError(e?.message ?? 'Unknown error');
			setRecording(false);
		}
	};

	return (
		<SafeAreaProvider>
			<View
				style={{
					flex: 1,
					alignItems: 'center',
					justifyContent: 'center',
					gap: 16,
				}}
			>
				<Button
					title={recording ? 'Stop & Play' : 'Start Recording'}
					onPress={handleToggleRecord}
				/>
				{!!error && <Text style={{color: 'red'}}>{error}</Text>}
			</View>
		</SafeAreaProvider>
	);
}
