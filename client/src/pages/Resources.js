// @flow

import { ItemList, FileUploadModal } from '@performant-software/semantic-components';
import React, { useCallback, type ComponentType } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import FileUpload from '../components/FileUpload';
import ResourceImage from '../components/ResourceImage';
import ResourcesService from '../services/Resources';
import { useTranslation } from 'react-i18next';

const Resources: ComponentType<any> = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { projectId } = useParams();
  const { t } = useTranslation();

  /**
   * Uploads the passed resources and navigates to the current URL to refresh the state.
   *
   * @type {function(*): Promise<R>|Promise<R|unknown>|Promise<*>|*}
   */
  const onUpload = useCallback((resources) => (
    ResourcesService
      .upload(resources)
      .then(() => navigate(location.pathname, {
        state: {
          saved: true
        }
      }))
  ), []);

  return (
    <ItemList
      actions={[{
        name: 'edit',
        label: null,
        onClick: (item) => navigate(item.id.toString())
      }, {
        name: 'delete',
        label: null
      }]}
      addButton={{
        location: 'top',
        onClick: () => navigate('new')
      }}
      buttons={[{
        render: () => (
          <FileUploadModal
            button={t('Common.buttons.upload')}
            itemComponent={FileUpload}
            onAddFile={(file) => ({
              name: file.name,
              project_id: projectId,
              content: file,
              content_url: URL.createObjectURL(file),
              content_type: file.type
            })}
            onSave={onUpload}
            required={[]}
          />
        )
      }]}
      collectionName='resources'
      onLoad={(params) => ResourcesService.fetchAll({ ...params, project_id: projectId })}
      onDelete={(resource) => ResourcesService.delete(resource)}
      perPageOptions={[10, 25, 50, 100]}
      renderHeader={(resource) => resource.name}
      renderImage={(resource) => (
        <ResourceImage
          contentType={resource.content_type}
          dimmable={false}
          preview={resource.content_thumbnail_url}
          src={resource.content_thumbnail_url}
        />
      )}
      renderMeta={() => ''}
      saved={location.state && location.state.saved}
      sort={[{
        key: 'name',
        value: 'resources.name',
        text: t('Common.sort.name')
      }, {
        key: 'created_at',
        value: 'resources.created_at',
        text: t('Common.sort.created')
      }, {
        key: 'updated_at',
        value: 'resources.updated_at',
        text: t('Common.sort.updated')
      }]}
    />
  );
};

export default Resources;
