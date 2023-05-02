// @flow

import React from 'react';

type Props = {
  label?: string,
  value: string
};

const ReadOnlyField = (props: Props) => (
  <div
    className='field'
  >
    { props.label && (
      <label
        htmlFor='read-only-element'
      >
        { props.label }
      </label>
    )}
    <div
      id='read-only-element'
      className='ui input'
      role='textbox'
    >
      { props.value }
    </div>
  </div>
);

export default ReadOnlyField;
