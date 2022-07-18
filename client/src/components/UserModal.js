// @flow

import { AssociatedDropdown } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { withTranslation } from 'react-i18next';
import { Form, Modal } from 'semantic-ui-react';
import User from '../transforms/User';
import UsersService from '../services/Users';

const UserModal: ComponentType<any> = withTranslation()((props) => (
  <Modal
    as={Form}
    centered={false}
    open
  >
    <Modal.Header
      content={props.item.id
        ? props.t('UserModal.title.edit')
        : props.t('UserModal.title.add')}
    />
    <Modal.Content>
      <Form.Input
        error={props.isError('user_id')}
        label={props.t('UserModal.labels.user')}
        required={props.isRequired('user_id')}
      >
        <AssociatedDropdown
          collectionName='users'
          onSearch={(params) => UsersService.fetchAll(params)}
          onSelection={props.onAssociationInputChange.bind(this, 'user_id', 'user')}
          renderOption={(user) => User.toDropdown(user)}
          searchQuery={props.item.user && props.item.user.name}
          value={props.item.user_id}
        />
      </Form.Input>
    </Modal.Content>
    { props.children }
  </Modal>
));

export default UserModal;
