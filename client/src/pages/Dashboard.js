// @flow

import React, { type ComponentType } from 'react';
import { Container, Grid, Segment } from 'semantic-ui-react';
import AdminPage from '../components/AdminPage';
import HeapSpace from '../widgets/HeapSpace';
import SystemStatus from '../widgets/SystemStatus';

const Dashboard: ComponentType<any> = () => (
  <AdminPage>
    <Container
      fluid
    >
      <Grid>
        <Grid.Row
          columns={1}
        >
          <Grid.Column
            as={Segment}
          >
            <SystemStatus />
          </Grid.Column>
        </Grid.Row>
        <Grid.Row
          columns={2}
        >
          <Grid.Column
            as={Segment}
          >
            <HeapSpace />
          </Grid.Column>
        </Grid.Row>
      </Grid>
    </Container>
  </AdminPage>
);

export default Dashboard;
