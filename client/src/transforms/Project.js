// @flow

import { BaseTransform } from '@performant-software/shared-components';

/**
 * Class for handling transforming projects for PUT/POST requests.
 */
class Project extends BaseTransform {
  /**
   * Returns the project parameter name.
   *
   * @returns {string}
   */
  getParameterName(): string {
    return 'project';
  }

  /**
   * Returns the project payload keys.
   *
   * @returns {string[]}
   */
  getPayloadKeys(): Array<string> {
    return [
      'uid',
      'name',
      'description',
      'api_key',
      'organization_id'
    ];
  }
}

const ProjectTransform: Project = new Project();
export default ProjectTransform;
