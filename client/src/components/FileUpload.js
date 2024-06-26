// @flow

import { LazyMedia } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { Button, Form, Item } from 'semantic-ui-react';
import { withTranslation } from 'react-i18next';

const FileUpload: ComponentType<any> = withTranslation()((props) => (
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
    </Item.Content>
  </Item>
));

export default FileUpload;
