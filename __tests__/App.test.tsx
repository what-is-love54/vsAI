/**
 * @format
 */

import React from 'react';
import ReactTestRenderer from 'react-test-renderer';
// -----------------------------------------------------------------------------
import App from '../App';

test('renders correctly', async () => {
	await ReactTestRenderer.act(() => {
		ReactTestRenderer.create(<App />);
	});
});

jest.mock('react-native-bootsplash', () => {
	return {
		hide: jest.fn().mockResolvedValue(''),
		isVisible: jest.fn().mockResolvedValue(false),
		useHideAnimation: jest.fn().mockReturnValue({
			container: {},
			logo: {source: 0},
			brand: {source: 0},
		}),
	};
});
