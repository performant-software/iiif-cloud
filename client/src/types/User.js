// @flow

import type { UserOrganization } from './UserOrganization';

export type User = {
  id: number,
  name: string,
  email: string,
  user_organizations: Array<UserOrganization>
};
