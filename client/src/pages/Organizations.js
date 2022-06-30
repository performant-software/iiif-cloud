// @flow

import React, { type ComponentType } from 'react';
import { withTranslation } from 'react-i18next';
import ItemList from '../components/ItemList';
import OrganizationsService from '../services/Organizations';

const Organizations: ComponentType<any> = withTranslation()((props) => (
  <ItemList
    collectionName='organizations'
    columns={[{
      name: 'name',
      label: props.t('Organizations.columns.name'),
      sortable: true
    }, {
      name: 'location',
      label: props.t('Organizations.columns.location'),
      sortable: true
    }]}
    onDelete={(organization) => OrganizationsService.delete(organization)}
    onLoad={(params) => OrganizationsService.fetchAll(params)}
    onSave={(organization) => OrganizationsService.save(organization)}
  />
));

export default Organizations;
