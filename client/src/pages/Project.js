// @flow

import { AssociatedDropdown } from '@performant-software/semantic-components';
import React, { type ComponentType, useEffect } from 'react';
import { withTranslation } from 'react-i18next';
import uuid from 'react-uuid';
import { Form } from 'semantic-ui-react';
import Organization from '../transforms/Organization';
import OrganizationsService from '../services/Organizations';
import ProjectsService from '../services/Projects';
import SimpleEditPage from '../components/SimpleEditPage';
import withEditPage from '../hooks/EditPage';
import AuthenticationService from '../services/Authentication';
import _ from 'underscore';

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
            onSearch={(params) => OrganizationsService.fetchAll(params)}
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
        <Form.Input
          action={{
            color: 'blue',
            icon: 'refresh',
            content: 'Refresh',
            onClick: () => props.onSetState({
              api_key: uuid()
            })
          }}
          error={props.isError('api_key')}
          label={props.t('Project.labels.apiKey')}
          onChange={props.onTextInputChange.bind(this, 'api_key')}
          required={props.isRequired('api_key')}
          value={props.item.api_key}
        />
      </SimpleEditPage.Tab>
    </SimpleEditPage>
  );
});

const Project: ComponentType<any> = withEditPage(ProjectForm, {
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
