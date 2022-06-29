// @flow

import React, { useCallback, useState, type Node } from 'react';
import { LoginModal } from '@performant-software/semantic-components';
import { useNavigate } from 'react-router-dom';
import { Image } from 'semantic-ui-react';
import AuthenticationService from '../services/Authentication';
import styles from './Login.module.css';

const Login = (): Node => {
  const [disabled, setDisabled] = useState(false);
  const [email, setEmail] = useState();
  const [error, setError] = useState(false);
  const [password, setPassword] = useState();

  const navigate = useNavigate();

  /**
   * After authentication is successful, navigates to the correct page.
   *
   * @type {(function({data: *}): void)|*}
   */
  const onAuthentication = useCallback(({ data }) => {
    const { user } = data;

    if (user && !user.admin) {
      navigate('/organizations');
    } else if (user && user.admin) {
      navigate('/');
    }
  }, []);

  /**
   * Attempts to authenticate then navigates to the admin page.
   *
   * @type {(function(): void)|*}
   */
  const onLogin = useCallback(() => {
    setDisabled(true);

    AuthenticationService
      .login({ email, password })
      .then(onAuthentication)
      .catch(() => setError(true))
      .finally(() => setDisabled(false));
  }, [email, password]);

  return (
    <div
      className={styles.login}
    >
      <Image
        className={styles.background}
        src='/assets/clouds.jpeg'
      />
      <LoginModal
        disabled={disabled}
        loginFailed={error}
        onLogin={onLogin}
        onPasswordChange={(e, { value }) => setPassword(value)}
        onUsernameChange={(e, { value }) => setEmail(value)}
        open
      />
    </div>
  );
};

export default Login;
