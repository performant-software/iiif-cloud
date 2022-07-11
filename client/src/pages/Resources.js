// @flow

import { ItemList, LazyImage } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import ResourcesService from '../services/Resources';

const Resources: ComponentType<any> = () => {
  const navigate = useNavigate();
  const { projectId } = useParams();

  return (
    <ItemList
      actions={[{
        name: 'edit',
        onClick: (item) => navigate(item.id.toString())
      }, {
        name: 'delete'
      }]}
      addButton={{
        location: 'top',
        onClick: () => navigate('new')
      }}
      collectionName='resources'
      onLoad={(params) => ResourcesService.fetchAll({ ...params, project_id: projectId })}
      onDelete={(resource) => ResourcesService.delete(resource)}
      renderHeader={(resource) => resource.name}
      renderImage={(resource) => <LazyImage src={resource.content_url} />}
      renderMeta={() => ''}
    />
  );
};

export default Resources;
