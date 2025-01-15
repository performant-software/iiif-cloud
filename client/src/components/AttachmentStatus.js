// @flow

import React, { type ComponentType } from 'react';
import { Icon } from 'semantic-ui-react';

type Props = {
  className?: string,
  value: boolean
};

const AttachmentStatus: ComponentType<any> = (props: Props) => {
  if (props.value) {
    return (
      <Icon
        className={props.className}
        color='green'
        name='check circle'
      />
    );
  }

  return (
    <Icon
      className={props.className}
      color='red'
      name='times circle'
    />
  );
};

export default AttachmentStatus;
