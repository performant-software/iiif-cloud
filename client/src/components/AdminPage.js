// @flow

import React, { type ComponentType } from 'react';
import { Navigate } from 'react-router-dom';
import AuthenticationService from '../services/Authentication';

const AdminPage: ComponentType<any> = (props) => {
  if (!AuthenticationService.isAdmin()) {
    return <Navigate to='/' />;
  }

  return props.children;
};

export default AdminPage;
