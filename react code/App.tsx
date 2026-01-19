import React, { useState, useCallback, useRef } from 'react';
import { AppBar } from './components/casazero/AppBar';
import { BottomNav } from './components/casazero/BottomNav';
import { NavigationIndicator } from './components/casazero/NavigationIndicator';
import { AuthScreen } from './components/screens/AuthScreen';
import { FirstLoginSetupScreen } from './components/screens/FirstLoginSetupScreen';
import { ChangePasswordScreen } from './components/screens/ChangePasswordScreen';
import { HomeScreen } from './components/screens/HomeScreen';
import { DocumentsScreen } from './components/screens/DocumentsScreen';
import { MaintenanceScreen } from './components/screens/MaintenanceScreen';
import { AIScreen } from './components/screens/AIScreen';
import { TicketsScreen } from './components/screens/TicketsScreen';
import { ChatScreen } from './components/screens/ChatScreen';
import { SmartHomeScreen } from './components/screens/SmartHomeScreen';
import { ProfileScreen } from './components/screens/ProfileScreen';
import { NotificationsScreen } from './components/screens/NotificationsScreen';
import { AnalyticsScreen } from './components/screens/AnalyticsScreen';
import { UserManagementScreen } from './components/screens/UserManagementScreen';
import { BuildingManagementScreen } from './components/screens/BuildingManagementScreen';
import { HubScreen } from './components/screens/HubScreen';
import { BuildingSelector } from './components/casazero/BuildingSelector';
import { DemoControls } from './components/casazero/DemoControls';
import { Toaster } from './components/ui/sonner';
import { getPermissions } from './utils/permissions';
import { LanguageProvider } from './utils/LanguageContext';

type Screen = 'home' | 'documents' | 'maintenance' | 'ai' | 'hub' | 'aichat' | 'tickets' | 'chat' | 'smarthome' | 'profile' | 'notifications' | 'analytics' | 'users' | 'buildings' | 'change-password';
type Role = 'client' | 'admin';

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isFirstLogin, setIsFirstLogin] = useState(false);
  const [setupComplete, setSetupComplete] = useState(false);
  const [userEmail, setUserEmail] = useState('');
  const [userName, setUserName] = useState('Marco Rossi');
  const [currentScreen, setCurrentScreen] = useState<Screen>('home');
  const [role, setRole] = useState<Role>('client');
  const [currentResidence, setCurrentResidence] = useState('Building A, Unit 4B');
  const [notificationCount] = useState(3);
  
  // Building management state
  const [currentBuilding, setCurrentBuilding] = useState({
    id: '1',
    name: 'Residenza Verde Building A',
    address: 'Via Giuseppe Verdi 42, 20121 Milano MI',
    units: 24,
    residents: 42,
  });

  const [buildings] = useState([
    {
      id: '1',
      name: 'Residenza Verde Building A',
      address: 'Via Giuseppe Verdi 42, 20121 Milano MI',
      units: 24,
      residents: 42,
    },
    {
      id: '2',
      name: 'Residenza Verde Building B',
      address: 'Via Giuseppe Verdi 44, 20121 Milano MI',
      units: 32,
      residents: 0,
    },
  ]);

  // Navigation history management
  const [history, setHistory] = useState<Screen[]>(['home']);
  const [historyIndex, setHistoryIndex] = useState(0);
  const isNavigatingRef = useRef(false);
  const [navigationDirection, setNavigationDirection] = useState<'back' | 'forward' | null>(null);

  // Demo: For testing different property states
  const [residenceStatus, setResidenceStatus] = useState<'completed' | 'under-construction'>('completed');

  const handleLogin = (selectedRole: string, email?: string) => {
    setRole(selectedRole as Role);
    setUserEmail(email || 'demo@casazero.com');
    
    // Check if it's first login (in demo mode, we'll simulate this)
    // In production, this would come from the backend
    const hasCompletedSetup = localStorage.getItem(`casazero_setup_${email || 'demo'}`);
    
    if (!hasCompletedSetup) {
      setIsFirstLogin(true);
    } else {
      setIsAuthenticated(true);
    }
    
    // Reset history on login
    setHistory(['home']);
    setHistoryIndex(0);
  };

  const handleSetupComplete = () => {
    // Mark setup as complete
    localStorage.setItem(`casazero_setup_${userEmail}`, 'true');
    setIsFirstLogin(false);
    setSetupComplete(true);
    setIsAuthenticated(true);
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    setIsFirstLogin(false);
    setSetupComplete(false);
    setCurrentScreen('home');
    // Reset history on logout
    setHistory(['home']);
    setHistoryIndex(0);
  };

  // Navigate to a new screen and update history
  const handleNavigate = useCallback((screen: string) => {
    if (isNavigatingRef.current) return; // Prevent navigation loops
    
    const newScreen = screen as Screen;
    
    // Don't add duplicate consecutive screens
    if (newScreen === currentScreen) return;

    setCurrentScreen(newScreen);
    
    setHistory(prev => {
      // If we're not at the end of history, remove everything after current position
      const newHistory = prev.slice(0, historyIndex + 1);
      // Add new screen to history
      return [...newHistory, newScreen];
    });
    
    setHistoryIndex(prev => prev + 1);
  }, [currentScreen, historyIndex]);

  // Navigate back in history
  const handleBack = useCallback(() => {
    if (historyIndex > 0) {
      isNavigatingRef.current = true;
      setNavigationDirection('back');
      const newIndex = historyIndex - 1;
      setHistoryIndex(newIndex);
      setCurrentScreen(history[newIndex]);
      
      // Reset the flag and direction after navigation
      setTimeout(() => {
        isNavigatingRef.current = false;
        setNavigationDirection(null);
      }, 800);
    }
  }, [history, historyIndex]);

  // Navigate forward in history
  const handleForward = useCallback(() => {
    if (historyIndex < history.length - 1) {
      isNavigatingRef.current = true;
      setNavigationDirection('forward');
      const newIndex = historyIndex + 1;
      setHistoryIndex(newIndex);
      setCurrentScreen(history[newIndex]);
      
      // Reset the flag and direction after navigation
      setTimeout(() => {
        isNavigatingRef.current = false;
        setNavigationDirection(null);
      }, 800);
    }
  }, [history, historyIndex]);

  const handleNotifications = () => {
    handleNavigate('notifications');
  };

  // Check if back/forward navigation is available
  const canGoBack = historyIndex > 0;
  const canGoForward = historyIndex < history.length - 1;

  // Keyboard shortcuts for navigation
  React.useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Alt + Left Arrow or Cmd/Ctrl + [
      if ((e.altKey && e.key === 'ArrowLeft') || ((e.metaKey || e.ctrlKey) && e.key === '[')) {
        e.preventDefault();
        if (canGoBack) handleBack();
      }
      // Alt + Right Arrow or Cmd/Ctrl + ]
      if ((e.altKey && e.key === 'ArrowRight') || ((e.metaKey || e.ctrlKey) && e.key === ']')) {
        e.preventDefault();
        if (canGoForward) handleForward();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [canGoBack, canGoForward, handleBack, handleForward]);

  // Swipe gestures for mobile navigation
  React.useEffect(() => {
    let touchStartX = 0;
    let touchStartY = 0;
    let touchEndX = 0;
    let touchEndY = 0;

    const handleTouchStart = (e: TouchEvent) => {
      touchStartX = e.changedTouches[0].screenX;
      touchStartY = e.changedTouches[0].screenY;
    };

    const handleTouchEnd = (e: TouchEvent) => {
      touchEndX = e.changedTouches[0].screenX;
      touchEndY = e.changedTouches[0].screenY;
      handleSwipe();
    };

    const handleSwipe = () => {
      const swipeThreshold = 50;
      const deltaX = touchEndX - touchStartX;
      const deltaY = touchEndY - touchStartY;

      // Only trigger swipe if horizontal movement is greater than vertical
      if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > swipeThreshold) {
        if (deltaX > 0 && canGoBack) {
          // Swipe right - go back
          handleBack();
        } else if (deltaX < 0 && canGoForward) {
          // Swipe left - go forward
          handleForward();
        }
      }
    };

    document.addEventListener('touchstart', handleTouchStart);
    document.addEventListener('touchend', handleTouchEnd);

    return () => {
      document.removeEventListener('touchstart', handleTouchStart);
      document.removeEventListener('touchend', handleTouchEnd);
    };
  }, [canGoBack, canGoForward, handleBack, handleForward]);

  // Show first login setup if user hasn't completed it
  if (isFirstLogin && !setupComplete) {
    return (
      <LanguageProvider>
        <FirstLoginSetupScreen 
          onComplete={handleSetupComplete}
          userEmail={userEmail}
        />
      </LanguageProvider>
    );
  }

  if (!isAuthenticated) {
    return (
      <LanguageProvider>
        <AuthScreen onLogin={handleLogin} />
      </LanguageProvider>
    );
  }

  const getScreenTitle = () => {
    switch (currentScreen) {
      case 'home':
        return null; // Uses residence switcher
      case 'documents':
        return 'Documents';
      case 'maintenance':
        return 'Maintenance';
      case 'ai':
        return 'CasaZero AI';
      case 'hub':
        return 'Ecosystem Hub';
      case 'aichat':
        return 'CasaZero AI';
      case 'tickets':
        return 'Support Tickets';
      case 'chat':
        return 'Group Chat';
      case 'smarthome':
        return 'Smart Home';
      case 'profile':
        return 'Profile';
      case 'notifications':
        return 'Notifications';
      case 'analytics':
        return 'Analytics';
      case 'users':
        return 'User Management';
      case 'buildings':
        return 'Building Management';
      case 'change-password':
        return null; // No app bar for change password screen
      default:
        return '';
    }
  };

  // Get permissions for current role
  const permissions = getPermissions(role);

  const showResidenceSwitcher = currentScreen === 'home';
  const showSearch = currentScreen === 'documents' || currentScreen === 'maintenance';

  return (
    <LanguageProvider>
      <div className="min-h-screen bg-surface-warm-50">
        {/* Navigation Direction Indicator */}
        <NavigationIndicator direction={navigationDirection} />
      
      {/* App Bar - Hidden on Change Password screen */}
      {currentScreen !== 'change-password' && (
        <AppBar
          title={getScreenTitle() || undefined}
          variant={currentScreen === 'home' ? 'branded' : 'default'}
          showResidenceSwitcher={showResidenceSwitcher}
          currentResidence={currentResidence}
          onResidenceSwitch={() => console.log('Switch residence')}
          showSearch={showSearch && currentScreen !== 'ai' && currentScreen !== 'chat' && currentScreen !== 'notifications'}
          onSearch={() => console.log('Search')}
          showNotifications={currentScreen !== 'ai' && currentScreen !== 'chat' && currentScreen !== 'notifications'}
          notificationCount={notificationCount}
          onNotifications={handleNotifications}
          canGoBack={canGoBack}
          onBack={handleBack}
          canGoForward={canGoForward}
          onForward={handleForward}
        />
      )}

      {/* Building Selector - Show on relevant screens for admins */}
      {role === 'admin' && 
       (currentScreen === 'home' || currentScreen === 'documents' || currentScreen === 'maintenance' || 
        currentScreen === 'tickets' || currentScreen === 'analytics' || currentScreen === 'users' || 
        currentScreen === 'buildings') && (
        <BuildingSelector
          role={role}
          currentBuilding={currentBuilding}
          buildings={role === 'admin' ? buildings : undefined}
          onBuildingChange={(buildingId) => {
            const building = buildings.find(b => b.id === buildingId);
            if (building) setCurrentBuilding(building);
          }}
        />
      )}

      {/* Main Content */}
      <main className="relative">
        {currentScreen === 'home' && (
          <HomeScreen
            role={role}
            firstName="Marco"
            fullName={userName}
            residenceStatus={residenceStatus}
            onNavigate={handleNavigate}
          />
        )}

        {currentScreen === 'documents' && (
          <DocumentsScreen role={role} onAskAI={() => handleNavigate('ai')} />
        )}

        {currentScreen === 'maintenance' && (
          <MaintenanceScreen
            role={role}
            onAskAI={() => handleNavigate('ai')}
          />
        )}

        {currentScreen === 'ai' && <AIScreen />}

        {currentScreen === 'hub' && (
          <HubScreen role={role} onNavigate={handleNavigate} />
        )}

        {currentScreen === 'aichat' && <AIScreen />}

        {currentScreen === 'tickets' && <TicketsScreen role={role} />}

        {currentScreen === 'chat' && <ChatScreen role={role} />}

        {currentScreen === 'smarthome' && <SmartHomeScreen role={role} />}

        {currentScreen === 'profile' && (
          <ProfileScreen role={role} onLogout={handleLogout} onNavigate={handleNavigate} />
        )}

        {currentScreen === 'notifications' && (
          <NotificationsScreen onNavigate={handleNavigate} />
        )}

        {currentScreen === 'analytics' && permissions.canAccessAnalytics && (
          <AnalyticsScreen role={role} />
        )}

        {currentScreen === 'users' && permissions.canViewUserList && (
          <UserManagementScreen role={role} />
        )}

        {currentScreen === 'buildings' && permissions.canManageBuildings && (
          <BuildingManagementScreen role={role} />
        )}

        {currentScreen === 'change-password' && (
          <ChangePasswordScreen 
            onBack={() => handleNavigate('profile')}
            onSuccess={() => handleNavigate('profile')}
          />
        )}
      </main>

      {/* Bottom Navigation - Hidden on Notifications and Change Password screens */}
      {currentScreen !== 'notifications' && currentScreen !== 'change-password' && (
        <BottomNav
          activeTab={currentScreen}
          role={role}
          onTabChange={(tab) => handleNavigate(tab)}
        />
      )}

      {/* Toast Notifications */}
      <Toaster />

      {/* Demo Controls - Only visible when authenticated */}
      <DemoControls
        currentRole={role}
        onRoleChange={setRole}
        residenceStatus={residenceStatus}
        onResidenceStatusChange={setResidenceStatus}
      />
      </div>
    </LanguageProvider>
  );
}
