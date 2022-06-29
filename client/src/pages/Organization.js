// @flow

import React, { type ComponentType } from 'react';
import { withTranslation } from 'react-i18next';
import { Form } from 'semantic-ui-react';
import OrganizationsService from '../services/Organizations';
import withEditPage from '../hooks/EditPage';

const OrganizationForm = withTranslation()((props) => (
  <Form>
    <Form.Input
      error={props.isError('name')}
      label={props.t('OrganizationModal.labels.name')}
      onChange={props.onTextInputChange.bind(this, 'name')}
      required={props.isRequired('name')}
      value={props.item.name}
    />
    <Form.Input
      error={props.isError('location')}
      label={props.t('OrganizationModal.labels.location')}
      onChange={props.onTextInputChange.bind(this, 'location')}
      required={props.isRequired('location')}
      value={props.item.location}
    />
  </Form>
));

const Organization: ComponentType<any> = withEditPage(OrganizationForm, {
  id: 'organizationId',
  onInitialize: (id) => OrganizationsService.fetchOne(id).then(({ data }) => data.organization),
  onSave: (organization) => OrganizationsService.save(organization).then(({ data }) => data.organization)
});

export default Organization;
