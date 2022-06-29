// @flow

import React, { type Node } from 'react';
import { useLocation, useParams, useResolvedPath } from 'react-router-dom';
import { Menu } from 'semantic-ui-react';
import _ from 'underscore';
import MenuLink from './MenuLink';
import RouterUtils from '../utils/Router';

type Item = {
  content: string | Node,
  path?: string
};

type Props = {
  basePath: string,
  items: Array<Item>,
  id: string
};

const SubMenu = (props: Props): Node => {
  const location = useLocation();
  const params = useParams();

  const { pathname } = useResolvedPath(`${props.basePath}/:${props.id}`);
  const currentPath = RouterUtils.getCurrentPath(location, params);

  let active;

  if (pathname === '/') {
    active = currentPath === pathname;
  } else {
    active = currentPath.startsWith(pathname);
  }

  const id = params[props.id];

  if (!active) {
    return null;
  }

  return (
    <Menu.Menu>
      { _.map(props.items, (item) => (
        <MenuLink
          content={item.content}
          pattern='end'
          to={RouterUtils.join(props.basePath, id, item.path)}
        />
      ))}
    </Menu.Menu>
  );
};

export default SubMenu;
