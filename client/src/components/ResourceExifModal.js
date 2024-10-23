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
   * Renders the passed value as formatted JSON.
   *
   * @type {unknown}
   */
  const renderJson = useCallback((value) => (
    <pre>
      { JSON.stringify(value, undefined, 2) }
    </pre>
  ), []);

  /**
   * Renders the table row for the passed key/value.
   *
   * @type {function([*,*])}
   */
  const renderItem = useCallback(([key, value]) => {
    let content = value;

    if (_.isObject(value)) {
      content = renderJson(value);
    }

    return (
      <Table.Row>
        <Table.Cell>{ key }</Table.Cell>
        <Table.Cell>{ content }</Table.Cell>
      </Table.Row>
    );
  }, [renderJson]);

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
      <Modal.Content
        scrolling
      >
        <Table
          columns={2}
          padded
          striped
        >
          <Table.Body>
            { _.map(Object.entries(props.exif), renderItem) }
          </Table.Body>
        </Table>
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
