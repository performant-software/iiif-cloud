// @flow

import type { Organization } from './Organization';

export type Project = {
  id: number,
  uid: string,
  name: string,
  description: string,
  api_key: string,
  organization_id: number,
  organization: Organization,
  avatar_url: string,
  avatar_download_url: string,
  avatar_thumbnail_url: string
};
