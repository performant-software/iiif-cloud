// @flow

import { Toaster } from '@performant-software/semantic-components';
import { useEditContainer } from '@performant-software/shared-components';
import React, { useCallback, useState, type ComponentType } from 'react';
import { withTranslation } from 'react-i18next';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import { Button, Message } from 'semantic-ui-react';
import styles from './EditPage.module.css';

type Config = {
  id: string,
  onInitialize: (item: any) => Promise<any>,
  onSave: (item: any) => Promise<any>,
  required?: Array<string>
};

const EditPage = withTranslation()(useEditContainer((props) => {
  const [saved, setSaved] = useState(false);
  const navigate = useNavigate();
  const Form = props.component;

  return (
    <div
      className={styles.editPage}
    >
      <Form
        {...props}
      />
      <div
        className={styles.buttonContainer}
      >
        <Button
          content={props.t('Common.buttons.save')}
          disabled={props.saving || props.loading}
          onClick={() => (
            Promise
              .resolve(props.onSave())
              .then(() => setSaved(true))
          )}
          primary
        />
        <Button
          basic
          content={props.t('Common.buttons.cancel')}
          disabled={props.saving || props.loading}
          onClick={() => navigate(-1)}
        />
      </div>
      { saved && (
        <Toaster
          onDismiss={() => setSaved(false)}
          type={Toaster.MessageTypes.positive}
        >
          <Message.Header
            content={props.t('Common.messages.save.header')}
          />
          <Message.Content
            content={props.t('Common.messages.save.content')}
          />
        </Toaster>
      )}
    </div>
  );
}));

const withEditPage = (WrappedComponent: ComponentType<any>, config: Config): any => (props: any) => {
  const location = useLocation();
  const navigate = useNavigate();
  const params = useParams();

  const id = params[config.id];

  const onSave = useCallback((item) => {
    const { pathname } = location;
    const url = pathname.substring(0, pathname.lastIndexOf('/'));

    return config
      .onSave(item)
      .then((record) => navigate(`${url}/${record.id}`));
  }, [config.onSave, location]);

  return (
    <EditPage
      {...props}
      component={WrappedComponent}
      item={{ id }}
      onInitialize={config.onInitialize}
      onSave={onSave}
      required={config.required}
    />
  );
};

export default withEditPage;
