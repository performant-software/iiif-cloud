// @flow

import { BaseService, BaseTransform } from '@performant-software/shared-components';
import AuthenticationTransform from '../transforms/Authentication';

const STORAGE_KEY = 'current_user';

class Authentication extends BaseService {
  /**
   * Returns the authentication base URL.
   *
   * @returns {string}
   */
  getBaseUrl(): string {
    return '/api/auth/login';
  }

  /**
   * Returns the user authentication token.
   *
   * @returns {*}
   */
  getToken(): string {
    const user = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}');
    return user && user.token;
  }

  /**
   * Returns the authentication transform object.
   *
   * @returns {Authentication}
   */
  getTransform(): typeof BaseTransform {
    return AuthenticationTransform;
  }

  /**
   * Returns true if the logged in user is an administrator.
   *
   * @returns {boolean|*}
   */
  isAdmin(): boolean {
    if (!localStorage.getItem(STORAGE_KEY)) {
      return false;
    }

    const user = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}');
    return user && user.user && user.user.admin;
  }

  /**
   * Returns true if the current user is authenticated.
   *
   * @returns {*|boolean}
   */
  isAuthenticated(): boolean {
    if (!localStorage.getItem(STORAGE_KEY)) {
      return false;
    }

    const user = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}');
    const { token, exp } = user;

    const expirationDate = new Date(Date.parse(exp));
    const today = new Date();

    return token && token.length && expirationDate.getTime() > today.getTime();
  }

  /**
   * Attempts to authenticate the current user and stores the response in local storage.
   *
   * @param params
   *
   * @returns {*}
   */
  login(params: any): Promise<any> {
    return this
      .create(params)
      .then((response) => {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(response.data));
        return response;
      });
  }

  /**
   * Removes the properties of the current user from local storage.
   *
   * @returns {Promise<*>}
   */
  logout(): Promise<any> {
    localStorage.removeItem(STORAGE_KEY);
    return Promise.resolve();
  }
}

const AuthenticationService: Authentication = new Authentication();
export default AuthenticationService;
