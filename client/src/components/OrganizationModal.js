// @flow

import { AssociatedDropdown } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { withTranslation } from 'react-i18next';
import { Form, Modal } from 'semantic-ui-react';
import Organization from '../transforms/Organization';
import OrganizationsService from '../services/Organizations';

const OrganizationModal: ComponentType<any> = withTranslation()((props) => (
  <Modal
    as={Form}
    centered={false}
    open
  >
    <Modal.Header
      content={props.item.id
        ? props.t('OrganizationModal.title.edit')
        : props.t('OrganizationModal.title.add')}
    />
    <Modal.Content>
      <Form.Input
        error={props.isError('organization_id')}
        label={props.t('OrganizationModal.labels.organization')}
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
    </Modal.Content>
    { props.children }
  </Modal>
));

export default OrganizationModal;
