// @flow

import { LazyIIIF } from '@performant-software/semantic-components';
import { UserDefinedFieldsForm, UserDefinedFields } from '@performant-software/user-defined-fields';
import React, {
  useEffect,
  useMemo,
  useState,
  type ComponentType
} from 'react';
import { withTranslation } from 'react-i18next';
import { useParams } from 'react-router-dom';
import { Button, Form } from 'semantic-ui-react';
import ProjectsService from '../services/Projects';
import ReadOnlyField from '../components/ReadOnlyField';
import ResourceExifModal from '../components/ResourceExifModal';
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
            manifest={props.item.manifest_url}
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
        <ReadOnlyField
          label={props.t('Resource.labels.uuid')}
          value={props.item.uuid}
        />
        <UserDefinedFieldsForm
          data={props.item.user_defined}
          defineableId={projectId}
          defineableType='Project'
          isError={props.isError}
          onChange={(userDefined) => props.onSetState({ user_defined: userDefined })}
          onClearValidationError={props.onClearValidationError}
          tableName='Resource'
        />
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
  resolveValidationError: UserDefinedFields.resolveError.bind(this)
});

export default Resource;
