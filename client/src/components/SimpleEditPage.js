// @flow

import { Element } from '@performant-software/shared-components';
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
import { Toaster } from '@performant-software/semantic-components';
import { useLocation, useNavigate } from 'react-router-dom';
import type { EditContainerProps } from '@performant-software/shared-components/types';
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
   * Calls the onSave prop and sets the "saved" variable if no errors occur.
   *
   * @type {function(): Promise<unknown>|*}
   */
  const onSave = useCallback(() => (
    Promise
      .resolve(props.onSave())
      .then(() => {
        if (_.isEmpty(props.errors)) {
          setSaved(true);
        }
      })
  ), [props.errors, props.onSave]);

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
        pointing
        secondary
      >
        { _.map(tabs, (item) => (
          <Menu.Item
            active={item.key === currentTab}
            key={item.key}
            name={item.props.name}
            onClick={() => onTabClick(item)}
          />
        ))}
        <Menu.Menu
          position='right'
        >
          <Menu.Item>
            <Button
              content={props.t('Common.buttons.save')}
              onClick={onSave}
              primary
            />
          </Menu.Item>
          <Menu.Item>
            <Button
              basic
              content={props.t('Common.buttons.cancel')}
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
    <Grid>
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
