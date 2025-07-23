// @flow

import React, { type ComponentType } from 'react';
import { DndProvider } from 'react-dnd';
import { HTML5Backend } from 'react-dnd-html5-backend';
import {
  BrowserRouter as Router,
  Navigate,
  Route,
  Routes
} from 'react-router';
import Layout from './components/Layout';
import AuthenticatedRoute from './components/AuthenticatedRoute';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import Organization from './pages/Organization';
import Organizations from './pages/Organizations';
import Project from './pages/Project';
import Projects from './pages/Projects';
import Resource from './pages/Resource';
import Resources from './pages/Resources';
import User from './pages/User';
import Users from './pages/Users';

const App: ComponentType<any> = () => (
  <DndProvider
    backend={HTML5Backend}
  >
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
            path='/organizations/:organizationId'
          />
          <Route
            path='/projects'
          >
            <Route
              element={<Projects />}
              index
            />
            <Route
              element={<Project />}
              path='new'
            />
            <Route
              path=':projectId'
            >
              <Route
                element={<Project />}
                index
              />
              <Route
                path='resources'
              >
                <Route
                  element={<Resources />}
                  index
                />
                <Route
                  element={<Resource />}
                  path='new'
                />
                <Route
                  element={<Resource />}
                  path=':resourceId'
                />
              </Route>
            </Route>
          </Route>
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
            path='/users/:userId'
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
  </DndProvider>
);

export default App;
