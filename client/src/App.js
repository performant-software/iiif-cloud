// @flow

import { useDragDrop } from '@performant-software/shared-components';
import React, { type ComponentType } from 'react';
import {
  BrowserRouter as Router,
  Navigate,
  Route,
  Routes
} from 'react-router-dom';
import Layout from './components/Layout';
import AuthenticatedRoute from './components/AuthenticatedRoute';
import Dashboard from './pages/Dashboard';
import Organizations from './pages/Organizations';
import Users from './pages/Users';
import Login from './pages/Login';
import Organization from './pages/Organization';
import User from './pages/User';

const App: ComponentType<any> = useDragDrop(() => (
  <Router>
    <Routes>
      <Route
        element={<Login />}
        exact
        path='/'
      />
      <Route
        element={(
          <AuthenticatedRoute>
            <Layout />
          </AuthenticatedRoute>
        )}
        path='/'
      >
        <Route
          element={<Dashboard />}
          path='/dashboard'
        />
        <Route
          element={<Organizations />}
          path='/organizations'
        />
        <Route
          element={<Organization />}
          path='/organizations/new'
        />
        <Route
          element={<Organization />}
          path='/organizations/:id'
        />
        <Route
          element={<Users />}
          path='/users'
        />
        <Route
          element={<User />}
          path='/users/new'
        />
        <Route
          element={<User />}
          path='/users/:id'
        />
      </Route>
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
