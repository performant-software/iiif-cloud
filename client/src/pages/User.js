// @flow

import { EmbeddedList } from '@performant-software/semantic-components';
import type { EditContainerProps } from '@performant-software/shared-components/types';
import React, { type ComponentType, useContext, useEffect } from 'react';
import { withTranslation } from 'react-i18next';
import { v4 as uuid } from 'uuid';
import { Form } from 'semantic-ui-react';
import _ from 'underscore';
import i18n from '../i18n/i18n';
import SimpleEditPage from '../components/SimpleEditPage';
import type { Translateable } from '../types/Translateable';
import UsersService from '../services/Users';
import withEditPage from '../hooks/EditPage';
import { AuthenticationContext } from '../contexts/AuthenticationContext';

const UserForm = withTranslation()((props: EditContainerProps & Translateable) => {
  const { user } = useContext(AuthenticationContext);

  /**
   * Pre-populate the organization if the user is only a member of one organization.
   */
  useEffect(() => {
    if (!props.item.id) {
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
          label={props.t('User.labels.name')}
          disabled
          value={props.item.name || ''}
        />
        <Form.Input
          label={props.t('User.labels.email')}
          disabled
          value={props.item.email || ''}
        />
        { user.admin && (
          <Form.Checkbox
            checked={props.item.admin}
            disabled
            label={props.t('User.labels.admin')}
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
          value={props.item.api_key || ''}
        />
      </SimpleEditPage.Tab>
      <SimpleEditPage.Tab
        key='organizations'
        name={props.t('Common.tabs.organizations')}
      >
        <EmbeddedList
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
          items={props.item.user_organizations}
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
