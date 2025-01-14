// @flow

import cx from 'classnames';
import { LazyIIIF, Toaster } from '@performant-software/semantic-components';
import { UserDefinedFieldsForm, UserDefinedFields } from '@performant-software/user-defined-fields';
import React, {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ComponentType
} from 'react';
import { withTranslation } from 'react-i18next';
import { useParams } from 'react-router-dom';
import {
  Button,
  Form,
  Header,
  Menu,
  Message,
  Segment
} from 'semantic-ui-react';
import AttachmentDetails from '../components/AttachmentDetails';
import AttachmentStatus from '../components/AttachmentStatus';
import AuthenticationService from '../services/Authentication';
import ProjectsService from '../services/Projects';
import ReadOnlyField from '../components/ReadOnlyField';
import ResourceExifModal from '../components/ResourceExifModal';
import ResourcesService from '../services/Resources';
import SimpleEditPage from '../components/SimpleEditPage';
import styles from './Resource.module.css';
import withEditPage from '../hooks/EditPage';

const Tabs = {
  content: 'content',
  content_converted: 'content_converted'
};

const ResourceForm = withTranslation()((props) => {
  const [converted, setConverted] = useState(false);
  const [errors, setErrors] = useState([]);
  const [info, setInfo] = useState(false);
  const [project, setProject] = useState();
  const [tab, setTab] = useState(Tabs.content);

  const { projectId } = useParams();

  /**
   * Memo-izes the current attachment info.
   *
   * @type {AttachmentInfo}
   */
  const attachment = useMemo(() => (tab === Tabs.content
    ? props.item.content_info
    : props.item.content_converted_info
  ), [tab, props.item]);

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
   * Calls the `/api/resources/:id/convert API endpoint and sets any errors on the state.
   *
   * @type {function(): Promise<*>}
   */
  const onConvert = useCallback(() => (
    ResourcesService
      .convert(props.item.id)
      .then(() => setConverted(true))
      .catch(({ response: { data } }) => setErrors(data.errors))
  ), [props.item.id]);

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
      className={styles.resource}
      errors={[...props.errors, ...errors]}
    >
      <SimpleEditPage.Tab
        key='details'
        name={props.t('Common.tabs.details')}
      >
        <ReadOnlyField
          label={props.t('Resource.labels.uuid')}
          value={props.item.uuid}
        />
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
        <Header
          content={props.t('Resource.labels.attachments')}
        />
        <Segment
          padded
        >
          <Menu
            className={cx(styles.ui, styles.menu)}
            pointing
            secondary
          >
            <Menu.Item
              name={Tabs.content}
              active={tab === Tabs.content}
              onClick={() => setTab(Tabs.content)}
            >
              { props.t('Resource.labels.sourceImage') }
              <AttachmentStatus
                className={cx(styles.icon, styles.attachmentStatus)}
                value={!!props.item.content_info}
              />
            </Menu.Item>
            <Menu.Item
              name={Tabs.content_converted}
              active={tab === Tabs.content_converted}
              onClick={() => setTab(Tabs.content_converted)}
            >
              { props.t('Resource.labels.convertedImage') }
              <AttachmentStatus
                className={cx(styles.icon, styles.attachmentStatus)}
                value={!!props.item.content_converted_info}
              />
            </Menu.Item>
            { AuthenticationService.isAdmin() && (
              <Menu.Menu
                position='right'
              >
                <Menu.Item
                  as={Button}
                >
                  <Button
                    content={props.t('Resource.buttons.convert')}
                    icon='exchange'
                    onClick={onConvert}
                  />
                </Menu.Item>
              </Menu.Menu>
            )}
          </Menu>
          <AttachmentDetails
            attachment={attachment}
          />
          { converted && (
            <Toaster
              onDismiss={() => setConverted(false)}
              type={Toaster.MessageTypes.info}
            >
              <Message.Header
                content={props.t('Resource.messages.convert.header')}
              />
              <Message.Content
                content={props.t('Resource.messages.convert.content')}
              />
            </Toaster>
          )}
        </Segment>
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
