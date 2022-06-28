// @flow

import React, {
  useEffect,
  useRef,
  useState,
  type ComponentType
} from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import styles from './Layout.module.css';
import Breadcrumbs from './Breadcrumbs';

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
        <Breadcrumbs />
        <Outlet />
      </div>
    </div>
  );
};

export default Layout;
