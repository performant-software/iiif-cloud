// @flow

import { BaseService } from '@performant-software/shared-components';
import React, {
  useEffect,
  useState,
  type Element,
  type Node
} from 'react';
import { useParams } from 'react-router-dom';

type Props = {
  idParam: string,
  parameterName: string,
  renderItem: (item: any) => Element<any>,
  serviceClass: typeof BaseService,
};

const Breadcrumb = (props: Props): Node => {
  const params = useParams();
  const [item, setItem] = useState();

  const id = params[props.idParam];

  useEffect(() => {
    if (id) {
      props.serviceClass
        .fetchOne(id)
        .then(({ data }) => setItem(data[props.parameterName]));
    }
  }, [id]);

  if (!item) {
    return null;
  }

  return (
    <span>{ props.renderItem(item) }</span>
  );
};

export default Breadcrumb;
