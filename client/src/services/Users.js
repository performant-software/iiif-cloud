// @flow

import { BaseService } from '@performant-software/shared-components';
import User from '../transforms/User';

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
}

const UsersService: Users = new Users();
export default UsersService;
