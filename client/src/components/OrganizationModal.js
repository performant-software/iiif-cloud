// @flow

import React, { type ComponentType } from 'react';
import { withTranslation } from 'react-i18next';
import { Form, Modal } from 'semantic-ui-react';

const OrganizationModal: ComponentType<any> = withTranslation()((props) => (
  <Modal
    as={Form}
    centered={false}
    open
  >
    <Modal.Header
      content={props.item.id
        ? props.t('OrganizationModal.title.edit')
        : props.t('OrganizationModal.title.add')}
    />
    <Modal.Content>
      <Form.Input
        error={props.isError('name')}
        label={props.t('OrganizationModal.labels.name')}
        onChange={props.onTextInputChange.bind(this, 'name')}
        required={props.isRequired('name')}
        value={props.item.name}
      />
      <Form.Input
        error={props.isError('location')}
        label={props.t('OrganizationModal.labels.location')}
        onChange={props.onTextInputChange.bind(this, 'location')}
        required={props.isRequired('location')}
        value={props.item.location}
      />
    </Modal.Content>
    { props.children }
  </Modal>
));

export default OrganizationModal;
