// @flow

import React, { type ComponentType } from 'react';
import {
  BrowserRouter as Router,
  Navigate,
  Route,
  Routes
} from 'react-router-dom';
import { useDragDrop } from '@performant-software/shared-components';
import AuthenticatedRoute from './components/AuthenticatedRoute';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import AdminLayout from './layouts/AdminLayout';
import Organizations from './pages/Organizations';
import Users from './pages/Users';

const App: ComponentType<any> = useDragDrop(() => (
  <Router>
    <Routes>
      <Route
        element={(
          <AuthenticatedRoute>
            <AdminLayout />
          </AuthenticatedRoute>
        )}
        path='/'
      >
        <Route
          element={<Dashboard />}
          index
        />
        <Route
          element={<Organizations />}
          path='/organizations'
        />
        <Route
          element={<Users />}
          path='/users'
        />
      </Route>
      <Route
        element={<Login />}
        path='/login'
      />
      <Route
        element={(
          <Navigate
            replace
            to='/'
          />
        )}
        path='*'
      />
    </Routes>
  </Router>
));

export default App;
