// @flow

import React, { type ComponentType, type Node } from 'react';
import { Link, useMatch, useResolvedPath } from 'react-router-dom';
import { Menu } from 'semantic-ui-react';
import _ from 'underscore';

type Props = {
  children: Node<any>,
  to: string
};

const MenuLink: ComponentType<any> = (props: Props) => {
  const resolved = useResolvedPath(props.to);
  const active = useMatch({ path: resolved.pathname, end: true });

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
