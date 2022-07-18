// @flow

import { BooleanIcon } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { withTranslation } from 'react-i18next';
import ItemList from '../components/ItemList';
import UsersService from '../services/Users';

const Users: ComponentType<any> = withTranslation()((props) => (
  <ItemList
    collectionName='users'
    columns={[{
      name: 'name',
      label: props.t('Users.columns.name'),
      sortable: true
    }, {
      name: 'email',
      label: props.t('Users.columns.email'),
      sortable: true
    }, {
      name: 'admin',
      label: props.t('Users.columns.admin'),
      render: (user) => <BooleanIcon value={user.admin} />,
      sortable: true
    }]}
    onDelete={(user) => UsersService.delete(user)}
    onLoad={(params) => UsersService.fetchAll({ ...params, organization_id: props.organizationId })}
  />
));

export default Users;
