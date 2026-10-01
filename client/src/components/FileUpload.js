// @flow

import { LazyMedia } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import {
  Button,
  Form,
  Item,
  Progress
} from 'semantic-ui-react';
import { withTranslation } from 'react-i18next';

const FileUpload: ComponentType<any> = withTranslation()((props) => {
  const progress = props.progress && props.progress[props.item.uid];

  return (
    <Item
      className='file-upload'
    >
      <Item.Image>
        <LazyMedia
          contentType={props.item.content_type}
          dimmable={false}
          src={props.item.content_url}
        />
      </Item.Image>
      <Item.Content>
        <Form.Input
          error={props.isError('name')}
          label={props.t('FileUpload.labels.name')}
          onChange={props.onTextInputChange.bind(this, 'name')}
          required={props.isRequired('name')}
          value={props.item.name}
        />
        <Button
          basic
          color='red'
          icon='trash'
          onClick={props.onDelete}
        />
        { props.renderStatus() }
        { progress !== undefined && (
          <Progress
            className='upload-progress'
            color='blue'
            percent={Math.round(progress * 100)}
            progress
            size='small'
          />
        )}
      </Item.Content>
    </Item>
  );
});

export default FileUpload;
