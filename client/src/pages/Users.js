// @flow

import React from 'react';
import type { ComponentType } from 'react';
import { withTranslation } from 'react-i18next';
import { BooleanIcon, ListTable } from '@performant-software/semantic-components';
import UserModal from '../components/UserModal';
import UsersService from '../services/Users';

const Users: ComponentType<any> = withTranslation()((props) => (
  <ListTable
    actions={[{
      name: 'edit'
    }, {
      name: 'delete'
    }]}
    addButton={{
      color: undefined,
      location: 'top'
    }}
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
    modal={{
      component: UserModal,
      props: {
        onInitialize: (id) => UsersService.fetchOne(id).then(({ data }) => data.user),
        required: ['name', 'email']
      }
    }}
    onDelete={(user) => UsersService.delete(user)}
    onLoad={(params) => UsersService.fetchAll(params)}
    onSave={(user) => UsersService.save(user)}
    perPageOptions={[10, 25, 50, 100]}
  />
));

export default Users;
