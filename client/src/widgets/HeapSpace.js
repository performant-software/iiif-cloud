// @flow

import React, {
  useCallback,
  useEffect,
  useState,
  type ComponentType
} from 'react';
import { useTranslation } from 'react-i18next';
import {
  Cell,
  Legend,
  Pie,
  PieChart,
  Tooltip
} from 'recharts';
import DashboardService from '../services/Dashboard';
import Widget from '../components/Widget';

const HeapSpace: ComponentType<any> = () => {
  const [data, setData] = useState();
  const [loading, setLoading] = useState(false);

  const { t } = useTranslation();

  /**
   * Calls the `/api/dashboard/heap` API endpoint.
   *
   * @type {(function(): void)|*}
   */
  const onLoad = useCallback(() => {
    setLoading(true);

    DashboardService
      .heap()
      .then(({ data: { max, used } }) => setData([{
        name: t('HeapSpace.labels.free'),
        value: max - used
      }, {
        name: t('HeapSpace.labels.used'),
        value: used
      }]))
      .finally(() => setLoading(false));
  }, []);

  /**
   * Renders the custom label based on the passed percent.
   *
   * @type {function({percent: *}): string}
   */
  const renderLabel = useCallback(({ percent }) => `${(percent * 100).toFixed(0)}%`, []);

  /**
   * Calls the onLoad function when the component is mounted.
   */
  useEffect(() => onLoad(), []);

  return (
    <Widget
      loading={loading}
      onReload={onLoad}
      title={t('HeapSpace.title')}
    >
      <PieChart
        width={400}
        height={400}
      >
        <Pie
          dataKey='value'
          data={data}
          isAnimationActive={false}
          label={renderLabel}
        >
          <Cell
            fill='#3e5c76'
          />
          <Cell
            fill='#748cab'
          />
        </Pie>
        <Tooltip />
        <Legend />
      </PieChart>
    </Widget>
  );
};

export default HeapSpace;
