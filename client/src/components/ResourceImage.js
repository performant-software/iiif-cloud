// @flow

import React, { type ComponentType, type Element } from 'react';
import { LazyDocument, LazyImage, LazyVideo } from '@performant-software/semantic-components';
import _ from 'underscore';

type Props = {
  children: Element<any>,
  contentType: string,
};

const ResourceImage: ComponentType<any> = ({ contentType, children, ...rest }: Props) => {
  if (!contentType || contentType.startsWith('image')) {
    return (
      <LazyImage
        {...rest}
      >
        { children }
      </LazyImage>
    );
  }

  if (contentType.startsWith('video')) {
    return (
      <LazyVideo
        {...rest}
      >
        { children }
      </LazyVideo>
    );
  }

  if (contentType.startsWith('audio') || contentType === 'application/pdf') {
    return (
      <LazyDocument
        {..._.omit(rest, 'src')}
      >
        { children }
      </LazyDocument>
    );
  }

  return null;
};

export default ResourceImage;
