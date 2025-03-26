// @flow

import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

// Configuration
import './config/Api';
import './i18n/i18n';

// CSS
import '@performant-software/shared-components/style.css';
import '@performant-software/semantic-components/style.css';
import 'react-calendar/dist/Calendar.css';
import './index.css';

ReactDOM.render(
  <App />,
  document.getElementById('root')
);
