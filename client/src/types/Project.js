// @flow

import type { Organization } from './Organization';

export type Project = {
  id: number,
  uid: string,
  name: string,
  description: string,
  api_key: string,
  organization_id: number,
  organization: Organization
};
