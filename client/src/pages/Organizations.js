// @flow

import { ListTable } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { withTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { Button } from 'semantic-ui-react';
import OrganizationsService from '../services/Organizations';
import OrganizationModal from '../components/OrganizationModal';

const Organizations: ComponentType<any> = withTranslation()((props) => (
  <ListTable
    actions={[{
      name: 'edit',
      render: (item) => (
        <Button
          as={Link}
          basic
          compact
          icon='edit'
          to={item.id.toString()}
        />
      )
    }, {
      name: 'delete'
    }]}
    addButton={{
      color: undefined,
      location: 'top'
    }}
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
    modal={{
      component: OrganizationModal,
      props: {
        onInitialize: (id) => OrganizationsService.fetchOne(id).then(({ data }) => data.organization),
        required: ['name', 'location']
      }
    }}
    onDelete={(organization) => OrganizationsService.delete(organization)}
    onLoad={(params) => OrganizationsService.fetchAll(params)}
    onSave={(organization) => OrganizationsService.save(organization)}
    perPageOptions={[10, 25, 50, 100]}
  />
));

export default Organizations;
