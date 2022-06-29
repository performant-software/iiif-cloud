// @flow

import React from 'react';
import Breadcrumb from '../components/Breadcrumb';
import Dashboard from '../pages/Dashboard';
import DetailLayout from '../components/DetailLayout';
import i18n from '../i18n/i18n';
import Layout from '../components/Layout';
import Login from '../pages/Login';
import Organization from '../pages/Organization';
import Organizations from '../pages/Organizations';
import OrganizationsService from '../services/Organizations';
import User from '../pages/User';
import Users from '../pages/Users';
import UsersService from '../services/Users';

const OrganizationBreadcrumbProps = {
  idParam: 'organizationId',
  parameterName: 'organization',
  serviceClass: OrganizationsService,
  renderItem: (item) => item.name
};

const UserBreadcrumbProps = {
  idParam: 'userId',
  parameterName: 'user',
  serviceClass: UsersService,
  renderItem: (item) => item.name
};

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
      path: '/organizations/new',
      element: <DetailLayout />,
      children: [{
        index: true,
        element: <Organization />
      }]
    }, {
      path: '/organizations/:organizationId',
      element: <DetailLayout />,
      children: [{
        index: true,
        element: <Organization />,
        breadcrumb: Breadcrumb,
        props: OrganizationBreadcrumbProps
      }, {
        path: '/organizations/:organizationId/users',
        children: [{
          index: true,
          element: <Users />,
          breadcrumb: i18n.t('Routes.users')
        }, {
          path: '/organizations/:organizationId/users/new',
          element: <User />
        }, {
          path: '/organizations/:organizationId/users/:userId',
          element: <User />,
          breadcrumb: Breadcrumb,
          props: UserBreadcrumbProps
        }]
      }]
    }],
  }, {
    path: 'users',
    children: [{
      index: true,
      element: <Users />,
      breadcrumb: i18n.t('Routes.users')
    }, {
      path: '/users/new',
      element: <DetailLayout />,
      children: [{
        index: true,
        element: <User />
      }]
    }, {
      path: '/users/:userId',
      element: <DetailLayout />,
      children: [{
        index: true,
        element: <User />,
        breadcrumb: Breadcrumb,
        props: UserBreadcrumbProps
      }, {
        path: '/users/:userId/organizations',
        children: [{
          index: true,
          element: <Organizations />,
          breadcrumb: i18n.t('Routes.organizations')
        }, {
          path: '/users/:userId/organizations/new',
          element: <Organization />
        }, {
          path: '/users/:userId/organizations/:organizationId',
          element: <Organization />,
          breadcrumb: Breadcrumb,
          props: OrganizationBreadcrumbProps
        }]
      }]
    }]
  }]
}, {
  path: '/login',
  element: <Login />
}];

export default Routes;
