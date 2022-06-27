// @flow

import React, {
  useEffect,
  useRef,
  useState,
  type ComponentType
} from 'react';
import { Outlet } from 'react-router-dom';
import AdminSidebar from '../components/AdminSidebar';
import styles from './AdminLayout.module.css';

const AdminLayout: ComponentType<any> = () => {
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
      <AdminSidebar
        context={sidebarRef}
      />
      <div
        className={styles.content}
        style={{
          marginLeft: menuWidth
        }}
      >
        <Outlet />
      </div>
    </div>
  );
};

export default AdminLayout;
