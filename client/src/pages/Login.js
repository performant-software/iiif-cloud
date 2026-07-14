// @flow

import React, { type ComponentType } from 'react';
import { SignIn, useAuth } from '@clerk/react';
import { Navigate } from 'react-router';
import styles from './Login.module.css';
import ClerkLoginModal from '../components/ClerkLoginModal';

const isDevelopment = import.meta.env.VITE_ENVIRONMENT === 'development';

const Login: ComponentType<any> = () => {
  const { isLoaded, isSignedIn } = useAuth();

  if (!isLoaded) {
    return null;
  }

  if (isSignedIn) {
    return <Navigate to='/dashboard' />;
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
