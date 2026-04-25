module.exports = {
  rootDir: '..',
  roots: ['<rootDir>/public/js'],
  testEnvironment: 'jsdom',
  moduleFileExtensions: ['js', 'jsx'],
  testMatch: [
    '**/public/js/t/**/*.test.js',
    '**/public/js/t/**/*.spec.js'
  ],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/public/js/$1'
  },
  transform: {
    '^.+\\.(js|jsx)$': ['babel-jest', { configFile: './t/babel.config.js' }]
  },
  collectCoverageFrom: [
    'public/js/!(t)/**/*.js',
    'public/js/*.js',
    '!public/js/t/**',
    '!public/js/contrib/**'
  ],
  coverageDirectory: 'coverage',
  verbose: true
};