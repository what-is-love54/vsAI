/** @format */

import {useEffect} from 'react';
import RNBootSplash from 'react-native-bootsplash';
// -----------------------------------------------------------------------------

export const useInit = () => {
	useEffect(() => {
		const initializing = async () => {
			try {
				__DEV__ && console.info('==-> Application Starting');
			} catch (err) {
				console.error('==-> Application Error', err);
			} finally {
				console.info('==-> Application Started');
				await RNBootSplash.hide({fade: true});
			}
		};

		initializing().catch(err => console.error('=-> App Error', err));
	}, []);
};
