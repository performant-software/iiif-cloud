// @flow

import { BaseService } from '@performant-software/shared-components';
import Organization from '../transforms/Organization';

/**
 * Class responsible for handling all organizations API requests.
 */
class Organizations extends BaseService {
  /**
   * Returns the organizations base URL.
   *
   * @returns {string}
   */
  getBaseUrl(): string {
    return '/api/organizations';
  }

  /**
   * Returns the organizations transform object.
   *
   * @returns {Organization}
   */
  getTransform(): any {
    return Organization;
  }
}

const OrganizationsService: Organizations = new Organizations();
export default OrganizationsService;
