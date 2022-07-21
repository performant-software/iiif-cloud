// @flow

import _ from 'underscore';

/**
 * Converts the passed value to a string for FormData.
 *
 * @param value
 *
 * @returns {*|string}
 */
const toString: any = (value: any) => {
  if (_.isNumber(value) || _.isBoolean(value)) {
    return value;
  }

  return value || '';
};

export default {
  toString
};
