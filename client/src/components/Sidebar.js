// @flow

import cx from 'classnames';
import React, { useCallback, type ComponentType } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Icon, Menu, Popup } from 'semantic-ui-react';
import AuthenticationService from '../services/Authentication';
import MenuLink from './MenuLink';
import styles from './Sidebar.module.css';
import { withTranslation } from 'react-i18next';
import type { Translateable } from '../types/Translateable';

type Props = Translateable & {
  context: {
    current: ?HTMLDivElement
  }
};

const Sidebar: ComponentType<any> = withTranslation()((props: Props) => {
  const navigate = useNavigate();
  const params = useParams();

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
        { AuthenticationService.isAdmin() && (
          <Popup
            content={props.t('Sidebar.labels.dashboard')}
            mouseEnterDelay={1000}
            position='right center'
            trigger={(
              <MenuLink
                className={styles.item}
                to='/dashboard'
              >
                <Icon
                  name='chart bar'
                  size='big'
                />
              </MenuLink>
            )}
          />
        )}
        { AuthenticationService.isAdmin() && (
          <Popup
            content={props.t('Sidebar.labels.organizations')}
            mouseEnterDelay={1000}
            position='right center'
            trigger={(
              <MenuLink
                className={styles.item}
                parent
                to='/organizations'
              >
                <Icon
                  className={styles.icon}
                  name='building outline'
                  size='big'
                />
              </MenuLink>
            )}
          />
        )}
        <Popup
          content={props.t('Sidebar.labels.projects')}
          mouseEnterDelay={1000}
          position='right center'
          trigger={(
            <MenuLink
              className={styles.item}
              parent
              to='/projects'
            >
              <Icon
                className={styles.icon}
                name='folder outline'
                size='big'
              />
              { params.projectId && (
                <Menu.Menu>
                  <MenuLink
                    content={props.t('Sidebar.labels.details')}
                    to={`/projects/${params.projectId}`}
                  />
                  <MenuLink
                    content={props.t('Sidebar.labels.resources')}
                    parent
                    to={`/projects/${params.projectId}/resources`}
                  />
                </Menu.Menu>
              )}
            </MenuLink>
          )}
        />
        <Popup
          content={props.t('Sidebar.labels.users')}
          mouseEnterDelay={1000}
          position='right center'
          trigger={(
            <MenuLink
              className={styles.item}
              parent
              to='users'
            >
              <Icon
                name='users'
                size='big'
              />
            </MenuLink>
          )}
        />
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
});

export default Sidebar;
