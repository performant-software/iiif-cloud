// @flow

import type { UserOrganization } from './UserOrganization';

export type User = {
  id: number,
  name: string,
  email: string,
  admin: boolean,
  avatar_url: string,
  avatar_download_url: string,
  avatar_preview_url: string,
  avatar_thumbnail_url: string,
  user_organizations: Array<UserOrganization>
};
