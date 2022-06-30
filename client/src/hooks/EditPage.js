// @flow

import { useEditContainer } from '@performant-software/shared-components';
import React, { useCallback, type ComponentType } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';

type Config = {
  onInitialize: (item: any) => Promise<any>,
  onSave: (item: any) => Promise<any>,
  required?: Array<string>
};

const withEditPage = (WrappedComponent: ComponentType<any>, config: Config): any => (props: any) => {
  const location = useLocation();
  const navigate = useNavigate();
  const { id } = useParams();

  let tab;

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
      onTabClick={(t) => {
        tab = t;
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
    />
  );
};

export default withEditPage;
