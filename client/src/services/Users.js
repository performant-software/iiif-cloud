// @flow

import { BaseService } from '@performant-software/shared-components';
import User from '../transforms/User';
import type { User as UserType } from '../types/User';

/**
 * Class responsible for handling all users API requests.
 */
class Users extends BaseService {
  /**
   * Returns the users base URL.
   *
   * @returns {string}
   */
  getBaseUrl(): string {
    return '/api/users';
  }

  /**
   * Returns the users transform object.
   *
   * @returns {User}
   */
  getTransform(): any {
    return User;
  }

  getMe(): UserType {
    return this.getAxios().get(`${this.getBaseUrl()}/me`)
  }
}

const UsersService: Users = new Users();
export default UsersService;
