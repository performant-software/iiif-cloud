// @flow

import { ListTable } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router';
import { Button } from 'semantic-ui-react';
import _ from 'underscore';

type Props = {
  actions?: Array<any>,
  allowAdd?: boolean,
  allowEdit?: boolean,
  buttons?: Array<any>
};

const SimpleList: ComponentType<any> = (props: Props) => {
  const {
    actions,
    allowAdd = true,
    allowEdit = true,
    buttons,
    ...rest
  } = props;

  const { t } = useTranslation();

  return (
    <ListTable
      actions={[{
        accept: () => allowEdit,
        name: 'edit',
        render: (item) => (
          <Button
            as={Link}
            basic
            compact
            icon='edit'
            key={item.id}
            to={item.id.toString()}
          />
        )
      }, {
        accept: () => allowEdit,
        name: 'delete'
      }, ...(actions || [])]}
      addButton={{}}
      buttons={[{
        accept: () => allowAdd,
        as: Link,
        basic: true,
        content: t('Common.buttons.add'),
        icon: 'plus',
        to: 'new'
      }, ...(buttons || [])]}
      perPageOptions={[10, 25, 50, 100]}
      {..._.omit(rest, 'actions', 'buttons')}
    />
  );
};

export default SimpleList;
