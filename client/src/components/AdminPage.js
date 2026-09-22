// @flow

import React, { type ComponentType, useContext } from 'react';
import { Navigate } from 'react-router';
import { AuthenticationContext } from '../contexts/AuthenticationContext';

const AdminPage: ComponentType<any> = (props) => {
  const { user } = useContext(AuthenticationContext);

  if (!user.admin) {
    return <Navigate to='/' />;
  }

  return props.children;
};

export default AdminPage;
