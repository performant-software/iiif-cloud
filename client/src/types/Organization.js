// @flow

import type { UserOrganization } from './UserOrganization';

export type Organization = {
  id: number,
  name: string,
  location: string,
  user_organizations: Array<UserOrganization>
};
