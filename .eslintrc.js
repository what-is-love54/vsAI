/** @format */

module.exports = {
	root: true,
	extends: [
		'@react-native',
		'eslint:recommended',
		'plugin:@typescript-eslint/recommended',
		'plugin:react/recommended',
		'plugin:react-hooks/recommended',
	],
	parser: '@typescript-eslint/parser',
	parserOptions: {
		ecmaVersion: 'latest',
		sourceType: 'module',
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
	ignorePatterns: [
		'dist',
		'node_modules',
		'android',
		'ios',
		'.expo',
		'*.config.js',
		'.eslintrc.js',
		'babel.config.js',
		'metro.config.js',
		'jest.config.js',
	],
	overrides: [
		{
			files: ['*.ts', '*.tsx'],
			parserOptions: {
				project: './tsconfig.json',
			},
			extends: ['plugin:@typescript-eslint/recommended-type-checked'],
			rules: {
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
			},
		},
	],
	rules: {
		indent: ['error', 'tab', {SwitchCase: 1}],
		quotes: ['error', 'single'],
		semi: ['error', 'always'],
		'no-empty-function': 'error',
		'max-len': [
			'error',
			{
				code: 100,
				ignorePattern: '^\\s*className=',
				ignoreStrings: true,
				ignoreTemplateLiterals: true,
			},
		],
		'padding-line-between-statements': [
			'error',
			{blankLine: 'always', prev: ['const', 'var'], next: '*'},
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
		'react-native/no-unused-styles': 'warn',
		'react-native/no-inline-styles': 'warn',
		'react-native/no-color-literals': 'off',
		'react-native/no-raw-text': 'off',
	},
};
