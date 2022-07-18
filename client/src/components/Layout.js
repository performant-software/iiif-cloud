// @flow

import React, {
  useEffect,
  useRef,
  useState,
  type ComponentType
} from 'react';
import { Outlet } from 'react-router-dom';
import { Container } from 'semantic-ui-react';
import Sidebar from './Sidebar';
import styles from './Layout.module.css';

const Layout: ComponentType<any> = () => {
  const [menuWidth, setMenuWidth] = useState();

  const sidebarRef = useRef();

  /**
   * Sets the width of the sidebar to dynamically set the margin.
   */
  useEffect(() => {
    if (sidebarRef && sidebarRef.current) {
      setMenuWidth(sidebarRef.current.offsetWidth);
    }
  }, [sidebarRef]);

  return (
    <div
      className={styles.adminLayout}
    >
      <Sidebar
        context={sidebarRef}
      />
      <div
        className={styles.content}
        style={{
          marginLeft: menuWidth
        }}
      >
        <Container>
          <Outlet />
        </Container>
      </div>
    </div>
  );
};

export default Layout;
