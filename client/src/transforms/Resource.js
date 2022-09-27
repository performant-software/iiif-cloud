// @flow

import { Attachments, FormDataTransform } from '@performant-software/shared-components';
import { FieldableTransform } from '@performant-software/user-defined-fields';
import _ from 'underscore';
import type { Resource as ResourceType } from '../types/Resource';
import String from '../utils/String';

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
      'project_id'
    ];
  }

  /**
   * Returns the passed resource record as FormData for PUT/POST requests.
   *
   * @param resource
   *
   * @returns {FormData}
   */
  toPayload(resource: ResourceType): FormData {
    const formData = super.toPayload(resource);
    Attachments.toPayload(formData, this.getParameterName(), resource, 'content');
    FieldableTransform.toFormData(formData, this.getParameterName(), resource);

    return formData;
  }

  /**
   * Returns the passed array of resources as FormData for multi-record upload.
   *
   * @param resources
   *
   * @returns {FormData}
   */
  toUploadPayload(resources: Array<ResourceType>): FormData {
    const formData = new FormData();

    _.each(resources, (resource, index) => {
      _.each(this.getPayloadKeys(), (key) => {
        formData.append(`resources[${index}][${key}]`, String.toString(resource[key]));
      });

      Attachments.toPayload(formData, `resources[${index}]`, resource, 'content');
    });

    return formData;
  }
}

const ResourceTransform: Resource = new Resource();
export default ResourceTransform;
