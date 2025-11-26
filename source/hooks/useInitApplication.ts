/** @format */

import {useEffect} from 'react';
import RNBootSplash from 'react-native-bootsplash';
// -----------------------------------------------------------------------------

export const useInit = () => {
	useEffect(() => {
		const initializing = async () => {
			try {
				console.info('=-> App Starting');
			} catch (err) {
				console.error('=-> App Error', err);
			} finally {
				console.info('=-> App Started');
				await RNBootSplash.hide({fade: true});
			}
		};

		initializing().catch(err => console.error('=-> App Error', err));
	}, []);
};
