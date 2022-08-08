// @flow

import { ItemList, LazyImage } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import ProjectsService from '../services/Projects';

const Projects: ComponentType<any> = () => {
  const navigate = useNavigate();
  const { t } = useTranslation();

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
      renderImage={(project) => (
        <LazyImage
          dimmable={false}
          src={project.avatar_thumbnail_url}
        />
      )}
      renderMeta={(project) => project.organization && project.organization.name}
      sort={[{
        key: 'name',
        value: 'projects.name',
        text: t('Projects.sort.name')
      }, {
        key: 'created_at',
        value: 'projects.created_at',
        text: t('Projects.sort.created')
      }, {
        key: 'updated_at',
        value: 'projects.updated_at',
        text: t('Projects.sort.updated')
      }]}
    />
  );
};

export default Projects;
