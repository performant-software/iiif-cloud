// @flow

import React, { type Node } from 'react';
import { Navigate } from 'react-router-dom';
import AuthenticationService from '../services/Authentication';

type Props = {
  children: Array<Node>
};

const AuthenticatedRoute = ({ children }: Props): Node => {
  if (!AuthenticationService.isAuthenticated()) {
    return <Navigate to='/login' />;
  }

  return children;
};

export default AuthenticatedRoute;
