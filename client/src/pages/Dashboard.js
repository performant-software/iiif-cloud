// @flow

import React, { type ComponentType } from 'react';
import { Container, Segment } from 'semantic-ui-react';
import AdminPage from '../components/AdminPage';
import SystemStatus from '../widgets/SystemStatus';

const Dashboard: ComponentType<any> = () => (
  <AdminPage>
    <Container
      fluid
    >
      <Segment>
        <SystemStatus />
      </Segment>
    </Container>
  </AdminPage>
);

export default Dashboard;
