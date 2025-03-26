// @flow

import React, { type ComponentType } from 'react';
import styles from './AttributeView.module.css';

type Props = {
  label: string,
  value: string
};

const AttributeView: ComponentType<any> = (props: Props) => (
  <div
    className={styles.gridItem}
  >
    <div
      className={styles.label}
    >
      { props.label }
    </div>
    <div
      className={styles.value}
    >
      { props.value }
    </div>
  </div>
);

export default AttributeView;
