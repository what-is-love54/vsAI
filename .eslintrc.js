/** @format */

module.exports = {
	root: true,
	extends: [
		'@react-native',
		'eslint:recommended',
		'plugin:@typescript-eslint/recommended-type-checked',
		'plugin:react/recommended',
		'plugin:react-hooks/recommended',
	],
	parser: '@typescript-eslint/parser',
	parserOptions: {
		ecmaVersion: 'latest',
		sourceType: 'module',
		project: './tsconfig.json',
		ecmaFeatures: {
			jsx: true,
		},
	},
	plugins: ['react', 'react-hooks', 'react-native', '@typescript-eslint'],
	settings: {
		react: {
			version: 'detect',
		},
	},
	env: {
		'react-native/react-native': true,
		node: true,
		es2021: true,
	},
	globals: {
		__DEV__: 'readonly',
	},
	ignorePatterns: ['dist', 'node_modules', 'android', 'ios', '.expo', '*.config.js'],
	rules: {
		indent: ['error', 'tab', {SwitchCase: 1}],
		quotes: ['error', 'single'],
		semi: ['error', 'always'],
		'no-empty-function': 'error',
		'max-len': [
			'error',
			{
				code: 120,
				ignorePattern: '^\\s*className=',
				ignoreStrings: true,
				ignoreTemplateLiterals: true,
			},
		],
		'padding-line-between-statements': [
			'error',
			{blankLine: 'always', prev: ['const', 'let', 'var'], next: '*'},
			{
				blankLine: 'any',
				prev: ['const', 'let', 'var'],
				next: ['const', 'let', 'var'],
			},
		],
		'arrow-spacing': ['error', {before: true, after: true}],
		'@typescript-eslint/no-unused-vars': [
			'warn',
			{
				args: 'all',
				argsIgnorePattern: '^_',
				caughtErrors: 'all',
				caughtErrorsIgnorePattern: '^_',
				destructuredArrayIgnorePattern: '^_',
				varsIgnorePattern: '^_',
				ignoreRestSiblings: true,
			},
		],
		'react/jsx-no-undef': ['warn', {allowGlobals: true}],
		'react/react-in-jsx-scope': 'off',
		'@typescript-eslint/no-inferrable-types': 'off',
		'@typescript-eslint/no-explicit-any': 'off',
		'require-await': 'warn',
		'@typescript-eslint/require-await': 'warn',
		'@typescript-eslint/promise-function-async': 'warn',
		'@typescript-eslint/await-thenable': 'error',
		'@typescript-eslint/no-floating-promises': 'warn',
		'@typescript-eslint/no-misused-promises': [
			'error',
			{
				checksVoidReturn: {
					attributes: false,
				},
			},
		],
		// React Native specific
		'react-native/no-unused-styles': 'warn',
		'react-native/no-inline-styles': 'warn',
		'react-native/no-color-literals': 'off',
		'react-native/no-raw-text': 'off',
	},
};
