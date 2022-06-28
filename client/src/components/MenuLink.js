// @flow

import React, { type ComponentType, type Node } from 'react';
import {
  Link,
  useLocation,
  useParams,
  useResolvedPath
} from 'react-router-dom';
import { Menu } from 'semantic-ui-react';
import _ from 'underscore';
import RouterUtils from '../utils/Router';

type Props = {
  children: Node<any>,
  index?: boolean,
  to: string
};

const INDEX_PATH = '/';

const MenuLink: ComponentType<any> = (props: Props) => {
  const location = useLocation();
  const params = useParams();

  const { pathname } = useResolvedPath(props.to);
  const currentPath = RouterUtils.getCurrentPath(location, params);

  let active;

  if (pathname === INDEX_PATH) {
    active = currentPath === pathname;
  } else {
    active = currentPath.startsWith(pathname);
  }

  return (
    <Menu.Item
      {..._.omit(props, 'children')}
      active={active}
      as={Link}
    >
      { props.children }
    </Menu.Item>
  );
};

export default MenuLink;
