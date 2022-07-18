// @flow

import { ListTable } from '@performant-software/semantic-components';
import React, { type ComponentType } from 'react';
import { Link } from 'react-router-dom';
import { Button } from 'semantic-ui-react';
import _ from 'underscore';

type Props = {
  actions?: Array<any>,
  allowAdd?: boolean,
  allowEdit?: boolean,
  buttons?: Array<any>
};

const ItemList: ComponentType<any> = (props: Props) => (
  <ListTable
    actions={[{
      accept: () => props.allowEdit,
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
      accept: () => props.allowEdit,
      name: 'delete'
    }, ...(props.actions || [])]}
    addButton={{}}
    buttons={[{
      accept: () => props.allowAdd,
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

// $FlowIssue - Ignoring default props error
ItemList.defaultProps = {
  allowAdd: true,
  allowEdit: true
};

export default ItemList;
