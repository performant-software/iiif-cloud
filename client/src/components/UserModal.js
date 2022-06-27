// @flow

import { EmbeddedList, TabbedModal } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { withTranslation } from 'react-i18next';
import { Form, Message } from 'semantic-ui-react';
import UserOrganizationModal from './UserOrganizationModal';

const UserModal: ComponentType<any> = withTranslation()((props) => (
  <TabbedModal
    as={Form}
    centered={false}
    header={props.item.id
      ? props.t('UserModal.title.edit')
      : props.t('UserModal.title.add')}
    inlineTabs={false}
    open
  >
    <TabbedModal.Tab
      name={props.t('UserModal.tabs.details')}
    >
      <Form.Input
        error={props.isError('name')}
        label={props.t('UserModal.labels.name')}
        onChange={props.onTextInputChange.bind(this, 'name')}
        required={props.isRequired('name')}
        value={props.item.name}
      />
      <Form.Input
        error={props.isError('email')}
        label={props.t('UserModal.labels.email')}
        onChange={props.onTextInputChange.bind(this, 'email')}
        required={props.isRequired('email')}
        value={props.item.email}
      />
      <Form.Checkbox
        checked={props.item.admin}
        error={props.isError('admin')}
        label={props.t('UserModal.labels.admin')}
        onChange={props.onCheckboxInputChange.bind(this, 'admin')}
      />
      <Message
        content={props.t('UserModal.password.content')}
        header={props.t('UserModal.password.header')}
      />
      <Form.Input
        error={props.isError('password')}
        disabled={props.item.customer}
        label={props.t('UserModal.labels.password')}
        onChange={props.onTextInputChange.bind(this, 'password')}
        required={props.isRequired('password')}
        type='password'
        value={props.item.password || ''}
      />
      <Form.Input
        error={props.isError('password_confirmation')}
        disabled={props.item.customer}
        label={props.t('UserModal.labels.passwordConfirmation')}
        onChange={props.onTextInputChange.bind(this, 'password_confirmation')}
        required={props.isRequired('password_confirmation')}
        type='password'
        value={props.item.password_confirmation || ''}
      />
    </TabbedModal.Tab>
    <TabbedModal.Tab
      name={props.t('UserModal.tabs.organizations')}
    >
      <EmbeddedList
        actions={[{
          name: 'delete'
        }]}
        columns={[{
          name: 'name',
          label: props.t('UserModal.userOrganizations.columns.name'),
          resolve: (u) => u.organization.name,
          sortable: true
        }, {
          name: 'location',
          label: props.t('UserModal.userOrganizations.columns.location'),
          resolve: (u) => u.organization.location,
          sortable: true
        }]}
        items={props.item.user_organizations}
        modal={{
          component: UserOrganizationModal
        }}
        onDelete={props.onDeleteChildAssociation.bind(this, 'user_organizations')}
        onSave={props.onSaveChildAssociation.bind(this, 'user_organizations')}
      />
    </TabbedModal.Tab>
    { props.children }
  </TabbedModal>
));

export default UserModal;
