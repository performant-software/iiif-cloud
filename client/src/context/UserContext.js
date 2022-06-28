// @flow

import { createContext } from 'react';

const UserContext: any = createContext({
  organization: null,
  setOrganization: () => {},
  setUser: () => {},
  user: null
});

export default UserContext;
