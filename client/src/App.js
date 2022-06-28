// @flow

import { useDragDrop } from '@performant-software/shared-components';
import React, { useMemo, type ComponentType } from 'react';
import { useRoutes } from 'react-router-dom';
import useBreadcrumbs from 'use-react-router-breadcrumbs';
import Routes from './config/Routes';
import UserContext from './context/UserContext';

const App: ComponentType<any> = useDragDrop(() => {
  const breadcrumbs = useBreadcrumbs(Routes, { excludePaths: ['/'] });
  const routes = useRoutes(Routes);

  const userContext = useMemo(() => ({
    breadcrumbs
  }), [breadcrumbs]);

  return (
    <UserContext.Provider
      value={userContext}
    >
      { routes }
    </UserContext.Provider>
  );
});

export default App;
