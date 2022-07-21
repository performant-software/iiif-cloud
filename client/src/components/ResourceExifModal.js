// @flow

import React, { useCallback, type ComponentType } from 'react';
import {
  Button,
  Grid,
  Header,
  Modal,
  Table
} from 'semantic-ui-react';
import _ from 'underscore';
import { useTranslation } from 'react-i18next';

type Props = {
  exif: any,
  onClose: () => void
};

const ResourceExifModal: ComponentType<any> = (props: Props) => {
  const { t } = useTranslation();

  /**
   * Renders the header component and table structure.
   *
   * @type {function([*,*])}
   */
  const renderHeader = useCallback(([key, value]) => (
    <>
      <Header
        content={key}
      />
      <Table
        columns={2}
        padded
        striped
      >
        <Table.Body>
          { _.map(Object.entries(value), renderItem) }
          { _.isEmpty(value) && (
            <Table.Row>
              <Table.Cell>
                No records
              </Table.Cell>
            </Table.Row>
          )}
        </Table.Body>
      </Table>
    </>
  ), []);

  /**
   * Renders the table row for the passed key/value.
   *
   * @type {function([*,*])}
   */
  const renderItem = useCallback(([key, value]) => (
    <Table.Row>
      <Table.Cell>{ key }</Table.Cell>
      <Table.Cell>{ value }</Table.Cell>
    </Table.Row>
  ), []);

  return (
    <Modal
      centered={false}
      open
    >
      <Modal.Header>
        <Grid
          columns={2}
        >
          <Grid.Column>
            <Header
              content={t('ResourceExifModal.title')}
            />
          </Grid.Column>
          <Grid.Column
            textAlign='right'
          >
            <Button
              basic
              content={t('Common.buttons.close')}
              onClick={props.onClose}
            />
          </Grid.Column>
        </Grid>
      </Modal.Header>
      <Modal.Content>
        { _.map(Object.entries(props.exif), renderHeader) }
      </Modal.Content>
      <Modal.Actions>
        <Button
          basic
          content={t('Common.buttons.close')}
          onClick={props.onClose}
        />
      </Modal.Actions>
    </Modal>
  );
};

export default ResourceExifModal;
