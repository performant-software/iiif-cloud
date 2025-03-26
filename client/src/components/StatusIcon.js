// @flow

import React, { type ComponentType } from 'react';
import { Icon } from 'semantic-ui-react';

type Props = {
  className?: string,
  status: 'positive' | 'warning' | 'negative'
};

const StatusIcon: ComponentType<any> = (props: Props) => {
  if (props.status === 'positive') {
    return (
      <Icon
        className={props.className}
        color='green'
        name='check circle'
      />
    );
  }

  if (props.status === 'warning') {
    return (
      <Icon
        className={props.className}
        color='yellow'
        name='warning circle'
      />
    );
  }

  if (props.status === 'negative') {
    return (
      <Icon
        className={props.className}
        color='red'
        name='times circle'
      />
    );
  }

  return null;
};

export default StatusIcon;
