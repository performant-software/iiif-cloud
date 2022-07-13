// @flow

import { DownloadButton, FileInputButton, LazyImage } from '@performant-software/semantic-components';
import React, { type ComponentType, useEffect } from 'react';
import { withTranslation } from 'react-i18next';
import { Link, useParams } from 'react-router-dom';
import { Button, Form, Icon } from 'semantic-ui-react';
import _ from 'underscore';
import ResourcesService from '../services/Resources';
import withEditPage from '../hooks/EditPage';
import SimpleEditPage from '../components/SimpleEditPage';

const ProjectForm = withTranslation()((props) => {
  const { projectId } = useParams();

  useEffect(() => {
    props.onSetState({ project_id: projectId });
  }, [projectId]);

  return (
    <SimpleEditPage
      {...props}
    >
      <SimpleEditPage.Tab
        key='details'
        name={props.t('Common.tabs.details')}
      >
        <Form.Input
          label={props.t('Resource.labels.content')}
        >
          <LazyImage
            preview={props.item.content_preview_url}
            src={props.item.content_url}
            size='medium'
          >
            { !props.item.content_url && (
              <FileInputButton
                color='orange'
                content={props.t('Common.buttons.upload')}
                icon='cloud upload'
                onSelection={(files) => {
                  const file = _.first(files);
                  const url = URL.createObjectURL(file);
                  props.onSetState({
                    content: file,
                    content_url: url,
                    content_preview_url: url
                  });
                }}
              />
            )}
            { props.item.content_download_url && (
              <a
                className='ui button green'
                download={props.item.name}
                href={props.item.content_download_url}
              >
                <Icon
                  name='cloud download'
                />
                { props.t('Common.buttons.download') }
              </a>
            )}
            { props.item.content_url && (
              <Button
                color='red'
                content={props.t('Common.buttons.remove')}
                icon='times'
                onClick={() => props.onSetState({ content: null, content_url: null, content_remove: true })}
              />
            )}
          </LazyImage>
        </Form.Input>
        <Form.Input
          error={props.isError('name')}
          label={props.t('Project.labels.name')}
          onChange={props.onTextInputChange.bind(this, 'name')}
          required={props.isRequired('name')}
          value={props.item.name}
        />
      </SimpleEditPage.Tab>
    </SimpleEditPage>
  );
});

const Resource: ComponentType<any> = withEditPage(ProjectForm, {
  id: 'resourceId',
  onInitialize: (
    (id) => ResourcesService
      .fetchOne(id)
      .then(({ data }) => data.resource)
  ),
  onSave: (
    (resource) => ResourcesService
      .save(resource)
      .then(({ data }) => data.resource)
  ),
  required: ['name']
});

export default Resource;
