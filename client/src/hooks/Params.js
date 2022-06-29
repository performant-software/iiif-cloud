// @flow

import React, { type ComponentType } from 'react';
import { useParams } from 'react-router-dom';

const withParams = (WrappedComponent: ComponentType<any>): any => (props) => (
  <WrappedComponent
    {...props}
    {...useParams()}
  />
);

export default withParams;
