// @flow

import React, { type ComponentType, useContext } from 'react';
import { SignIn } from '@clerk/react';
import { Navigate } from 'react-router';
import styles from './Login.module.css';
import ClerkLoginModal from '../components/ClerkLoginModal';
import { AuthenticationContext } from '../contexts/AuthenticationContext';

const isDevelopment = import.meta.env.VITE_ENVIRONMENT === 'development';

const Login: ComponentType<any> = () => {
  const { user } = useContext(AuthenticationContext);

  if (user) {
    if (user.admin) {
      return <Navigate to='/dashboard' />;
    } else {
      return <Navigate to='/projects' />;
    }
  }

  return (
    <div
      className={styles.login}
    >
      {isDevelopment
        ? <SignIn />
        : <ClerkLoginModal />
      }
    </div>
  );
};

export default Login;
