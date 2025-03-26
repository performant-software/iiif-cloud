// @flow

import React, {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ComponentType
} from 'react';
import { useTranslation } from 'react-i18next';
import { Grid } from 'semantic-ui-react';
import AttributeView from '../components/AttributeView';
import DashboardService from '../services/Dashboard';
import StatusIcon from '../components/StatusIcon';
import styles from './SystemStatus.module.css';
import Widget from '../components/Widget';

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
  const onLoad = useCallback(() => {
    setLoading(true);

    DashboardService
      .status()
      .then((response) => setData(response.data))
      .finally(() => setLoading(false));
  }, []);

  /**
   * Calls the onLoad function when the component is mounted.
   */
  useEffect(() => onLoad(), [onLoad]);

  return (
    <Widget
      className={styles.systemStatus}
      loading={loading}
      onReload={onLoad}
      title={(
        <>
          { t('SystemStatus.title') }
          <StatusIcon
            className={styles.statusIcon}
            status={status}
          />
        </>
      )}
    >
      { data && (
        <Grid
          columns={3}
        >
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
    </Widget>
  );
};

export default SystemStatus;
