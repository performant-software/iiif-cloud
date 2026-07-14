// @flow

import { FormDataTransform } from '@performant-software/shared-components';
import type { User as UserType } from '../types/User';

/**
 * Class responsible for transforming user objects.
 */
class User extends FormDataTransform {
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
      'api_key'
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
}

const UserTransform: User = new User();
export default UserTransform;
