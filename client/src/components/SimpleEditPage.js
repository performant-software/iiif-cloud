// @flow

import { Toaster } from '@performant-software/semantic-components';
import { Element } from '@performant-software/shared-components';
import type { EditContainerProps } from '@performant-software/shared-components/types';
import cx from 'classnames';
import React, {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ComponentType
} from 'react';
import _ from 'underscore';
import {
  Button,
  Form,
  Grid,
  Menu,
  Message,
  Ref,
  Sticky
} from 'semantic-ui-react';
import styles from './SimpleEditPage.module.css';
import { useLocation, useNavigate } from 'react-router-dom';
import type { Translateable } from '../types/Translateable';

type Props = EditContainerProps & Translateable & {
  onTabClick?: (tab: string) => void,
  stickyMenu?: boolean
};

const SimpleEditPage: ComponentType<any> = (props: Props) => {
  const [currentTab, setCurrentTab] = useState();
  const [saved, setSaved] = useState(false);

  const contentRef = useRef();
  const location = useLocation();
  const navigate = useNavigate();

  // $FlowIgnore
  const tabs = Element.findByType(props.children, SimpleEditPage.Tab);
  const tab = useMemo(() => _.find(tabs, (t) => t.key === currentTab), [currentTab, tabs]);

  /**
   * Sets the current tab.
   *
   * @type {(function(*): void)|*}
   */
  const onTabClick = useCallback((item) => {
    const { key } = item;
    setCurrentTab(key);

    if (props.onTabClick) {
      props.onTabClick(key);
    }
  }, [props.onTabClick]);

  /**
   * Renders the tab menu component.
   *
   * @type {(function(): (*))|*}
   */
  const renderTabs = useCallback(() => {
    const menu = (
      <Menu
        className={styles.menu}
        pointing
        secondary
      >
        { _.map(tabs, (item) => (
          <Menu.Item
            active={item.key === currentTab}
            disabled={props.loading || props.saving}
            key={item.key}
            name={item.props.name}
            onClick={() => onTabClick(item)}
          />
        ))}
        <Menu.Menu
          position='right'
        >
          <Menu.Item
            className={cx(styles.item, styles.buttonContainer)}
          >
            <Button
              className={styles.button}
              content={props.t('Common.buttons.save')}
              disabled={props.loading || props.saving}
              onClick={props.onSave}
              primary
            />
            <Button
              basic
              className={styles.button}
              content={props.t('Common.buttons.cancel')}
              disabled={props.loading || props.saving}
              onClick={() => navigate(-1)}
            />
          </Menu.Item>
        </Menu.Menu>
      </Menu>
    );

    if (props.stickyMenu) {
      return (
        <Sticky
          context={contentRef}
          offset={20}
        >
          { menu }
        </Sticky>
      );
    }

    return menu;
  });

  useEffect(() => {
    // Sets the default tab to the first tab in the list, or the tab on the URL state
    let defaultTab;

    const { state } = location;
    if (state && state.tab) {
      defaultTab = { key: state.tab };
    } else {
      defaultTab = _.first(tabs);
    }

    onTabClick(defaultTab);

    // Sets the saved indicator based on the URL state
    if (state && state.saved) {
      setSaved(true);
    }
  }, []);

  return (
    <Grid
      className={styles.simpleEditPage}
    >
      <Grid.Row>
        <Grid.Column>
          { renderTabs() }
        </Grid.Column>
      </Grid.Row>
      <Grid.Row>
        <Grid.Column>
          <Ref
            innerRef={contentRef}
          >
            <div>
              <Form
                error={!_.isEmpty(props.errors)}
                loading={props.loading || props.saving}
                noValidate
              >
                <Message
                  error
                  header={props.t('Common.errors.save')}
                  list={props.errors}
                />
                { tab && tab.props.children }
              </Form>
              { saved && (
                <Toaster
                  onDismiss={() => setSaved(false)}
                  type={Toaster.MessageTypes.positive}
                >
                  <Message.Header
                    content={props.t('Common.messages.save.header')}
                  />
                  <Message.Content
                    content={props.t('Common.messages.save.content')}
                  />
                </Toaster>
              )}
            </div>
          </Ref>
        </Grid.Column>
      </Grid.Row>
    </Grid>
  );
};

const Tab = (props) => props.children;
Tab.displayName = 'Tab';

// $FlowIgnore
const SimpleEditPageStatic = Object.assign(SimpleEditPage, { Tab });

export default SimpleEditPageStatic;
