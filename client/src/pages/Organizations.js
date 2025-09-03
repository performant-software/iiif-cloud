// @flow

import React, { type ComponentType } from 'react';
import { useTranslation } from 'react-i18next';
import AdminPage from '../components/AdminPage';
import OrganizationsService from '../services/Organizations';
import SimpleList from '../components/SimpleList';

const Organizations: ComponentType<any> = () => {
  const { t } = useTranslation();

  return (
    <AdminPage>
      <SimpleList
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
        onDelete={(organization) => OrganizationsService.delete(organization)}
        onLoad={(params) => OrganizationsService.fetchAll(params)}
        onSave={(organization) => OrganizationsService.save(organization)}
      />
    </AdminPage>
  );
};

export default Organizations;
