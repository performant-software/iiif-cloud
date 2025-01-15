// @flow

import cx from 'classnames';
import React, {
  useEffect,
  useMemo,
  useState,
  type ComponentType
} from 'react';
import { useTranslation } from 'react-i18next';
import {
  Dimmer,
  Grid,
  Header,
  Loader
} from 'semantic-ui-react';
import AttributeView from '../components/AttributeView';
import DashboardService from '../services/Dashboard';
import StatusIcon from '../components/StatusIcon';
import styles from './SystemStatus.module.css';

const StatusColors = {
  green: 'GREEN',
  red: 'RED',
  yellow: 'YELLOW'
};

const Statuses = {
  [StatusColors.green]: 'positive',
  [StatusColors.yellow]: 'warning',
  [StatusColors.red]: 'negative'
};

const SystemStatus: ComponentType<any> = () => {
  const [data, setData] = useState();
  const [loading, setLoading] = useState(false);

  const { t } = useTranslation();

  /**
   * Memo-izes the status constant based on the color.
   *
   * @type {unknown}
   */
  const status = useMemo(() => data && Statuses[data.status_color], [data]);

  /**
   * Calls the `/api/dashboard/status` API endpoint and sets the data on the state.
   */
  useEffect(() => {
    setLoading(true);

    DashboardService
      .status()
      .then((response) => setData(response.data))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div
      className={styles.systemStatus}
    >
      <Dimmer
        active={loading}
        inverted
      >
        <Loader />
      </Dimmer>
      <Header
        className={cx(styles.ui, styles.header)}
      >
        { t('SystemStatus.title') }
        <StatusIcon
          className={styles.statusIcon}
          status={status}
        />
      </Header>
      { data && (
        <Grid columns={3}>
          <Grid.Column>
            <AttributeView
              label={t('SystemStatus.labels.application')}
              value={data.application?.name}
            />
          </Grid.Column>
          <Grid.Column>
            <AttributeView
              label={t('SystemStatus.labels.version')}
              value={data.application?.version}
            />
          </Grid.Column>
          <Grid.Column>
            <AttributeView
              label={t('SystemStatus.labels.operatingSystem')}
              value={data.os?.name}
            />
          </Grid.Column>
          <Grid.Column>
            <AttributeView
              label={t('SystemStatus.labels.processors')}
              value={data.os?.processors}
            />
          </Grid.Column>
          <Grid.Column>
            <AttributeView
              label={t('SystemStatus.labels.vm')}
              value={data.vm?.name}
            />
          </Grid.Column>
          <Grid.Column>
            <AttributeView
              label={t('SystemStatus.labels.vmVersion')}
              value={data.vm?.version}
            />
          </Grid.Column>
        </Grid>
      )}
    </div>
  );
};

export default SystemStatus;
