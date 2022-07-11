// @flow

import type { Project } from './Project';

export type Resource = {
  id: number,
  name: string,
  content_url: string,
  exif: any,
  metadata: any,
  project_id: number,
  project: Project
};
