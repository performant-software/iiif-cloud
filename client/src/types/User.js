// @flow

import type { UserOrganization } from './UserOrganization';

export type User = {
  id: number,
  name: string,
  email: string,
  password: string,
  password_confirmation: string,
  user_organizations: Array<UserOrganization>
};
