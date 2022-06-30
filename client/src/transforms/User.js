// @flow

import { BaseTransform } from '@performant-software/shared-components';
import UserOrganizations from './UserOrganizations';

import type { User as UserType } from '../types/User';

/**
 * Class responsible for transforming user objects.
 */
class User extends BaseTransform {
  /**
   * Returns the user parameter name.
   *
   * @returns {string}
   */
  getParameterName(): string {
    return 'user';
  }

  /**
   * Returns the user payload keys used for PUT/POST requests.
   *
   * @returns {string[]}
   */
  getPayloadKeys(): Array<string> {
    return [
      'admin',
      'name',
      'email',
      'password',
      'password_confirmation',
    ];
  }

  /**
   * Returns the passed user as a dropdown option.
   *
   * @param user
   *
   * @returns {{text: string, value: number, key: number}}
   */
  toDropdown(user: UserType): any {
    return {
      key: user.id,
      value: user.id,
      text: user.name
    };
  }

  /**
   * Returns the passed user record as JSON for PUT/POST requests.
   *
   * @param user
   *
   * @returns {{[p: string]: *}}
   */
  toPayload(user: UserType): any {
    const payload = super.toPayload(user)[this.getParameterName()];

    return {
      [this.getParameterName()]: {
        ...payload,
        ...UserOrganizations.toPayload(user)
      }
    };
  }
}

const UserTransform: User = new User();
export default UserTransform;
