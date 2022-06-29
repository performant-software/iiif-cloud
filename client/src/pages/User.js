// @flow

import type { EditContainerProps } from '@performant-software/shared-components/types';
import React, { type ComponentType, useEffect } from 'react';
import withEditPage from '../hooks/EditPage';
import { Form, Message } from 'semantic-ui-react';
import UsersService from '../services/Users';
import type { Translateable } from '../types/Translateable';
import { withTranslation } from 'react-i18next';
import { useParams } from 'react-router-dom';

const UserForm = withTranslation()((props: EditContainerProps & Translateable) => {
  const { organizationId } = useParams();

  /**
   * If we're adding a new user from the organization context, automatically
   * add a user_organizations records.
   */
  useEffect(() => {
    if (!props.item.id) {
      props.onSetState({
        user_organizations: [{
          organization_id: organizationId
        }]
      });
    }
  }, [organizationId]);

  return (
    <Form>
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
    </Form>
  );
});

const User: ComponentType<any> = withEditPage(UserForm, {
  id: 'userId',
  onInitialize: (id) => UsersService.fetchOne(id).then(({ data }) => data.user),
  onSave: (user) => UsersService.save(user).then(({ data }) => data.user),
  required: ['name', 'email']
});

export default User;
