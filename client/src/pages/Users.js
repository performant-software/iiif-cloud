// @flow

import { ItemList, LazyImage } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { withTranslation } from 'react-i18next';
import UsersService from '../services/Users';
import { useNavigate } from 'react-router-dom';

const Users: ComponentType<any> = withTranslation()(() => {
  const navigate = useNavigate();

  return (
    <ItemList
      actions={[{
        name: 'edit',
        onClick: (item) => navigate(`/users/${item.id}`)
      }, {
        name: 'delete'
      }]}
      addButton={{
        location: 'top',
        onClick: () => navigate('/users/new')
      }}
      collectionName='users'
      onLoad={(params) => UsersService.fetchAll(params)}
      onDelete={(user) => UsersService.delete(user)}
      renderHeader={(user) => user.name}
      renderImage={(user) => <LazyImage dimmable={false} src={user.avatar_thumbnail_url} />}
      renderMeta={(user) => user.email}
    />
  );
});

export default Users;
