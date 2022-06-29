// @flow

import { matchPath, resolvePath, useMatch } from 'react-router-dom';
import _ from 'underscore';

type Location = {
  pathname: string
};

type Params = {
  [string]: string
};

/**
 * Returns the current path for the passed location and params.
 *
 * @param location
 * @param params
 *
 * @returns {string}
 */
const getCurrentPath = (location: Location, params: Params): string => {
  const { pathname } = location;

  if (_.isEmpty(params)) {
    return pathname;
  }

  let path = pathname;

  _.each(_.keys(params), (name) => {
    const value = params[name];
    if (value) {
      path = path.replace(value, `:${name}`);
    }
  });

  return path;
};

/**
 *
 * @param args
 * @returns {string}
 */
const join = (...args: Array<string>): string => {
  const path = [];

  _.each(args, (arg) => {
    if (arg) {
      path.push(arg);
    }
  });

  return path.join('/');
};

// const currentPathStartsWith = (location, params, pathname) => {
//   let value;
//
//   const currentPath = getCurrentPath(location, params);
//
//   if (pathname === '/') {
//     value = currentPath === pathname;
//   } else {
//     value = currentPath.startsWith(pathname);
//   }
//   return value;
// };
//
// const currentPathEndsWith = (pathname) => {
//   return matchPath({ path: pathname, end: true });
// };

export default {
  getCurrentPath,
  join
};
