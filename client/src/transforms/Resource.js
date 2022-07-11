// @flow

import { Attachments, FormDataTransform } from '@performant-software/shared-components';
import type { Resource as ResourceType } from '../types/Resource';

/**
 * Class for handling transforming resource for PUT/POST requests.
 */
class Resource extends FormDataTransform {
  /**
   * Returns the resource parameter name.
   *
   * @returns {string}
   */
  getParameterName(): string {
    return 'resource';
  }

  /**
   * Returns the resource payload keys.
   *
   * @returns {string[]}
   */
  getPayloadKeys(): Array<string> {
    return [
      'name',
      'project_id',
      'metadata'
    ];
  }

  /**
   * Returns the passed resource record as JSON for PUT/POST requests.
   *
   * @param resource
   *
   * @returns {*}
   */
  toPayload(resource: ResourceType): FormData {
    const formData = super.toPayload(resource);
    Attachments.toPayload(formData, this.getParameterName(), resource, 'content');

    return formData;
  }
}

const ResourceTransform: Resource = new Resource();
export default ResourceTransform;
