// @flow

import React, { createContext, useEffect, useMemo, useState } from 'react';
import UsersService from '../services/Users';
import { useAuth } from '@clerk/react';
import type { User as UserType } from '../types/User';

interface AuthenticationContextType {
  setUser: (user: UserType | null) => void;
  signOut: () => void;
  user: UserType | null;
}

export const AuthenticationContext = createContext<AuthenticationContextType>({
  setUser: () => {},
  signOut: () => {},
  user: null
});

interface AuthenticationContextProps {
  children?: any;
}

export const AuthenticationContextProvider = ({ children }: AuthenticationContextProps) => {
  const clerkAuth = useAuth();
  const [user, setUser] = useState(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (clerkAuth.isSignedIn && !user) {
      UsersService.getMe()
        .then(res => setUser(res.data))
        .catch(() => clerkAuth.signOut());
    }
  }, [clerkAuth.isSignedIn]);

  useEffect(() => {
    if (clerkAuth.isLoaded && !!(user || !clerkAuth.isSignedIn)) {
      setReady(true);
    }
  }, [clerkAuth.isSignedIn, user]);

  const value = useMemo(() => {
    return { user, setUser, signOut: clerkAuth.signOut };
  }, [user, setUser, clerkAuth.signOut]);

  return (
    <AuthenticationContext.Provider value={value}>
      {ready && children}
    </AuthenticationContext.Provider>
  );
};

