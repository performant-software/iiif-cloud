// @flow

import { Attachments, FormDataTransform } from '@performant-software/shared-components';
import type { Project as ProjectType } from '../types/Project';

/**
 * Class for handling transforming projects for PUT/POST requests.
 */
class Project extends FormDataTransform {
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
      'organization_id',
      'metadata'
    ];
  }

  /**
   * Returns the passed project record as JSON for PUT/POST requests.
   *
   * @param project
   *
   * @returns {*}
   */
  toPayload(project: ProjectType): FormData {
    const formData = super.toPayload(project);
    Attachments.toPayload(formData, this.getParameterName(), project, 'avatar');

    return formData;
  }
}

const ProjectTransform: Project = new Project();
export default ProjectTransform;
