// @flow

import cx from 'classnames';
import React, { type ComponentType, type Node } from 'react';
import {
  Button,
  Dimmer,
  Header,
  Loader
} from 'semantic-ui-react';
import styles from './Widget.module.css';

type Props = {
  children: Node,
  className?: string,
  loading: boolean,
  onReload?: () => void,
  title: string
};

const Widget: ComponentType<any> = (props: Props) => (
  <div
    className={cx(styles.widget, props.className)}
  >
    <Dimmer
      active={props.loading}
      inverted
    >
      <Loader />
    </Dimmer>
    <div
      className={styles.headerContainer}
    >
      <Header
        className={cx(styles.ui, styles.header)}
      >
        { props.title }
      </Header>
      { props.onReload && (
        <Button
          basic
          className={cx(styles.ui, styles.button, styles.reload)}
          icon='refresh'
          onClick={props.onReload}
        />
      )}
    </div>
    { props.children }
  </div>
);

export default Widget;
