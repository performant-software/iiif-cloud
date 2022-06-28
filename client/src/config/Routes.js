// @flow

import React from 'react';
import Layout from '../components/Layout';
import Dashboard from '../pages/Dashboard';
import Organizations from '../pages/Organizations';
import Users from '../pages/Users';
import Organization from '../pages/Organization';
import Login from '../pages/Login';
import i18n from '../i18n/i18n';

const Routes: any = [{
  path: '/',
  element: <Layout />,
  children: [{
    element: <Dashboard />,
    exact: true,
    index: true
  }, {
    path: '/organizations',
    children: [{
      index: true,
      element: <Organizations />,
      breadcrumb: i18n.t('Routes.organizations')
    }, {
      path: '/organizations/:id',
      children: [{
        index: true,
        element: <Organization />,
        breadcrumb: i18n.t('Routes.organizationDetails')
      }, {
        path: '/organizations/:id/users',
        element: <Users />,
        breadcrumb: i18n.t('Routes.users')
      }]
    }],
  }, {
    path: 'users',
    element: <Users />
  }]
}, {
  path: '/login',
  element: <Login />
}];

export default Routes;
