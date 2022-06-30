// @flow

import React, { type ComponentType } from 'react';
import { Navigate } from 'react-router-dom';
import AuthenticationService from '../services/Authentication';

type Props = {
  children: any
};

const AuthenticatedRoute: ComponentType<any> = ({ children }: Props) => {
  if (!AuthenticationService.isAuthenticated()) {
    return <Navigate to='/login' />;
  }

  return children;
};

export default AuthenticatedRoute;
