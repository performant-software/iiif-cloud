// @flow

import React, { type ComponentType, useContext } from 'react';
import { Navigate } from 'react-router';
import { AuthenticationContext } from '../contexts/AuthenticationContext';

type Props = {
  children: any
};

const AuthenticatedRoute: ComponentType<any> = ({ children }: Props) => {
  const { user } = useContext(AuthenticationContext);

  if (!user) {
    return <Navigate to='/login' />;
  }

  return children;
};

export default AuthenticatedRoute;
