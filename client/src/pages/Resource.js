// @flow

import cx from 'classnames';
import { LazyIIIF, Toaster } from '@performant-software/semantic-components';
import type { EditContainerProps } from '@performant-software/shared-components/types';
import { UserDefinedFieldsForm, UserDefinedFields } from '@performant-software/user-defined-fields';
import React, {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ComponentType
} from 'react';
import { useTranslation } from 'react-i18next';
import { useParams } from 'react-router';
import {
  Button,
  Form,
  Header,
  Menu,
  Message,
  Segment
} from 'semantic-ui-react';
import AttachmentDetails from '../components/AttachmentDetails';
import AuthenticationService from '../services/Authentication';
import ProjectsService from '../services/Projects';
import ReadOnlyField from '../components/ReadOnlyField';
import type { Resource as ResourceType } from '../types/Resource';
import ResourceExifModal from '../components/ResourceExifModal';
import ResourcesService from '../services/Resources';
import SimpleEditPage from '../components/SimpleEditPage';
import StatusIcon from '../components/StatusIcon';
import styles from './Resource.module.css';
import withEditPage from '../hooks/EditPage';

type Props = EditContainerProps & {
  item: ResourceType
}

const Tabs = {
  content: 'content',
  content_converted: 'content_converted'
};

const ResourceForm = (props: Props) => {
  const [cacheCleared, setCacheCleared] = useState(false);
  const [converted, setConverted] = useState(false);
  const [errors, setErrors] = useState([]);
  const [info, setInfo] = useState(false);
  const [manifestRebuilt, setManifestRebuilt] = useState(false);
  const [project, setProject] = useState();
  const [tab, setTab] = useState(Tabs.content);

  const { projectId } = useParams();
  const { t } = useTranslation();

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
      } catch {
        // Catch JSON parse exception
      }
    }

    return value;
  }, [props.item.exif]);

  /**
   * Calls the `/api/resources/:id/clear_cache API endpoint and sets any errors on the state.
   *
   * @type {function(): Promise<*>}
   */
  const onClearCache = useCallback(() => (
    ResourcesService
      .clearCache(props.item.id, tab)
      .then(() => setCacheCleared(true))
      .catch(({ response: { data } }) => setErrors(data.errors))
  ), [tab, props.item.id]);

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
   * Calls the `/api/resources/:id/create_manifest API endpoint and sets any errors on the state.
   *
   * @type {function(): Promise<*>}
   */
  const onCreateManifest = useCallback(() => (
    ResourcesService
      .createManifest(props.item.id)
      .then(() => setManifestRebuilt(true))
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
        name={t('Common.tabs.details')}
      >
        <ReadOnlyField
          label={t('Resource.labels.uuid')}
          value={props.item.uuid}
        />
        <Form.Input
          label={t('Resource.labels.content')}
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
                content={t('Resource.buttons.exif')}
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
          label={t('Resource.labels.name')}
          onChange={props.onTextInputChange.bind(this, 'name')}
          required={props.isRequired('name')}
          value={props.item.name || ''}
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
        <Form.Field>
          <Button
            basic
            content={t('Resource.buttons.rebuildManifest')}
            icon='refresh'
            onClick={onCreateManifest}
            type='button'
          />
          { props.item.manifest && (
            <Button
              as='a'
              basic
              content={t('Resource.buttons.viewManifest')}
              href={props.item.manifest_url}
              icon='file code outline'
              rel='noopener noreferrer'
              target='_blank'
              type='button'
            />
          )}
        </Form.Field>
        { manifestRebuilt && (
          <Toaster
            onDismiss={() => setManifestRebuilt(false)}
            type={Toaster.MessageTypes.info}
          >
            <Message.Header
              content={t('Resource.messages.manifest.header')}
            />
            <Message.Content
              content={t('Resource.messages.manifest.content')}
            />
          </Toaster>
        )}
        { info && exif && (
          <ResourceExifModal
            exif={exif}
            onClose={() => setInfo(false)}
          />
        )}
        <Header
          content={t('Resource.labels.attachments')}
        />
        <Segment
          padded
          secondary
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
              { t('Resource.labels.sourceImage') }
              <StatusIcon
                className={cx(styles.icon, styles.attachmentStatus)}
                status={props.item.content_info ? 'positive' : 'negative'}
              />
            </Menu.Item>
            <Menu.Item
              name={Tabs.content_converted}
              active={tab === Tabs.content_converted}
              onClick={() => setTab(Tabs.content_converted)}
            >
              { t('Resource.labels.convertedImage') }
              <StatusIcon
                className={cx(styles.icon, styles.attachmentStatus)}
                status={props.item.content_converted_info ? 'positive' : 'negative'}
              />
            </Menu.Item>
            { AuthenticationService.isAdmin() && (
              <Menu.Menu
                position='right'
              >
                <Menu.Item
                  as={Button}
                  content={t('Resource.buttons.convert')}
                  icon='exchange'
                  onClick={onConvert}
                />
              </Menu.Menu>
            )}
          </Menu>
          <AttachmentDetails
            attachment={attachment}
          />
          { AuthenticationService.isAdmin() && attachment && (
            <div
              className={styles.actions}
            >
              <Button
                color='red'
                content={t('Resource.buttons.clearCache')}
                icon='trash'
                onClick={onClearCache}
              />
            </div>
          )}
          { converted && (
            <Toaster
              onDismiss={() => setConverted(false)}
              type={Toaster.MessageTypes.info}
            >
              <Message.Header
                content={t('Resource.messages.convert.header')}
              />
              <Message.Content
                content={t('Resource.messages.convert.content')}
              />
            </Toaster>
          )}
          { cacheCleared && (
            <Toaster
              onDismiss={() => setCacheCleared(false)}
              type={Toaster.MessageTypes.positive}
            >
              <Message.Header
                content={t('Resource.messages.cache.header')}
              />
              <Message.Content
                content={t('Resource.messages.cache.content', { tab })}
              />
            </Toaster>
          )}
        </Segment>
      </SimpleEditPage.Tab>
    </SimpleEditPage>
  );
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
  resolveValidationError: UserDefinedFields.resolveError.bind(this)
});

export default Resource;
