// @flow

import cx from 'classnames';
import React, { useCallback, useContext, type Node } from 'react';
import { Link } from 'react-router-dom';
import _ from 'underscore';
import { Breadcrumb } from 'semantic-ui-react';
import styles from './Breadcrumbs.module.css';
import UserContext from '../context/UserContext';

const Breadcrumbs = (): Node => {
  const { breadcrumbs } = useContext(UserContext);

  /**
   * Renders the breadcrumb section component.
   *
   * @type {unknown}
   */
  const renderBreadcrumb = useCallback((breadcrumb, index) => {
    const active = index === breadcrumbs.length - 1;

    return (
      <>
        <Breadcrumb.Section
          active={active}
          as={active ? undefined : Link}
          to={breadcrumb.match.pathname}
        >
          { breadcrumb.breadcrumb }
        </Breadcrumb.Section>
        { !active && (
          <Breadcrumb.Divider
            className={styles.divider}
          />
        )}
      </>
    );
  }, [breadcrumbs]);

  return (
    <Breadcrumb
      className={cx(styles.ui, styles.breadcrumbs, styles.big)}
      size='big'
    >
      { _.map(breadcrumbs, renderBreadcrumb) }
    </Breadcrumb>
  );
};

export default Breadcrumbs;
