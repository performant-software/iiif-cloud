// @flow

import { AssociatedDropdown, FileInputButton, LazyImage } from '@performant-software/semantic-components';
import { UserDefinedFieldsEmbeddedList } from '@performant-software/user-defined-fields';
import React, { type ComponentType, useEffect } from 'react';
import { withTranslation } from 'react-i18next';
import { Button, Form } from 'semantic-ui-react';
import _ from 'underscore';
import AuthenticationService from '../services/Authentication';
import Organization from '../transforms/Organization';
import OrganizationsService from '../services/Organizations';
import ProjectsService from '../services/Projects';
import SimpleEditPage from '../components/SimpleEditPage';
import withEditPage from '../hooks/EditPage';

const ProjectForm = withTranslation()((props) => {
  /**
   * Pre-populate the organization dropdown if the user is only a member of one organization.
   */
  useEffect(() => {
    if (!props.item.id) {
      const user = AuthenticationService.getCurrentUser();
      if (user.user_organizations && user.user_organizations.length === 1) {
        const { organization } = _.first(user.user_organizations);
        props.onSetState({ organization_id: organization.id, organization });
      }
    }
  }, []);

  return (
    <SimpleEditPage
      {...props}
    >
      <SimpleEditPage.Tab
        key='details'
        name={props.t('Common.tabs.details')}
      >
        <Form.Input
          label={props.t('Common.labels.avatar')}
        >
          <LazyImage
            preview={props.item.avatar_preview_url}
            src={props.item.avatar_url}
            size='medium'
          >
            { !props.item.avatar_url && (
              <FileInputButton
                color='green'
                content={props.t('Common.buttons.upload')}
                icon='cloud upload'
                onSelection={(files) => {
                  const file = _.first(files);
                  const url = URL.createObjectURL(file);
                  props.onSetState({
                    avatar: file,
                    avatar_url: url,
                    avatar_preview_url: url
                  });
                }}
              />
            )}
            { props.item.avatar_url && (
              <Button
                color='red'
                content={props.t('Common.buttons.remove')}
                icon='times'
                onClick={() => props.onSetState({ avatar: null, avatar_url: null, avatar_remove: true })}
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
        <Form.Input
          error={props.isError('organization_id')}
          label={props.t('Project.labels.organization')}
          required={props.isRequired('organization_id')}
        >
          <AssociatedDropdown
            collectionName='organizations'
            onSearch={(search) => OrganizationsService.fetchAll({ search, sort_by: 'name' })}
            onSelection={props.onAssociationInputChange.bind(this, 'organization_id', 'organization')}
            renderOption={(organization) => Organization.toDropdown(organization)}
            searchQuery={props.item.organization && props.item.organization.name}
            value={props.item.organization_id}
          />
        </Form.Input>
        <Form.TextArea
          error={props.isError('description')}
          label={props.t('Project.labels.description')}
          onChange={props.onTextInputChange.bind(this, 'description')}
          required={props.isRequired('description')}
          value={props.item.description}
        />
        <div
          className='field'
        >
          <label
            htmlFor='uuid-element'
          >
            { props.t('Project.labels.uuid') }
          </label>
          <div
            id='uuid-element'
            className='ui input'
            role='textbox'
          >
            { props.item.uuid }
          </div>
        </div>
      </SimpleEditPage.Tab>
      <SimpleEditPage.Tab
        key='fields'
        name={props.t('Project.tabs.fields')}
      >
        <UserDefinedFieldsEmbeddedList
          items={props.item.user_defined_fields}
          onDelete={props.onDeleteChildAssociation.bind(this, 'user_defined_fields')}
          onSave={props.onSaveChildAssociation.bind(this, 'user_defined_fields')}
        />
      </SimpleEditPage.Tab>
    </SimpleEditPage>
  );
});

const Project: ComponentType<any> = withEditPage(ProjectForm, {
  id: 'projectId',
  onInitialize: (
    (id) => ProjectsService
      .fetchOne(id)
      .then(({ data }) => data.project)
  ),
  onSave: (
    (project) => ProjectsService
      .save(project)
      .then(({ data }) => data.project)
  ),
  required: ['name', 'description', 'organization_id']
});

export default Project;
