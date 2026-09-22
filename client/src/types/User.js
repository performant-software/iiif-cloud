// @flow

import type { UserOrganization } from './UserOrganization';

export type User = {
  id: number,
  name: string,
  email: string,
  admin: boolean,
  user_organizations: Array<UserOrganization>
};
