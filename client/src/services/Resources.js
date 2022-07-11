// @flow

import { BaseService } from '@performant-software/shared-components';
import Resource from '../transforms/Resource';
import type { Resource as ResourceType } from '../types/Resource';

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

  /**
   * Uploads the passed array of resources.
   *
   * @param resources
   *
   * @returns {*}
   */
  upload(resources: Array<ResourceType>): Promise<any> {
    const url = `${this.getBaseUrl()}/upload`;

    const transform = this.getTransform();
    const payload = transform.toUploadPayload(resources);

    return this.getAxios().post(url, payload, this.getConfig());
  }
}

const ResourcesService: Resources = new Resources();
export default ResourcesService;
