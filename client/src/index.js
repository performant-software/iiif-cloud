// @flow

import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter as Router } from 'react-router-dom';
import App from './App';

// Configuration
import './config/Api';
import './i18n/i18n';

// CSS
import '@performant-software/shared-components/build/main.css';
import '@performant-software/semantic-components/build/main.css';
import '@performant-software/semantic-components/build/semantic-ui.css';
import './index.css';

const root = ReactDOM.createRoot(document.getElementById('root'));

root.render(
  <Router>
    <App />
  </Router>
);
