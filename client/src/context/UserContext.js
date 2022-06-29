// @flow

import { createContext } from 'react';

const UserContext: any = createContext({
  breadcrumbs: null,
  setBreadcrumbs: () => {}
});

export default UserContext;
