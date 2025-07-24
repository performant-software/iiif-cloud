// @flow

import { EmbeddedList } from '@performant-software/semantic-components';
import type { EditContainerProps } from '@performant-software/shared-components/types';
import React, { type ComponentType } from 'react';
import { useTranslation } from 'react-i18next';
import { Form } from 'semantic-ui-react';
import AdminPage from '../components/AdminPage';
import type { Organization as OrganizationType } from '../types/Organization';
import OrganizationsService from '../services/Organizations';
import SimpleEditPage from '../components/SimpleEditPage';
import UserModal from '../components/UserModal';
import withEditPage from '../hooks/EditPage';

type Props = EditContainerProps & {
  item: OrganizationType
}

const OrganizationForm = (props: Props) => {
  const { t } = useTranslation();

  return (
    <AdminPage>
      <SimpleEditPage
        {...props}
      >
        <SimpleEditPage.Tab
          key='details'
          name={t('Common.tabs.details')}
        >
          <Form.Input
            error={props.isError('name')}
            label={t('Organization.labels.name')}
            onChange={props.onTextInputChange.bind(this, 'name')}
            required={props.isRequired('name')}
            value={props.item.name || ''}
          />
          <Form.Input
            error={props.isError('location')}
            label={t('Organization.labels.location')}
            onChange={props.onTextInputChange.bind(this, 'location')}
            required={props.isRequired('location')}
            value={props.item.location || ''}
          />
        </SimpleEditPage.Tab>
        <SimpleEditPage.Tab
          key='users'
          name={t('Common.tabs.users')}
        >
          <EmbeddedList
            actions={[{
              name: 'edit'
            }, {
              name: 'delete'
            }]}
            columns={[{
              name: 'name',
              label: t('Organization.users.columns.name'),
              resolve: (u) => u.user.name,
              sortable: true
            }, {
              name: 'email',
              label: t('Organization.users.columns.email'),
              resolve: (u) => u.user.email,
              sortable: true
            }]}
            modal={{
              component: UserModal,
              props: {
                required: ['user_id']
              }
            }}
            items={props.item.user_organizations}
            onDelete={props.onDeleteChildAssociation.bind(this, 'user_organizations')}
            onSave={props.onSaveChildAssociation.bind(this, 'user_organizations')}
          />
        </SimpleEditPage.Tab>
      </SimpleEditPage>
    </AdminPage>
  );
};

const Organization: ComponentType<any> = withEditPage(OrganizationForm, {
  id: 'organizationId',
  onInitialize: (id) => (
    OrganizationsService
      .fetchOne(id)
      .then(({ data }) => data.organization)
  ),
  onSave: (organization) => (
    OrganizationsService
      .save(organization)
      .then(({ data }) => data.organization)
  ),
  required: ['name', 'location']
});

export default Organization;
