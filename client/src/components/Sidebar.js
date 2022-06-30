// @flow

import cx from 'classnames';
import React, { useCallback, type ComponentType } from 'react';
import { useNavigate } from 'react-router-dom';
import { Icon, Menu } from 'semantic-ui-react';
import AuthenticationService from '../services/Authentication';
import MenuLink from './MenuLink';
import styles from './Sidebar.module.css';

type Props = {
  context: {
    current: ?HTMLDivElement
  }
};

const Sidebar: ComponentType<any> = (props: Props) => {
  const navigate = useNavigate();

  /**
   * Logs the user out and navigates to the index page.
   *
   * @type {function(): Promise<R>|Promise<R|unknown>|Promise<*>|*}
   */
  const onLogout = useCallback(() => AuthenticationService.logout().then(() => navigate('/login')), []);

  return (
    <div
      className={styles.adminSidebar}
      ref={props.context}
    >
      <Menu
        className={cx(styles.ui, styles.vertical, styles.icon, styles.menu)}
        inverted
        icon='labeled'
        vertical
      >
        <Menu.Item
          className={styles.item}
        >
          <Icon
            name='cloud'
            size='big'
            style={{
              color: '#b4cded'
            }}
          />
        </Menu.Item>
        <MenuLink
          className={styles.item}
          to='/dashboard'
        >
          <Icon
            name='chart bar'
            size='big'
          />
        </MenuLink>
        <MenuLink
          className={styles.item}
          index
          to='/organizations'
        >
          <Icon
            className={styles.icon}
            name='building outline'
            size='big'
          />
        </MenuLink>
        <MenuLink
          className={styles.item}
          index
          to='users'
        >
          <Icon
            name='users'
            size='big'
          />
        </MenuLink>
        <Menu.Item
          className={styles.item}
          onClick={onLogout}
        >
          <Icon
            flipped='horizontally'
            name='log out'
            size='big'
          />
        </Menu.Item>
      </Menu>
    </div>
  );
};

export default Sidebar;
