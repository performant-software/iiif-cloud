// @flow

import React, { type ComponentType } from 'react';
import Login from '../components/Login';
import styles from './Home.module.css';
import { Image } from 'semantic-ui-react';

const Home: ComponentType<any> = () => (
  <div
    className={styles.home}
  >
    <Image
      className={styles.background}
      src='/assets/clouds.jpeg'
    />
    <Login />
  </div>
);

export default Home;
