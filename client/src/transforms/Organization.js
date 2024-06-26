// @flow

import { BaseTransform } from '@performant-software/shared-components';
import UserOrganizations from './UserOrganizations';
import type { Organization as OrganizationType } from '../types/Organization';

/**
 * Class responsible for transforming organization objects.
 */
class Organization extends BaseTransform {
  /**
   * Returns the organization parameter name.
   *
   * @returns {string}
   */
  getParameterName(): string {
    return 'organization';
  }

  /**
   * Returns the organization payload keys used for PUT/POST requests.
   *
   * @returns {string[]}
   */
  getPayloadKeys(): Array<string> {
    return [
      'name',
      'location'
    ];
  }

  /**
   * Transforms the passed organization to a dropdown option.
   *
   * @param organization
   *
   * @returns {{text: string, value: number, key: number}}
   */
  toDropdown(organization: OrganizationType): any {
    return {
      key: organization.id,
      value: organization.id,
      text: organization.name
    };
  }

  /**
   * Returns the passed organization for PUT/POST requests.
   *
   * @param organization
   *
   * @returns {{[p: string]: {[p: string]: *}}}
   */
  toPayload(organization: OrganizationType): any {
    const payload = super.toPayload(organization)[this.getParameterName()];

    return {
      [this.getParameterName()]: {
        ...payload,
        ...UserOrganizations.toPayload(organization)
      }
    };
  }
}

const OrganizationTransform: Organization = new Organization();
export default OrganizationTransform;
