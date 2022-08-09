// @flow

import { LazyIIIF } from '@performant-software/semantic-components';
import { IIIF as IIIFUtils, Object as ObjectUtils } from '@performant-software/shared-components';
import React, {
  useEffect,
  useMemo,
  useState,
  type ComponentType
} from 'react';
import { withTranslation } from 'react-i18next';
import { useParams } from 'react-router-dom';
import { Button, Form } from 'semantic-ui-react';
import _ from 'underscore';
import i18n from '../i18n/i18n';
import ProjectsService from '../services/Projects';
import ResourceExifModal from '../components/ResourceExifModal';
import ResourceMetadata from '../components/ResourceMetadata';
import ResourcesService from '../services/Resources';
import SimpleEditPage from '../components/SimpleEditPage';
import withEditPage from '../hooks/EditPage';

const ResourceForm = withTranslation()((props) => {
  const [info, setInfo] = useState(false);
  const [project, setProject] = useState();

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
  const manifest = useMemo(() => IIIFUtils.createManifestURL(props.item.manifest), [props.item.manifest]);

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
          <LazyIIIF
            contentType={props.item.content_type}
            downloadUrl={props.item.content_download_url}
            manifest={manifest}
            onUpload={(file) => props.onSetState({
              name: file.name,
              content: file
            })}
            preview={props.item.content_preview_url}
            src={props.item.content_url}
          >
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
          </LazyIIIF>
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
