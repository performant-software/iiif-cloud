// @flow

import { FileUploadModal, ItemList, LazyMedia } from '@performant-software/semantic-components';
import React, { type ComponentType, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import FileUpload from '../components/FileUpload';
import ResourcesService from '../services/Resources';

const Resources: ComponentType<any> = () => {
  const [modal, setModal] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();
  const { projectId } = useParams();

  const { t } = useTranslation();

  return (
    <>
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
          content: t('Common.buttons.upload'),
          icon: 'cloud upload',
          primary: true,
          onClick: () => setModal(true)
        }]}
        collectionName='resources'
        onLoad={(params) => ResourcesService.fetchAll({ ...params, project_id: projectId })}
        onDelete={(resource) => ResourcesService.delete(resource)}
        perPageOptions={[10, 25, 50, 100]}
        renderHeader={(resource) => resource.name}
        renderImage={(resource) => (
          <LazyMedia
            contentType={resource.content_type}
            dimmable={false}
            preview={resource.content_thumbnail_url}
          />
        )}
        renderMeta={(resource) => resource.uuid}
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
      { modal && (
        <FileUploadModal
          closeOnComplete={false}
          itemComponent={FileUpload}
          onAddFile={(file) => ({
            name: file.name,
            project_id: projectId,
            content: file,
            content_url: URL.createObjectURL(file),
            content_type: file.type
          })}
          onSave={(item) => ResourcesService.save(item)}
          required={{
            name: t('FileUpload.labels.name')
          }}
          onClose={() => {
            setModal(false);
            navigate(location.pathname, { state: { saved: true } });
          }}
          showPageLoader={false}
          strategy='single'
        />
      )}
    </>
  );
};

export default Resources;
