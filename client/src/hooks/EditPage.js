// @flow

import { useEditContainer } from '@performant-software/shared-components';
import React, { useCallback, type ComponentType } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import _ from 'underscore';
import { useTranslation } from 'react-i18next';

type Config = {
  id: string,
  onInitialize: (item: any) => Promise<any>,
  onSave: (item: any) => Promise<any>,
  required?: Array<string>,
  resolveValidationError?: (params: any) => any,
  validate?: () => {}
};

const withEditPage = (WrappedComponent: ComponentType<any>, config: Config): any => (props: any) => {
  const location = useLocation();
  const navigate = useNavigate();
  const { t } = useTranslation();

  const params = useParams();
  const id = params[config.id];

  let tab;

  /**
   * Adds the authorization error.
   *
   * @type {function(*): {}}
   */
  const resolveValidationError = useCallback((errorProps) => {
    const errors = {};

    if (config.resolveValidationError) {
      _.extend(errors, config.resolveValidationError(errorProps));
    }

    if (errorProps.status === 403) {
      _.extend(errors, { base: t('Common.errors.unauthorized') });
    }

    return errors;
  }, [config.resolveValidationError]);

  const onSave = useCallback((item) => {
    const { pathname } = location;
    const url = pathname.substring(0, pathname.lastIndexOf('/'));

    return config
      .onSave(item)
      .then((record) => navigate(`${url}/${record.id}`, { state: { saved: true, tab } }));
  }, [config.onSave, location, navigate]);

  // eslint-disable-next-line react/no-unstable-nested-components
  const EditPage = (innerProps) => (
    <WrappedComponent
      {...innerProps}
      onTabClick={(newTab) => {
        tab = newTab;
      }}
    />
  );

  const EditContainer = useEditContainer(EditPage);

  return (
    <EditContainer
      {...props}
      item={{ id }}
      onInitialize={config.onInitialize}
      onSave={onSave}
      required={config.required}
      resolveValidationError={resolveValidationError}
      validate={config.validate}
    />
  );
};

export default withEditPage;
