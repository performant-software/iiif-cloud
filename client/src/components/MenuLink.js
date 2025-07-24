// @flow

import cx from 'classnames';
import React, { type ComponentType, type Node } from 'react';
import { Link, useMatch, useResolvedPath } from 'react-router';
import { Menu } from 'semantic-ui-react';
import styles from './MenuLink.module.css';

type Props = {
  children?: Node | (active: boolean) => Node,
  className?: string,
  content?: Node | string,
  parent?: boolean,
  to: string
};

const MenuLink: ComponentType<any> = (props: Props) => {
  const url = `${props.to}${props.parent ? '/*' : ''}`;
  const { pathname } = useResolvedPath(url);
  const active = !!useMatch({ path: pathname, end: true });

  return (
    <Menu.Item
      active={active}
      className={cx(styles.menuLink, props.className)}
    >
      <Link
        className={styles.link}
        to={props.to}
      />
      { props.content }
      { props.children }
    </Menu.Item>
  );
};

export default MenuLink;
