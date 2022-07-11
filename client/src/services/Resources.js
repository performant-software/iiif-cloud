// @flow

import { BaseService } from '@performant-software/shared-components';
import Resource from '../transforms/Resource';

/**
 * Class responsible for handling all resource API requests.
 */
class Resources extends BaseService {
  /**
   * Returns the resources base URL.
   *
   * @returns {string}
   */
  getBaseUrl(): string {
    return '/api/resources';
  }

  /**
   * Returns the resources transform object.
   *
   * @returns {Resource}
   */
  getTransform(): any {
    return Resource;
  }
}

const ResourcesService: Resources = new Resources();
export default ResourcesService;
