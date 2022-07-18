// @flow

import CloverIIIF from '@samvera/clover-iiif';
import React, { type ComponentType } from 'react';
import { Modal } from 'semantic-ui-react';

type Props = {
  manifestId: string,
  onClose: () => void
};

const ResourceViewerModal: ComponentType<any> = (props: Props) => (
  <Modal
    centered={false}
    closeIcon
    onClose={props.onClose}
    open
  >
    <Modal.Content>
      <CloverIIIF
        manifestId={props.manifestId}
        options={{
          showIIIFBadge: false
        }}
      />
    </Modal.Content>
  </Modal>
);

export default ResourceViewerModal;
