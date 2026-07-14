// @flow

import React, { type ComponentType } from 'react';
import { useTranslation } from 'react-i18next';
import AdminPage from '../components/AdminPage';
import OrganizationsService from '../services/Organizations';
import { ListTable } from '@performant-software/semantic-components';
import { Button } from 'semantic-ui-react';
import { Link } from 'react-router';

const Organizations: ComponentType<any> = () => {
  const { t } = useTranslation();

  return (
    <AdminPage>
      <ListTable
        actions={[{
          name: 'edit',
          render: (item) => (
            <Button
              as={Link}
              basic
              compact
              icon='edit'
              key={item.id}
              to={item.id.toString()}
            />
          )
        }]}
        collectionName='organizations'
        columns={[{
          name: 'name',
          label: t('Organizations.columns.name'),
          sortable: true
        }, {
          name: 'location',
          label: t('Organizations.columns.location'),
          sortable: true
        }]}
        perPageOptions={[10, 25, 50, 100]}
        onLoad={(params) => OrganizationsService.fetchAll(params)}
        onSave={(organization) => OrganizationsService.save(organization)}
      />
    </AdminPage>
  );
};

export default Organizations;
