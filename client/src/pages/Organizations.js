// @flow

import React, { type Node } from 'react';
import { withTranslation } from 'react-i18next';
import ItemList from '../components/ItemList';
import OrganizationsService from '../services/Organizations';
import withParams from '../hooks/Params';

const Organizations = (withTranslation()(withParams((props) => (
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
    onLoad={(params) => OrganizationsService.fetchAll({ ...params, user_id: props.userId })}
    onSave={(organization) => OrganizationsService.save(organization)}
  />
))): Node);

export default Organizations;
