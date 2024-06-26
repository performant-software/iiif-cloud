// @flow

import { EmbeddedList, FileInputButton, LazyImage } from '@performant-software/semantic-components';
import type { EditContainerProps } from '@performant-software/shared-components/types';
import React, { type ComponentType, useEffect } from 'react';
import { withTranslation } from 'react-i18next';
import uuid from 'react-uuid';
import { Button, Form, Message } from 'semantic-ui-react';
import _ from 'underscore';
import AuthenticationService from '../services/Authentication';
import i18n from '../i18n/i18n';
import OrganizationModal from '../components/OrganizationModal';
import SimpleEditPage from '../components/SimpleEditPage';
import type { Translateable } from '../types/Translateable';
import UsersService from '../services/Users';
import withEditPage from '../hooks/EditPage';

const UserForm = withTranslation()((props: EditContainerProps & Translateable) => {
  /**
   * Pre-populate the organization if the user is only a member of one organization.
   */
  useEffect(() => {
    if (!props.item.id) {
      const user = AuthenticationService.getCurrentUser();
      if (user.user_organizations && user.user_organizations.length === 1) {
        const { organization } = _.first(user.user_organizations);
        props.onSetState({ user_organizations: [{ organization_id: organization.id, organization }] });
      }
    }
  }, []);

  return (
    <SimpleEditPage
      {...props}
    >
      <SimpleEditPage.Tab
        key='details'
        name={props.t('Common.tabs.details')}
      >
        <Form.Input
          label={props.t('Common.labels.avatar')}
        >
          <LazyImage
            preview={props.item.avatar_preview_url}
            src={props.item.avatar_url}
            size='medium'
          >
            { !props.item.avatar_url && (
              <FileInputButton
                color='green'
                content={props.t('Common.buttons.upload')}
                icon='cloud upload'
                onSelection={(files) => {
                  const file = _.first(files);
                  const url = URL.createObjectURL(file);
                  props.onSetState({
                    avatar: file,
                    avatar_url: url,
                    avatar_preview_url: url
                  });
                }}
              />
            )}
            { props.item.avatar_url && (
              <Button
                color='red'
                content={props.t('Common.buttons.remove')}
                icon='times'
                onClick={() => props.onSetState({ avatar: null, avatar_url: null, avatar_remove: true })}
              />
            )}
          </LazyImage>
        </Form.Input>
        <Form.Input
          error={props.isError('name')}
          label={props.t('User.labels.name')}
          onChange={props.onTextInputChange.bind(this, 'name')}
          required={props.isRequired('name')}
          value={props.item.name}
        />
        <Form.Input
          error={props.isError('email')}
          label={props.t('User.labels.email')}
          onChange={props.onTextInputChange.bind(this, 'email')}
          required={props.isRequired('email')}
          value={props.item.email}
        />
        { AuthenticationService.isAdmin() && (
          <Form.Checkbox
            checked={props.item.admin}
            error={props.isError('admin')}
            label={props.t('User.labels.admin')}
            onChange={props.onCheckboxInputChange.bind(this, 'admin')}
          />
        )}
        <Form.Input
          action={{
            color: 'blue',
            icon: 'refresh',
            content: 'Refresh',
            onClick: () => props.onSetState({
              api_key: uuid()
            })
          }}
          error={props.isError('api_key')}
          label={props.t('Project.labels.apiKey')}
          onChange={props.onTextInputChange.bind(this, 'api_key')}
          required={props.isRequired('api_key')}
          value={props.item.api_key}
        />
        <Message
          content={props.t('User.password.content')}
          header={props.t('User.password.header')}
        />
        <Form.Input
          error={props.isError('password')}
          disabled={props.item.customer}
          label={props.t('User.labels.password')}
          onChange={props.onTextInputChange.bind(this, 'password')}
          required={props.isRequired('password')}
          type='password'
          value={props.item.password || ''}
        />
        <Form.Input
          error={props.isError('password_confirmation')}
          disabled={props.item.customer}
          label={props.t('User.labels.passwordConfirmation')}
          onChange={props.onTextInputChange.bind(this, 'password_confirmation')}
          required={props.isRequired('password_confirmation')}
          type='password'
          value={props.item.password_confirmation || ''}
        />
      </SimpleEditPage.Tab>
      <SimpleEditPage.Tab
        key='organizations'
        name={props.t('Common.tabs.organizations')}
      >
        <EmbeddedList
          actions={[{
            name: 'edit'
          }, {
            name: 'delete'
          }]}
          columns={[{
            name: 'name',
            label: props.t('User.organizations.columns.name'),
            resolve: (o) => o.organization.name,
            sortable: true
          }, {
            name: 'location',
            label: props.t('User.organizations.columns.location'),
            resolve: (o) => o.organization.location,
            sortable: true
          }]}
          modal={{
            component: OrganizationModal,
            props: {
              required: ['organization_id']
            }
          }}
          items={props.item.user_organizations}
          onDelete={props.onDeleteChildAssociation.bind(this, 'user_organizations')}
          onSave={props.onSaveChildAssociation.bind(this, 'user_organizations')}
        />
      </SimpleEditPage.Tab>
    </SimpleEditPage>
  );
});

const ValidateUser = (user) => {
  const errors = {};

  if (user && !user.admin && _.isEmpty(user.user_organizations)) {
    _.extend(errors, { user_organizations: i18n.t('User.errors.noOrganization') });
  }

  return errors;
};

const User: ComponentType<any> = withEditPage(UserForm, {
  id: 'userId',
  onInitialize: (id) => (
    UsersService
      .fetchOne(id)
      .then(({ data }) => data.user)
  ),
  onSave: (user) => (
    UsersService
      .save(user)
      .then(({ data }) => data.user)
  ),
  required: ['name', 'email'],
  validate: ValidateUser
});

export default User;
