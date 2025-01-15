// @flow

import cx from 'classnames';
import React, { type ComponentType } from 'react';
import { useTranslation } from 'react-i18next';
import { Icon, Image, List } from 'semantic-ui-react';
import FileUtils from '../utils/File';
import styles from './AttachmentDetails.module.css';

type Props = {
  attachment?: {
    byte_size: number,
    content_type: string,
    key: string,
  }
};

const AttachmentDetails: ComponentType<any> = (props: Props) => {
  const { t } = useTranslation();

  return (
    <div
      className={styles.attachmentDetails}
    >
      { !props.attachment && (
        <span>
          { t('AttachmentDetails.messages.noContent') }
        </span>
      )}
      { props.attachment && (
        <List
          className={cx(styles.ui, styles.list, styles.horizontal)}
          horizontal
        >
          <List.Item
            content={props.attachment?.key}
            header={t('AttachmentDetails.labels.key')}
            image={(
              <Image>
                <Icon
                  circular
                  name='aws'
                  size='large'
                />
              </Image>
            )}
          />
          <List.Item
            content={FileUtils.getFileSize(props.attachment?.byte_size)}
            header={t('AttachmentDetails.labels.fileSize')}
            image={(
              <Image>
                <Icon
                  circular
                  name='file alternate'
                  size='large'
                />
              </Image>
            )}
          />
          <List.Item
            content={props.attachment?.content_type}
            header={t('AttachmentDetails.labels.type')}
            image={(
              <Image>
                <Icon
                  circular
                  name='th large'
                  size='large'
                />
              </Image>
            )}
          />
        </List>
      )}
    </div>
  );
};

export default AttachmentDetails;
