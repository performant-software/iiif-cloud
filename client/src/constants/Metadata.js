// @flow

import _ from 'underscore';
import i18n from '../i18n/i18n';

const Types = {
  checkbox: 'checkbox',
  date: 'date',
  dropdown: 'dropdown',
  number: 'number',
  string: 'string',
  text: 'text'
};

const MetadataOptions = _.map(_.values(Types), (type) => ({
  key: type,
  value: type,
  text: i18n.t(`Metadata.types.${type}`)
}));

type GetOptionsType = () => Array<any>;

const getOptions: GetOptionsType = () => _.sortBy(MetadataOptions, 'text');

export default {
  getOptions,
  Types
};
