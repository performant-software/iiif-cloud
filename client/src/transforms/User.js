// @flow

import { Attachments, FormDataTransform } from '@performant-software/shared-components';
import type { User as UserType } from '../types/User';
import UserOrganizations from './UserOrganizations';

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
      'admin',
      'name',
      'email'
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
    const formData = super.toPayload(user);
    Attachments.toPayload(formData, this.getParameterName(), user, 'avatar');
    UserOrganizations.toFormData(formData, this.getParameterName(), user);

    // Only include the password/confirmation in the payload if we're changing it
    if (user.password && user.password_confirmation) {
      formData.append(`${this.getParameterName()}[password]`, user.password);
      formData.append(`${this.getParameterName()}[password_confirmation]`, user.password_confirmation);
    }

    return formData;
  }
}

const UserTransform: User = new User();
export default UserTransform;
