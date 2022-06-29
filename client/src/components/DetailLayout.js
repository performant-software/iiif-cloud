// @flow

import React, { type Node } from 'react';
import { Outlet } from 'react-router-dom';
import Breadcrumbs from './Breadcrumbs';

const DetailLayout = (): Node => (
  <div>
    <Breadcrumbs />
    <Outlet />
  </div>
);

export default DetailLayout;
