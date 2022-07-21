// @flow

import React, { useCallback, type ComponentType } from 'react';
import { useTranslation } from 'react-i18next';
import { Button, Form, List } from 'semantic-ui-react';
import _ from 'underscore';
import Metadata from '../constants/Metadata';
import MetadataOptions from './MetadataOptions';

const MetadataList: ComponentType<any> = (props) => {
  const { t } = useTranslation();

  /**
   * Adds a new item to the list.
   *
   * @type {(function(): void)|*}
   */
  const onAddItem = useCallback(() => {
    props.onChange([...props.items, {}]);
  }, [props.items]);

  /**
   * Removes the item at the passed index from the list.
   *
   * @type {(function(*): void)|*}
   */
  const onRemoveItem = useCallback((findIndex) => {
    props.onChange(_.reject(props.items, (item, index) => index === findIndex));
  }, [props.items]);

  /**
   * Updates the passed attribute of the item at the passed index.
   *
   * @type {(function(number, string, ?Event, {value: *}): void)|*}
   */
  const onUpdateItem = useCallback((findIndex: number, attribute: string, e: ?Event, { value }) => {
    props.onChange(_.map(props.items, (item, index) => (
      index !== findIndex ? item : ({ ...item, [attribute]: value })
    )));
  }, [props.items]);

  return (
    <Form>
      <Button
        basic
        content={t('Common.buttons.add')}
        icon='plus'
        onClick={onAddItem.bind(this)}
        type='button'
      />
      <List
        divided
        relaxed='very'
      >
        { _.map(props.items, (item, index) => (
          <List.Item>
            <Form.Group
              style={{
                alignItems: 'center'
              }}
            >
              <Form.Input
                error={props.isError(`metadata[${index}][name]`)}
                onChange={onUpdateItem.bind(this, index, 'name')}
                placeholder={t('MetadataList.labels.name')}
                value={item.name}
                width={7}
              />
              <Form.Dropdown
                clearable
                error={props.isError(`metadata[${index}][type]`)}
                onChange={onUpdateItem.bind(this, index, 'type')}
                options={Metadata.getOptions()}
                placeholder={t('MetadataList.labels.type')}
                value={item.type}
                selectOnBlur={false}
                selection
                width={6}
              />
              <Form.Checkbox
                checked={item.required}
                label={t('MetadataList.labels.required')}
                onChange={(e, { checked }) => onUpdateItem(index, 'required', e, { value: checked })}
                width={2}
              />
              <Form.Button
                color='red'
                icon='trash'
                onClick={onRemoveItem.bind(this, index)}
                type='button'
                width={1}
              />
            </Form.Group>
            { item.type === 'dropdown' && (
              <Form.Group
                style={{
                  alignItems: 'center'
                }}
              >
                <Form.Checkbox
                  checked={item.multiple}
                  label={t('MetadataList.labels.multiple')}
                  onChange={(e, { checked }) => onUpdateItem(index, 'multiple', e, { value: checked })}
                />
                <Form.Field>
                  <MetadataOptions
                    options={item.options}
                    onChange={(options) => onUpdateItem(index, 'options', null, { value: options })}
                  />
                </Form.Field>
              </Form.Group>
            )}
          </List.Item>
        ))}
      </List>
    </Form>
  );
};

export default MetadataList;
