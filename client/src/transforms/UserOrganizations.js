// @flow

import { NestedAttributesTransform } from '@performant-software/shared-components';

class UserOrganizations extends NestedAttributesTransform {
  /**
   * Returns the collection of allowed payload keys.
   *
   * @returns {string[]}
   */
  getPayloadKeys(): Array<string> {
    return [
      'id',
      'organization_id',
      'user_id',
      '_destroy'
    ];
  }

  /**
   * Appends the user_organizations records to the passed form data object.
   *
   * @param formData
   * @param prefix
   * @param record
   * @param collection
   *
   * @returns {void|*}
   */
  toFormData(formData: FormData, prefix: string, record: any, collection: string = 'user_organizations'): void {
    return super.toFormData(formData, prefix, record, collection);
  }

  /**
   * Returns the collection of user_organizations for PUT/POST requests.
   *
   * @param record
   * @param collectionName
   *
   * @returns {*}
   */
  toPayload(record: any, collectionName: string = 'user_organizations'): any {
    return super.toPayload(record, collectionName);
  }
}

const UserOrganizationsTransform: UserOrganizations = new UserOrganizations();
export default UserOrganizationsTransform;
