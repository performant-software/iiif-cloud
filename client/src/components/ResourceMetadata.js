// @flow

import { DatePicker } from '@performant-software/semantic-components';
import React, { useCallback, type ComponentType } from 'react';
import { Form } from 'semantic-ui-react';
import _ from 'underscore';
import Metadata from '../constants/Metadata';

type Item = {
  multiple?: boolean,
  name: string,
  options?: Array<string>,
  required?: boolean,
  type: string,
  value: any
};

type Props = {
  items: Array<Item>,
  onChange: (item: any) => void,
  value: any
};

const ResourceMetadata: ComponentType<any> = (props: Props) => {
  /**
   * Changes the value for the passed item.
   *
   * @type {(function(*, *): void)|*}
   */
  const onChange = useCallback((item, value) => {
    props.onChange({ ...props.value, [item.name]: value });
  }, [props.onChange, props.value]);

  /**
   * Renders the passed item.
   *
   * @type {function(*): *}
   */
  const renderItem = useCallback((item) => {
    let rendered;

    if (item.type === Metadata.Types.string) {
      rendered = (
        <Form.Input
          label={item.name}
          required={item.required}
          onChange={(e, { value }) => onChange(item, value)}
          value={props.value && props.value[item.name]}
        />
      );
    }

    if (item.type === Metadata.Types.number) {
      rendered = (
        <Form.Input
          label={item.name}
          required={item.required}
          onChange={(e, { value }) => onChange(item, value)}
          value={props.value && props.value[item.name]}
          type='number'
        />
      );
    }

    if (item.type === Metadata.Types.dropdown) {
      rendered = (
        <Form.Dropdown
          label={item.name}
          multiple={item.multiple}
          required={item.required}
          options={_.map(item.options, (option) => ({ key: option, value: option, text: option }))}
          onChange={(e, { value }) => onChange(item, value)}
          selectOnBlur={false}
          selection
          value={props.value && props.value[item.name]}
        />
      );
    }

    if (item.type === Metadata.Types.text) {
      rendered = (
        <Form.TextArea
          label={item.name}
          required={item.required}
          onChange={(e, { value }) => onChange(item, value)}
          value={props.value && props.value[item.name]}
        />
      );
    }

    if (item.type === Metadata.Types.date) {
      rendered = (
        <Form.Input
          label={item.name}
          required={item.required}
        >
          <DatePicker
            onChange={(date) => onChange(item, date && date.toString())}
            value={props.value && props.value[item.name] && new Date(props.value[item.name])}
          />
        </Form.Input>
      );
    }

    if (item.type === Metadata.Types.checkbox) {
      rendered = (
        <Form.Checkbox
          checked={props.value && props.value[item.name]}
          label={item.name}
          onChange={(e, { checked }) => onChange(item, checked)}
        />
      );
    }

    return rendered;
  }, [props.value]);

  return (
    <>
      { _.map(props.items, renderItem.bind(this)) }
    </>
  );
};

export default ResourceMetadata;
