// @flow

import { FileInputButton, LazyImage } from '@performant-software/semantic-components';
import { Object as ObjectUtils } from '@performant-software/shared-components';
import React, {
  useEffect,
  useMemo,
  useState,
  type ComponentType
} from 'react';
import { withTranslation } from 'react-i18next';
import { useParams } from 'react-router-dom';
import { Button, Form, Icon } from 'semantic-ui-react';
import _ from 'underscore';
import i18n from '../i18n/i18n';
import ProjectsService from '../services/Projects';
import ResourceExifModal from '../components/ResourceExifModal';
import ResourceMetadata from '../components/ResourceMetadata';
import ResourceViewerModal from '../components/ResourceViewerModal';
import ResourcesService from '../services/Resources';
import SimpleEditPage from '../components/SimpleEditPage';
import withEditPage from '../hooks/EditPage';

const ResourceForm = withTranslation()((props) => {
  const [info, setInfo] = useState(false);
  const [project, setProject] = useState();
  const [viewer, setViewer] = useState(false);

  const { projectId } = useParams();

  /**
   * Converts the EXIF data to JSON.
   *
   * @type {*}
   */
  const exif = useMemo(() => {
    let value;

    if (props.item.exif) {
      try {
        value = JSON.parse(props.item.exif);
      } catch (e) {
        // Catch JSON parse exception
      }
    }

    return value;
  }, [props.item.exif]);

  /**
   * Creates the manifest ID based on the blob content.
   *
   * @type {string}
   */
  const manifestId = useMemo(() => (
    URL.createObjectURL(new Blob([props.item.manifest], {
      type: 'application/ld+json'
    }))
  ), [props.item.manifest]);

  /**
   * Loads the related project record.
   */
  useEffect(() => {
    ProjectsService
      .fetchOne(projectId)
      .then(({ data }) => setProject(data.project));
  }, [projectId]);

  /**
   * Sets the project ID on the state.
   */
  useEffect(() => {
    if (project) {
      props.onSetState({ project, project_id: project.id });
    }
  }, [project]);

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
                    content_preview_url: url,
                    name: file.name
                  });
                }}
              />
            )}
            { props.item.manifest && (
              <Button
                color='yellow'
                content={props.t('Common.buttons.iiif')}
                icon='file image outline'
                onClick={() => setViewer(true)}
              />
            )}
            { exif && (
              <Button
                content={props.t('Resource.buttons.exif')}
                icon='info circle'
                onClick={() => setInfo(true)}
                style={{
                  backgroundColor: '#219ebc',
                  color: '#FFFFFF'
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
        { project && (
          <ResourceMetadata
            isError={props.isError}
            items={JSON.parse(project.metadata)}
            onChange={(obj) => props.onTextInputChange('metadata', null, { value: JSON.stringify(obj) })}
            value={props.item.metadata && JSON.parse(props.item.metadata)}
          />
        )}
        { viewer && manifestId && (
          <ResourceViewerModal
            manifestId={manifestId}
            onClose={() => setViewer(false)}
          />
        )}
        { info && exif && (
          <ResourceExifModal
            exif={exif}
            onClose={() => setInfo(false)}
          />
        )}
      </SimpleEditPage.Tab>
    </SimpleEditPage>
  );
});

const ValidateResource = (resource) => {
  const errors = {};

  if (resource) {
    const { project } = resource;

    // Validate required metadata
    if (project && project.metadata) {
      const items = JSON.parse(project.metadata);
      const values = JSON.parse(resource.metadata || '{}');

      _.each(items, (item) => {
        const { name, required } = item;

        if (required && ObjectUtils.isEmpty(values[name])) {
          _.extend(errors, { [`metadata[${name}]`]: i18n.t('Resource.errors.required', { name }) });
        }
      });
    }
  }

  return errors;
};

const Resource: ComponentType<any> = withEditPage(ResourceForm, {
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
  required: ['name'],
  validate: ValidateResource
});

export default Resource;
