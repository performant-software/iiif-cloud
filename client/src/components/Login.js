// @flow

import { LoginModal } from '@performant-software/semantic-components';
import React, { type ComponentType, useCallback, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import AuthenticationService from '../services/Authentication';

const Login: ComponentType<any> = () => {
  const [disabled, setDisabled] = useState(false);
  const [email, setEmail] = useState();
  const [error, setError] = useState(false);
  const [password, setPassword] = useState();

  const navigate = useNavigate();

  /**
   * Attempts to authenticate then navigates to the admin page.
   *
   * @type {(function(): void)|*}
   */
  const onLogin = useCallback(() => {
    setDisabled(true);

    AuthenticationService
      .login({ email, password })
      .then(() => navigate('/admin'))
      .catch(() => setError(true))
      .finally(() => setDisabled(false));
  }, [email, password]);

  return (
    <LoginModal
      disabled={disabled}
      loginFailed={error}
      onLogin={onLogin}
      onPasswordChange={(e, { value }) => setPassword(value)}
      onUsernameChange={(e, { value }) => setEmail(value)}
      open
    />
  );
};

export default Login;
