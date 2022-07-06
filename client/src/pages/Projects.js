// @flow

import { ItemList, LazyImage } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { useNavigate } from 'react-router-dom';
import ProjectsService from '../services/Projects';

const Projects: ComponentType<any> = () => {
  const navigate = useNavigate();

  return (
    <ItemList
      actions={[{
        name: 'edit',
        onClick: (item) => navigate(`/projects/${item.id}`)
      }, {
        name: 'delete'
      }]}
      addButton={{
        location: 'top',
        onClick: () => navigate('/projects/new')
      }}
      collectionName='projects'
      onLoad={(params) => ProjectsService.fetchAll(params)}
      onDelete={(project) => ProjectsService.delete(project)}
      renderDescription={(project) => project.description}
      renderHeader={(project) => project.name}
      renderImage={(project) => <LazyImage src={project.avatar_url} />}
      renderMeta={(project) => project.organization && project.organization.name}
    />
  );
};

export default Projects;
