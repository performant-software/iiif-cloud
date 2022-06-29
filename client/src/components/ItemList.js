// @flow

import { ListTable } from '@performant-software/semantic-components';
import React, { type Node } from 'react';
import { Link } from 'react-router-dom';
import { Button } from 'semantic-ui-react';
import _ from 'underscore';

type Props = {
  actions?: Array<any>,
  buttons?: Array<any>
};

const ItemList = (props: Props): Node => (
  <ListTable
    actions={[{
      name: 'edit',
      render: (item) => (
        <Button
          as={Link}
          basic
          compact
          icon='edit'
          to={item.id.toString()}
        />
      )
    }, {
      name: 'delete'
    }, ...(props.actions || [])]}
    addButton={{}}
    buttons={[{
      as: Link,
      basic: true,
      content: 'Add',
      icon: 'plus',
      to: 'new'
    }, ...(props.buttons || [])]}
    perPageOptions={[10, 25, 50, 100]}
    {..._.omit(props, 'actions', 'buttons')}
  />
);

export default ItemList;
