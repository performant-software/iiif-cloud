// @flow

import React, { useMemo, type Node } from 'react';
import {
  Link,
  useLocation,
  useMatch,
  useParams,
  useResolvedPath
} from 'react-router-dom';
import { Menu } from 'semantic-ui-react';
import _ from 'underscore';
import RouterUtils from '../utils/Router';

type Props = {
  children?: Node | (active: boolean) => Node,
  pattern?: 'start' | 'end',
  to: string
};

const INDEX_PATH = '/';

const MenuLink = (props: Props): Node => {
  const location = useLocation();
  const params = useParams();

  const { pathname } = useResolvedPath(props.to);
  const currentPath = RouterUtils.getCurrentPath(location, params);
  const match = useMatch({ path: pathname, end: true });

  const active = useMemo(() => {
    let value;

    if (props.pattern === 'start') {
      if (pathname === INDEX_PATH) {
        value = currentPath === pathname;
      } else {
        value = currentPath.startsWith(pathname);
      }
    } else {
      value = match;
    }

    return value;
  }, [currentPath, match, pathname, props.pattern]);

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

MenuLink.defaultProps = {
  pattern: 'start'
};

export default MenuLink;
