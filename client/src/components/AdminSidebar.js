// @flow

import cx from 'classnames';
import React, { type ComponentType, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { Icon, Menu } from 'semantic-ui-react';
import AuthenticationService from '../services/Authentication';
import styles from './AdminSidebar.module.css';
import MenuLink from './MenuLink';

const AdminSidebar: ComponentType<any> = (props) => {
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
        icon
        vertical
        secondary
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
          to='/'
        >
          <Icon
            name='chart bar'
            size='big'
          />
        </MenuLink>
        <MenuLink
          className={styles.item}
          to='/organizations'
        >
          <Icon
            name='building outline'
            size='big'
          />
        </MenuLink>
        <MenuLink
          className={styles.item}
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

export default AdminSidebar;
