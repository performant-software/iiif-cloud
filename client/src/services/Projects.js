// @flow

import { BaseService } from '@performant-software/shared-components';
import Project from '../transforms/Project';

/**
 * Class responsible for handling all projects API requests.
 */
class Projects extends BaseService {
  /**
   * Returns the projects base URL.
   *
   * @returns {string}
   */
  getBaseUrl(): string {
    return '/api/projects';
  }

  /**
   * Returns the projects transform object.
   *
   * @returns {Project}
   */
  getTransform(): any {
    return Project;
  }
}

const ProjectsService: Projects = new Projects();
export default ProjectsService;
