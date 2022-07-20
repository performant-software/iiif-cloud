// @flow

import type { Project } from './Project';

export type Resource = {
  id: number,
  name: string,
  content_url: string,
  content_download_url: string,
  content_preview_url: string,
  content_thumbnail_url: string,
  content_type: string,
  exif: any,
  manifest: string,
  metadata: any,
  project_id: number,
  project: Project
};
