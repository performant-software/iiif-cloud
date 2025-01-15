// @flow

import { BaseService } from '@performant-software/shared-components';

/**
 * Class responsible for handling all dashboard API requests.
 */
class Dashboard extends BaseService {
  /**
   * Not implemented.
   *
   * @param args
   *
   * @returns {Promise<*>}
   */
  create(...args: any): Promise<any> {
    return Promise.reject(args);
  }

  /**
   * Not implemented.
   *
   * @param args
   *
   * @returns {Promise<*>}
   */
  delete(...args: any): Promise<any> {
    return Promise.reject(args);
  }

  /**
   * Not implemented.
   *
   * @param args
   *
   * @returns {Promise<*>}
   */
  fetchAll(...args: any): Promise<any> {
    return Promise.reject(args);
  }

  /**
   * Not implemented.
   *
   * @param args
   *
   * @returns {Promise<*>}
   */
  fetchOne(...args: any): Promise<any> {
    return Promise.reject(args);
  }

  /**
   * Returns the dashboard base URL.
   *
   * @returns {string}
   */
  getBaseUrl(): string {
    return '/api/dashboard';
  }

  /**
   * Not implemented.
   *
   * @param args
   *
   * @returns {Promise<*>}
   */
  save(...args: any): Promise<any> {
    return Promise.reject(args);
  }

  /**
   * Calls the `/api/dashboard/status` API endpoint.
   *
   * @returns {*}
   */
  status(): Promise<any> {
    return this.getAxios().get(`${this.getBaseUrl()}/status`, null, this.getConfig());
  }

  /**
   * Not implemented.
   *
   * @param args
   *
   * @returns {Promise<*>}
   */
  update(...args: any): Promise<any> {
    return Promise.reject(args);
  }
}

const DashboardService: Dashboard = new Dashboard();
export default DashboardService;
