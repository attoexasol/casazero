import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'en_US': enUS, 'it_IT': itIT};

  // Translation key constants for easy access
  static const String trustedDevices = 'trusted_devices';
  static const String manageYourDevices = 'manage_your_devices';
  static const String trustedDevicesInfo = 'trusted_devices_info';
  static const String currentDevice = 'current_device';
  static const String lastActive = 'last_active';
  static const String recentActivity = 'recent_activity';
  static const String removeDevice = 'remove_device';
  static const String confirmRemoveDevice = 'confirm_remove_device';
  static const String removeDeviceMessage = 'remove_device_message';
  static const String cancel = 'cancel';
  static const String remove = 'remove';
  static const String noTrustedDevices = 'no_trusted_devices';
  static const String noTrustedDevicesDesc = 'no_trusted_devices_desc';

  // English Translations
  static const Map<String, String> enUS = {
    // Common
    'app_name': 'CasaZero',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'warning': 'Warning',
    'info': 'Info',
    'confirmation': 'Confirmation',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'back': 'Back',
    'next': 'Next',
    'skip': 'Skip',
    'done': 'Done',
    'ok': 'OK',
    'yes': 'Yes',
    'no': 'No',
    'select': 'Select',
    'setup': 'Setup',

    // Auth Screen
    'smart_living': 'Smart Living Solutions',
    'email': 'Email',
    'email_placeholder': 'your.email@example.com',
    'password': 'Password',
    'forgot_password': 'Forgot password?',
    'sign_in': 'Sign In',
    'sign_out': 'Sign Out',
    'demo_mode': 'Development Version',
    'copyright':
        'Â© 2025 CasaZero Developed by AttoExa Solutions. All rights reserved.',
    'password_reset_sent': 'Password reset link sent',
    'check_email': 'Check your email for reset instructions',
    'login_failed': 'Login Failed',
    'invalid_credentials': 'Invalid credentials',
    'enter_email_password': 'Please enter email and password',
    'enter_email': 'Please enter your email',
    'failed_reset_email': 'Failed to send reset email',
    'reset_password': 'Reset Password',
    'reset_password_description': 'Enter your email and create a new password',
    'create_new_password': 'Create a new password for your account',
    'email_not_found': 'Email not found. Please try again.',
    'user_id_not_found': 'User ID not found. Please try again.',
    'password_reset_successful': 'Password reset successfully',
    'password_reset_failed': 'Failed to reset password. Please try again.',
    'sent_to_phone': 'Sent to phone',
    'sent_to_email': 'Sent to email',

    'verify_continue': 'Verify and Continue',
    // First Login Setup
    'first_login_setup': 'First-Time Setup',
    'secure_your_account':
        'Secure your account with a new password and two-factor authentication',
    'change_password': 'Change Password',
    'two_factor_auth': 'Two-Factor Authentication',
    'create_strong_password': 'Create a strong, unique password',
    'first_login_password_change':
        'For security reasons, you must change your password on first login',
    'current_password': 'Current Password',
    'new_password': 'New Password',
    'confirm_password': 'Confirm New Password',
    'passwords_no_match': 'Passwords do not match',
    'passwords_match': 'Passwords match',
    'password_requirements': 'Password Requirements:',
    'password_length': 'At least 8 characters',
    'password_uppercase': 'Contains uppercase letter',
    'password_lowercase': 'Contains lowercase letter',
    'password_number': 'Contains number',
    'password_special': 'Contains special character',
    'valid_password': 'Valid password! Ready to continue',
    'continue_to_2fa': 'Continue to 2FA Setup',
    'complete_fields': 'Complete all fields and meet password requirements',
    'add_extra_security': 'Add an extra layer of security',
    '2fa_recommended':
        'Two-factor authentication is highly recommended for protecting your account',
    'enable_2fa': 'Enable Two-Factor Authentication',
    '2fa_description':
        'Require a verification code from your phone when signing in',
    'qr_code_placeholder': 'QR Code',
    'scan_qr_code': 'Scan this QR code with your authenticator app',
    'verification_code': 'Verification Code',
    'enter_code_from_app': 'Enter the 6-digit code from your authenticator app',
    'complete_setup': 'Complete Setup',
    'skip_for_now': 'Skip for now',
    'enter_current_password': 'Please enter your current password',
    'enter_new_password': 'Please enter and confirm your new password',
    'password_requirements_not_met': 'Password does not meet all requirements',
    'password_changed': 'Password changed successfully',
    'enter_verification_code': 'Please enter the 6-digit verification code',
    '2fa_enabled': 'Two-factor authentication enabled successfully',
    'complete': 'Complete',

    // Home Screen
    'home': 'Home',
    'home_page': 'Home Page',
    'residence': 'Residence',
    'failed_to_load_residences': 'Failed to load residences',
    'no_residences_available': 'No residences available',
    'failed_to_load_home_data': 'Failed to load home data',
    'failed_to_logout': 'Failed to logout',
    'failed_to_pick_file': 'Failed to pick file',
    'please_select_due_date_first': 'Please select due date first',
    'please_select_residence': 'Please select a residence',
    'maintenance_created_successfully': 'Maintenance created successfully',
    'task_reverted_successfully': 'Task reverted to pending successfully',
    'task_marked_completed_successfully': 'Task marked as completed successfully',
    'failed_to_update_task_status': 'Failed to update task status',
    'failed_to_schedule_visit': 'Failed to schedule visit',
    'schedule_updated_successfully': 'Schedule updated successfully',
    'failed_to_update_schedule': 'Failed to update schedule',
    'maintenance_deleted_successfully': 'Maintenance deleted successfully',
    'failed_to_open_dialer': 'Failed to open dialer. Please call manually.',
    'good_night_scene_activated': 'Good Night scene activated',
    'good_morning_scene_activated': 'Good Morning scene activated',
    'leaving_home_scene_activated': 'Leaving Home scene activated',
    'welcome': 'Welcome,',
    'construction_progress': 'Construction Progress',
    'your_home_is_being_built': 'Your new home is taking shape',
    'view_all_buildings': 'View All Buildings',
    'latest_notifications': 'Latest Notifications',
    'analytics': 'Analytics',
    'residents': 'Residents',
    'building': 'Building',
    'residence_insights_desc': 'View insights',
    'manage_community_desc': 'Manage community',
    'manage_buildings_desc': 'Manage properties',
    'no_notifications': 'No notifications',
    'whats_new': "What's new:",
    'ai_document_analysis': 'CasaZero AI now supports document analysis!',

    // Construction Status
    'completed': 'Completed',
    'in_progress': 'In Progress',
    'pending': 'Pending',
    'percent_complete': '% Complete',

    // Feed Item Types
    'maintenance': 'Maintenance',
    'document': 'Document',
    'announcement': 'Announcement',

    // Time Ago
    'years_ago': 'years ago',
    'months_ago': 'months ago',
    'days_ago': 'days ago',
    'hours_ago': 'hours ago',
    'minutes_ago': 'minutes ago',
    'just_now': 'Just now',

    // Status
    'active': 'Active',
    'inactive': 'Inactive',
    'under_construction': 'Under Construction',

    // Errors
    'something_went_wrong': 'Something went wrong',
    'network_error': 'Network error. Please try again.',
    'failed_to_load_devices': 'Failed to load devices',
    'device_removed_successfully': 'Device removed successfully',
    'failed_to_remove_device': 'Failed to remove device',
    'delete_functionality_coming_soon': 'Delete functionality coming soon',
    'viewDocument': 'View Document',
    'connection_timeout':
        'Connection timeout. Please check your internet connection.',

    // ---------------- PROFILE ----------------
    "profile": "Profile",
    "member_since": "Member since",
    "contact_info": "Contact Information",
    "phone_number": "Phone Number",
    "phone": "Phone",

    // User Roles
    "administrator": "Administrator",
    "manager": "Manager",
    "resident": "Resident",

    // Profile Edit
    "edit_profile": "Edit Profile",
    "first_name": "First Name",
    "last_name": "Last Name",
    "update_personal_info": "Update your personal information",
    "save_changes": "Save",
    "please_enter_your_name": "Please enter your name",
    "please_enter_email": "Please enter your email",
    "please_enter_phone_number": "Please enter your phone number",

    // Residence
    "residence_title": "Residence",
    "address": "Address",
    "unit": "Unit",
    "No_Residence": "No Residence",

    // Security
    "security": "Security",
    "document_password": "Document Password",
    "document_password_description": "Set a password to protect your documents",
    "new_password_required": "New password is required",
    "confirm_password_required": "Please confirm your password",
    "passwords_do_not_match": "Passwords do not match",
    "document_password_saved": "Document password saved successfully",
    "failed_to_save_document_password": "Failed to save document password",
    'cancel_logout': 'Cancel and Logout',

    // Trusted Devices
    "trusted_devices": "Trusted Devices",
    "manage_your_devices": "Manage your trusted devices",
    "trusted_devices_info":
        "These are the devices that have been verified to access your account. Remove any devices you don't recognize.",
    "current_device": "Current Device",
    "last_active": "Last active",
    "recent_activity": "Details",
    "remove_device": "Remove Device",
    "confirm_remove_device": "Remove Device?",
    "remove_device_message":
        "Are you sure you want to remove this device? You'll need to verify it again on next login.",
    "remove": "Remove",
    "no_trusted_devices": "No Trusted Devices",
    "no_trusted_devices_desc":
        "Your trusted devices will appear here after logging in from different devices.",
    "trusted_devices_info_title": "Manage Your Trusted Devices",
    "trusted_devices_info_desc":
        "These devices have access to your account. You can remove any device you don't recognize.",
    "remove_device_title": "Remove Device?",

    // Notifications
    "notification_preferences": "Notification Preferences",
    "manage_push_settings": "Manage push notification settings",
    "notification_desc": "Manage push notification settings",
    "documents": "Documents",
    "maintenance_notif": "Maintenance",
    "chat_messages": "Chat Messages",
    "support_tickets": "Support Tickets",

    // Admin
    "admin_settings": "Admin Settings",
    "management_options": "Management options",
    "building_management": "Building Management",
    "user_management": "User Management",
    "system_configuration": "System Configuration",

    // Preferences
    "preferences": "Preferences",
    "language": "Language",
    "reset_first_login": "Reset First Login",

    // Logout
    "logout": "Logout",
    "confirm_logout": "Confirm Logout",
    "logout_message": "Are you sure you want to logout?",
    "are_you_sure_logout": "Are you sure you want to logout?",

    // Save Settings
    "save_settings": "Save Settings",
    "saving": "Saving...",
    "settings_saved_successfully": "Settings saved successfully!",
    "failed_to_save_settings": "Failed to save settings",
    "error_saving_settings": "Error saving settings. Please try again.",
    "no_user_data": "No user data found",
    "profile_updated_successfully": "Profile updated successfully!",
    "failed_to_update_profile": "Failed to update profile",
    "error_updating_profile": "Error updating profile. Please try again.",

    // Profile Screen
    'account': 'Account',
    'personal_info': 'Personal Information',
    'email_address': 'Email Address',
    'role': 'Role',
    'settings': 'Settings',
    'notifications': 'Notifications',
    'logout_confirmation': 'Are you sure you want to logout?',

    // 2FA General
    'select_2fa_method': 'Select 2FA Method',
    'change_2fa_method': 'Change 2FA Method',
    'deactivate_2fa': 'Deactivate 2FA',
    'verify_your_identity': 'Verify Your Identity',
    '2fa_is_active': '2FA is Active',
    'current_method': 'Current Method',
    'choose_verification_method':
        'Choose how you want to receive verification codes',
    'change_method_subtitle': 'Switch to a different authentication method',
    'deactivate_subtitle': 'Disable two-factor authentication',

    // 2FA Setup Steps
    'scan_qr_code_title': 'Scan QR Code',
    'or_enter_manually': 'Or enter this code manually:',
    'setup_step_1': '1. Open your authenticator app',
    'setup_step_2': '2. Scan the QR code above',
    'setup_step_3': '3. Enter the 6-digit code below',
    'qr_code_error': 'QR code error',
    'verification_code_sent_on_verify':
        'A verification code will be sent when you tap Verify below',

    // Verification
    'enter_code_from_authenticator':
        'Enter the code from your authenticator app',
    'code_sent_to': 'A verification code has been sent to {contact}',

    // Buttons
    'verify_and_activate': 'Verify and Activate',
    'verify_and_deactivate': 'Verify and Deactivate',
    'continue': 'Continue',
    'deactivate': 'Deactivate',

    // 2FA Activation Screen
    'enhance_account_security': 'Enhance your account security',
    'two_factor_info':
        'Two-factor authentication adds an extra layer of security to your account by requiring a verification code in addition to your password.',
    'authenticator_app': 'Authenticator App',
    'authenticator_app_desc': 'Use an app like Google Authenticator or Authy',
    'sms_verification': 'SMS Verification',
    'sms_verification_desc': 'Receive codes via text message',
    'email_verification': 'Email Verification',
    'email_verification_desc': 'Receive codes via email',
    'recommended': 'Recommended',
    'most_secure': 'Most secure method',
    'scan_qr_instructions':
        'Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.) or enter the key manually.',
    'manual_entry_key': 'Manual Entry Key',
    'copied_to_clipboard': 'Copied to clipboard',
    'secret_copied': 'Secret key copied to clipboard',
    'send_code': 'Send Code',
    'enter_authenticator_code':
        'Enter the 6-digit code from your authenticator app',
    'enter_sms_code': 'Enter the code sent to your phone',
    'enter_email_code': 'Enter the code sent to your email',
    'resend_code': 'Resend Code',
    'verify': 'Verify',
    'two_factor_success_message':
        'Your account is now protected with two-factor authentication',
    'sms_sent': 'SMS code sent successfully',
    'email_sent': 'Email code sent successfully',
    'sms_setup_desc': 'We will send a verification code to your phone number',
    'email_setup_desc': 'We will send a verification code to your email',
    'verification_code_sent_to':
        'The verification code will be sent to this contact',
    'sms_2fa_instructions':
        'A verification code will be sent to your registered phone number',
    'email_2fa_instructions':
        'A verification code will be sent to your registered email address',

    // 2FA Deactivation
    'deactivation_warning':
        'Are you sure you want to deactivate Two-Factor Authentication? This will make your account less secure. You will need to verify your identity.',
    'verify_identity_to_deactivate':
        'Enter verification code to deactivate 2FA',
    'security_warning': 'Security Warning',
    'security_risks': 'Security Risks',
    'deactivating_will_result': 'Deactivating 2FA will result in:',
    'risk_unauthorized_access': 'Increased risk of unauthorized access',
    'risk_account_takeover': 'Higher vulnerability to account takeover',
    'risk_data_breach': 'Reduced protection against data breaches',
    'risk_identity_theft': 'Greater exposure to identity theft',
    'understand_risks': 'I understand the risks and want to proceed',
    'enter_code_to_confirm':
        'Enter your verification code to confirm deactivation',
    'open_authenticator_app': 'Open your authenticator app for the code',

    // OTP Verification Screen - English Translations
    'verify_identity': 'Verify Your Identity',
    'email_authentication': 'Email Authentication',
    'sms_authentication': 'SMS Authentication',
    'two_factor_authentication': 'Two-Factor Authentication',
    'otp_email_instruction':
        'We\'ve sent a 6-digit verification code to your email',
    'otp_sms_instruction':
        'We\'ve sent a 6-digit verification code to your phone number',
    'otp_authenticator_instruction':
        'Open your authenticator app and enter the 6-digit code',
    'otp_verification_instruction':
        'Enter the 6-digit verification code to continue',
    'enter_otp_code': 'Please enter the verification code',
    'otp_must_be_6_digits': 'Verification code must be 6 digits',
    'invalid_otp_code': 'Invalid verification code. Please try again',
    'failed_to_send_otp': 'Failed to send verification code',
    'please_wait_before_resend':
        'Please wait {seconds} seconds before requesting a new code',
    'cancel_verification': 'Cancel Verification',
    'cancel_verification_message':
        'Are you sure you want to cancel? You will be logged out.',

    'two_factor_deactivated': '2FA Deactivated',
    'two_factor_deactivated_message':
        'Two-factor authentication has been disabled for your account',
    'reactivate_anytime': 'You can reactivate 2FA anytime in settings',

    // OTP Resend
    'please_wait_to_resend': 'Please wait {seconds} seconds before resending',

    // Success/Error messages
    '2fa_activated_successfully': '2FA activated successfully',
    '2fa_deactivated_successfully': '2FA deactivated successfully',
    'otp_sent_successfully': 'OTP sent successfully',
    'failed_to_activate_2fa': 'Failed to activate 2FA',
    'failed_to_deactivate_2fa': 'Failed to deactivate 2FA',
    'failed_to_generate_qr': 'Failed to generate QR code',
    'failed_to_update_2fa_status': 'Failed to update 2FA status',
    'user_not_found': 'User not found',
    'please_select_2fa_method': 'Please select a 2FA method',
    'verification_code_sent': 'Verification code sent',
    'enter_phone_number': 'Please enter your phone number',

    // Info messages
    '2fa_adds_security': '2FA adds an extra layer of security to your account',
    'enable_2fa_for_security': 'Enable 2FA to add an extra layer of security',

    // ---------------- DOCUMENTS SCREEN ----------------
    'searchDocuments': 'Search documents...',
    'allCategories': 'All Categories',
    'myDocuments': 'My Documents',
    'ownershipLegal': 'Ownership & Legal',
    'technicalBuilding': 'Technical & Building',
    'energyEnvironmental': 'Energy & Environmental',
    'complianceSafety': 'Compliance & Safety',
    'administrativeMaintenance': 'Administrative & Maintenance',
    'noDocumentsFound': 'No documents found',
    'tryAdjustingSearch': 'Try adjusting your search',
    'noDocumentsYet': 'No documents yet',
    'adminWillUpload': 'Your admin will upload documents here',
    'addDocument': 'Add Document',
    'title': 'Title',
    'description': 'Description',
    'upload': 'Upload',
    'downloadDocument': 'Download Document',
    'downloading': 'Downloading...',
    'downloadComplete': 'Download Complete',
    'downloadFailed': 'Download Failed',
    'downloadSuccess': 'Document downloaded successfully',
    'downloadError': 'Failed to download document',
    'enter_6_digit_code': 'Enter 6-digit code',

    // OPEN FILE KEYS  ← ADD HERE
    'openFile': 'Open',
    'openFileFailed': 'Failed to Open File',
    'openFileError': 'Could not open file',
    'fileNotFound': 'File not found on device',
    'noAppToOpen': 'No app available to open this file type',
    'openWith': 'Open With',
    'fileDownloadedSuccessfully': 'File downloaded successfully: {fileName}',
    'fileNotFoundInStorage': 'File not found in local storage. Please download again.',
    'fileEmptyPleaseDownloadAgain': 'File is empty. Please download again.',
    'fileNotSavedCorrectly': 'File was not saved correctly. Please try again.',
    'noFileDataReceived': 'No file data received from server',
    'invalidDocumentId': 'Invalid document ID',
    'anErrorOccurred': 'An error occurred',
    'documentUrlNotAvailable': 'Document URL is not available',
    'deleteFailed': 'Delete Failed',
    'documentDeleted': 'Document Deleted',
    'failedToDeleteDocument': 'Failed to delete document',
    'errorDeletingDocument': 'An error occurred while deleting the document',
    'documentDeletedSuccessfully': '{title} has been deleted successfully',
    'failedToFetchCategories': 'Failed to fetch categories',
    'errorFetchingCategories': 'An error occurred while fetching categories',
    'failedToFetchDocuments': 'Failed to fetch documents',
    'errorFetchingDocuments': 'An error occurred while fetching documents',
    'invalidDocumentCategorySelected': 'Invalid document category selected',

    'permissionDenied': 'Permission Denied',
    'permissionDeniedMessage':
        'Storage permission is required to download files',
    'openSettings': 'Open Settings',

    // ADD DOCUMENT DIALOG - NEW KEYS
    'optional': 'Optional',
    'documentType': 'Document Type',
    'selectType': 'Select type',
    'documentTitlePlaceholder': 'Enter document title',
    'documentDescPlaceholder': 'Add notes or description',
    'clickToUpload': 'Click to upload file',
    'dragDropHint': 'or drag and drop here',
    'supportedFormats': 'Supported formats: PDF, DOC, DOCX, JPG, PNG',
    'filePickError': 'Error selecting file',
    'documentUploadSuccess': 'Document uploaded successfully',
    'documentUploadError': 'Error uploading document',
    'uploading': 'Uploading...',

    // ---------------- MAINTENANCE SCREEN ----------------
    'all': 'All',
    'facoltative': 'Optional',
    'obbligatorie': 'Mandatory',
    'condominiali': 'Condominium',
    'personal': 'Personal',
    'maintenanceTasks': 'Maintenance Tasks',
    'tasksDueOrOverdue': 'tasks due or overdue',
    'pendingStatus': 'Pending',
    'inProgressStatus': 'In Progress',
    'completedStatus': 'Completed',
    'overdueStatus': 'Overdue',
    'lockedStatus': 'Locked',
    'unlockedStatus': 'Unlocked',
    'frequency': 'Frequency',
    'nextDue': 'Next Due',
    'lastCompleted': 'Last Completed',
    'dueDateLabel': 'Due Date',
    'due': 'Due',
    'startDate': 'Due Date',
    'endDate': 'End Date',
    'lastMaintenanceLabel': 'Last Maintenance',
    'fullDescription': 'Full Description',
    'attachments': 'Attachments',
    'contacts': 'Contacts',
    'itemName': 'Item Name',
    'company': 'Company',
    'recommendedCompany': 'Recommended Company',
    'markComplete': 'Mark Complete',
    'revertBack': 'Revert Back',
    'scheduleVisit': 'Schedule',
    'askAI': 'Ask AI',
    'viewDetails': 'View Details',
    // Frequency mappings for API values
    'frequencyWeekly': 'Weekly',
    'frequencyMonthly': 'Monthly',
    'frequencyQuarterly': 'Quarterly',
    'frequencyEvery6Months': 'Every 6 months',
    'frequencyAnnually': 'Annually',
    'frequencyEvery3Months': 'Every 3 months',
    'frequencyEvery12Months': 'Every 12 months',
    'frequencyEvery18Months': 'Every 18 months',
    'frequencyOneTime': 'One-time project',
    'noDescriptionAvailable': 'No description available',
    'createTask': 'Create Task',
    'createMaintenanceTask': 'Create Maintenance Task',
    'createTaskDescription': 'Create a personal maintenance task to track',
    'titleLabel': 'Title',
    'titlePlaceholder': 'e.g., Filter replacement',
    'categoryLabel': 'Category',
    'selectCategory': 'Select category',
    'appliances': 'Appliances',
    'hvac': 'HVAC',
    'plumbing': 'Plumbing',
    'electrical': 'Electrical',
    'cleaning': 'Cleaning',
    'other': 'Other',
    'frequencyLabel': 'Frequency',
    'selectFrequency': 'Select frequency',
    'weekly': 'Weekly',
    'monthly': 'Monthly',
    'quarterly': 'Quarterly',
    'biannually': 'Every 6 months',
    'annually': 'Annually',
    'custom': 'Custom',
    'notesOptional': 'Notes (Optional)',
    'addDetails': 'Add any additional details...',
    'attachmentOptional': 'Attachment (Optional)',
    'attachFile': 'Attach file or photo',
    'create': 'Create',
    'noMaintenanceTasks': 'No Maintenance Tasks',
    'createFirstTask': 'Create your first maintenance task to get started',

    // ---------------- AI SCREEN ----------------
    'casaZeroAI': 'CasaZero AI',
    'yourIntelligentAssistant': 'Your intelligent assistant',
    'askAnything': 'Ask me anything about your home...',
    'recentTickets': 'Recent Support Tickets',
    'viewAllTickets': 'View All Tickets',
    'exampleQuestions': 'Example Questions:',
    'energyCategory': 'Energy',
    'documentsCategory': 'Documents',
    'maintenanceCategory': 'Maintenance',
    'open': 'Open',
    'resolved': 'Resolved',

    // ---------------- SMART HOME SCREEN ----------------
    'smartHome': 'Smart Home',
    'devicesActive': 'devices active',
    'roomAll': 'All Rooms',
    'roomLiving': 'Living Room',
    'roomBedroom': 'Bedroom',
    'roomKitchen': 'Kitchen',
    'roomEntrance': 'Entrance',
    'deviceOn': 'On',
    'deviceOff': 'Off',
    'deviceLocked': 'Locked',
    'deviceUnlocked': 'Unlocked',
    'brightness': 'Brightness',
    'position': 'Position',
    'temperature': 'Temperature',
    'quickActions': 'Quick Actions',
    'commonScenarios': 'Common scenarios',
    'goodNight': 'Good Night',
    'turnOffAllLights': 'Turn off all lights',
    'goodMorning': 'Good Morning',
    'turnOnAllLights': 'Turn on all lights',
    'leavingHome': 'Leaving Home',
    'lockAllDoors': 'Lock all doors',
    'outside': 'Outside',
    'humidity': 'Humidity',
    'viewOnlyMode':
        'View-only mode. Contact your administrator for device control access.',
    'goodNightActivated': 'Good Night scene activated',
    'goodMorningActivated': 'Good Morning scene activated',
    'leavingHomeActivated': 'Leaving Home scene activated',

    // ---------------- HUB SCREEN ----------------
    'exploreFeatures':
        'Explore all the intelligent features of CasaZero to manage your home',
    'domotica': 'Smart Home',
    'chatCondominio': 'Condominium Chat',
    'assistenza': 'Support',

    // 2FA Deactivation - Security Warnings
    // 'security_warning': 'Security Warning',
    'deactivate_two_factor_warning':
        'Deactivating two-factor authentication will significantly reduce the security of your account. Please consider the risks before proceeding.',

    // Security Risks
    //     'security_risks': 'Security Risks',
    //     'deactivating_will_result': 'Deactivating two-factor authentication will result in:',
    'increase_vulnerability': 'Increased Vulnerability',
    'increase_vulnerability_desc':
        'Your account becomes more susceptible to unauthorized access and cyber attacks.',
    'unauthorized_access': 'Unauthorized Access',
    'unauthorized_access_desc':
        'Without 2FA, anyone with your password can access your account.',
    'data_breach_risk': 'Data Breach Risk',
    'data_breach_risk_desc':
        'Higher likelihood of sensitive information being compromised.',
    'identity_theft': 'Identity Theft',
    'identity_theft_desc':
        'Increased risk of your personal information being stolen and misused.',

    // Better Alternatives
    'better_alternatives': 'Better Alternatives',
    'alternative_switch_method':
        'Switch to a different 2FA method (SMS, Email, Authenticator)',
    'alternative_update_backup': 'Update your backup codes or recovery options',
    'alternative_contact_support':
        'Contact support if you\'re having issues with 2FA',

    // Deactivation Actions
    'continue_deactivation': 'Continue with Deactivation',
    'confirm_deactivation': 'Confirm Deactivation',
    'confirm_deactivation_message':
        'This action will remove two-factor authentication from your account. You can re-enable it at any time, but your account will be less secure until you do.',
    'proceed': 'Proceed',
    // 'deactivate': 'Deactivate',
    'deactivate_two_factor': 'Deactivate Two-Factor Authentication',
    'verify_to_deactivate': 'Verify to deactivate',

    // Verification Step
    //     'verify_identity_to_deactivate': 'For security, please verify your identity to deactivate 2FA',
    'enter_current_two_factor_code':
        'Enter the current 6-digit code from your two-factor authentication method',
    'verifying': 'Verifying...',
    'invalid_o_t_p': 'Invalid verification code. Please try again.',
    'verification_failed':
        'Verification failed. Please check your code and try again.',

    // Success State
    //     'two_factor_deactivated': 'Two-Factor Authentication Deactivated',
    //     'two_factor_deactivated_message': 'Your account is now less secure. We strongly recommend re-enabling 2FA as soon as possible.',
    //     'reactivate_anytime': 'You can reactivate 2FA anytime in Security settings',
  };

  // ============================================================================
  // ITALIAN TRANSLATIONS
  // ============================================================================
  static const Map<String, String> itIT = {
    // Common
    'app_name': 'CasaZero',
    'loading': 'Caricamento...',
    'error': 'Errore',
    'success': 'Successo',
    'warning': 'Avviso',
    'info': 'Informazione',
    'confirmation': 'Conferma',
    'cancel': 'Annulla',
    'confirm': 'Conferma',
    'save': 'Salva',
    'delete': 'Elimina',
    'edit': 'Modifica',
    'back': 'Indietro',
    'next': 'Avanti',
    'skip': 'Salta',
    'done': 'Fatto',
    'ok': 'OK',
    'yes': 'Sì',
    'no': 'No',
    'select': 'Seleziona',
    'setup': 'Configura',

    // Auth Screen
    'smart_living': 'Soluzioni Smart Living',
    'email': 'Email',
    'email_placeholder': 'tua.email@esempio.com',
    'password': 'Password',
    'forgot_password': 'Password dimenticata?',
    'sign_in': 'Accedi',
    'sign_out': 'Esci',
    'demo_mode': 'Versione di Sviluppo',
    'copyright':
        'Â© 2025 CasaZero Sviluppato da AttoExa Solutions. Tutti i diritti riservati.',
    'password_reset_sent': 'Link di reset password inviato',
    'check_email': 'Controlla la tua email per le istruzioni di reset',
    'login_failed': 'Accesso Fallito',
    'invalid_credentials': 'Credenziali non valide',
    'enter_email_password': 'Inserisci email e password',
    'enter_email': 'Inserisci la tua email',
    'failed_reset_email': 'Impossibile inviare email di reset',
    'reset_password': 'Reimposta Password',
    'reset_password_description':
        'Inserisci la tua email e crea una nuova password',
    'create_new_password': 'Crea una nuova password per il tuo account',
    'email_not_found': 'Email non trovata. Riprova.',
    'user_id_not_found': 'ID utente non trovato. Riprova.',
    'password_reset_successful': 'Password reimpostata con successo',
    'password_reset_failed': 'Impossibile reimpostare la password. Riprova.',

    // Profile
    "profile": "Profilo",
    "member_since": "Membro da",
    "contact_info": "Informazioni di Contatto",
    "phone_number": "Numero di Telefono",
    "phone": "Telefono",

    // User Roles
    "administrator": "Amministratore",
    "manager": "Manager",
    "resident": "Residente",

    // Profile Edit
    "edit_profile": "Modifica Profilo",
    "first_name": "Nome",
    "last_name": "Cognome",
    "update_personal_info": "Aggiorna le tue informazioni personali",
    "save_changes": "Salva",
    "please_enter_your_name": "Inserisci il tuo nome",
    "please_enter_email": "Inserisci la tua email",
    "please_enter_phone_number": "Inserisci il tuo numero di telefono",

    // Residence
    "residence_title": "Residenza",
    "address": "Indirizzo",
    "unit": "Unità",
    "No_Residence": "Nessuna Residenza",

    // Security
    "security": "Sicurezza",
    "document_password": "Password Documenti",
    "document_password_description": "Imposta una password per proteggere i tuoi documenti",
    "new_password_required": "La nuova password è obbligatoria",
    "confirm_password_required": "Conferma la tua password",
    "passwords_do_not_match": "Le password non corrispondono",
    "document_password_saved": "Password documento salvata con successo",
    "failed_to_save_document_password": "Impossibile salvare la password del documento",

    // Trusted Devices
    "trusted_devices": "Dispositivi Fidati",
    "manage_your_devices": "Gestisci i tuoi dispositivi fidati",
    "trusted_devices_info":
        "Questi sono i dispositivi che sono stati verificati per accedere al tuo account. Rimuovi eventuali dispositivi che non riconosci.",
    "current_device": "Dispositivo Corrente",
    "last_active": "Ultimo accesso",
    "recent_activity": "Dettagli",
    "remove_device": "Rimuovi Dispositivo",
    "confirm_remove_device": "Rimuovere Dispositivo?",
    "remove_device_message":
        "Sei sicuro di voler rimuovere questo dispositivo? Dovrai verificarlo nuovamente al prossimo accesso.",
    "remove": "Rimuovi",
    "no_trusted_devices": "Nessun Dispositivo Fidato",
    "no_trusted_devices_desc":
        "I tuoi dispositivi fidati appariranno qui dopo aver effettuato l'accesso da dispositivi diversi.",
    "trusted_devices_info_title": "Gestisci i Tuoi Dispositivi Fidati",
    "trusted_devices_info_desc":
        "Questi dispositivi hanno accesso al tuo account. Puoi rimuovere qualsiasi dispositivo che non riconosci.",
    "remove_device_title": "Rimuovere Dispositivo?",

    // Notifications
    "notification_preferences": "Preferenze Notifiche",
    "manage_push_settings": "Gestisci le impostazioni delle notifiche push",
    "notification_desc": "Gestisci le impostazioni delle notifiche push",
    "documents": "Documenti",
    "maintenance_notif": "Manutenzione",
    "chat_messages": "Messaggi Chat",
    "support_tickets": "Ticket di Supporto",

    // Admin
    "admin_settings": "Impostazioni Admin",
    "management_options": "Opzioni di gestione",
    "building_management": "Gestione Edifici",
    "user_management": "Gestione Utenti",
    "system_configuration": "Configurazione Sistema",

    // Preferences
    "preferences": "Preferenze",
    "language": "Lingua",
    "reset_first_login": "Reset Primo Accesso",

    // Logout
    "logout": "Esci",
    "confirm_logout": "Conferma Logout",
    "logout_message": "Sei sicuro di voler uscire?",
    "are_you_sure_logout": "Sei sicuro di voler uscire?",

    // Save Settings
    "save_settings": "Salva Impostazioni",
    "saving": "Salvataggio...",
    "settings_saved_successfully": "Impostazioni salvate con successo!",
    "failed_to_save_settings": "Impossibile salvare le impostazioni",
    "error_saving_settings": "Errore nel salvare le impostazioni. Riprova.",
    "no_user_data": "Nessun dato utente trovato",
    "profile_updated_successfully": "Profilo aggiornato con successo!",
    "failed_to_update_profile": "Impossibile aggiornare il profilo",
    "error_updating_profile": "Errore nell'aggiornamento del profilo. Riprova.",

    // Profile Screen
    'account': 'Account',
    'personal_info': 'Informazioni Personali',
    'email_address': 'Indirizzo Email',
    'role': 'Ruolo',
    'settings': 'Impostazioni',
    'notifications': 'Notifiche',
    'logout_confirmation': 'Sei sicuro di voler uscire?',

    // 2FA General
    'select_2fa_method': 'Seleziona Metodo 2FA',
    'change_2fa_method': 'Cambia Metodo 2FA',
    'deactivate_2fa': 'Disattiva 2FA',
    'verify_your_identity': 'Verifica la Tua Identità',
    '2fa_is_active': '2FA è Attivo',
    'current_method': 'Metodo Attuale',
    'choose_verification_method':
        'Scegli come vuoi ricevere i codici di verifica',
    'change_method_subtitle': 'Passa a un metodo di autenticazione diverso',
    'deactivate_subtitle': 'Disabilita l\'autenticazione a due fattori',

    // 2FA Setup Steps
    'scan_qr_code_title': 'Scansiona Codice QR',
    'or_enter_manually': 'Oppure inserisci questo codice manualmente:',
    'setup_step_1': '1. Apri la tua app di autenticazione',
    'setup_step_2': '2. Scansiona il codice QR sopra',
    'setup_step_3': '3. Inserisci il codice a 6 cifre qui sotto',

    // Verification
    'enter_code_from_authenticator':
        'Inserisci il codice dalla tua app di autenticazione',
    'code_sent_to': 'Un codice di verifica è stato inviato a {contact}',

    // Buttons
    'verify_and_activate': 'Verifica e Attiva',
    'verify_and_deactivate': 'Verifica e Disattiva',
    'continue': 'Continua',
    'deactivate': 'Disattiva',

    // 2FA Activation Screen
    'enhance_account_security': 'Migliora la sicurezza del tuo account',
    'two_factor_info':
        'L\'autenticazione a due fattori aggiunge un ulteriore livello di sicurezza al tuo account richiedendo un codice di verifica oltre alla password.',
    'authenticator_app': 'App Authenticator',
    'authenticator_app_desc': 'Usa un\'app come Google Authenticator o Authy',
    'sms_verification': 'Verifica SMS',
    'sms_verification_desc': 'Ricevi codici tramite messaggio di testo',
    'email_verification': 'Verifica Email',
    'email_verification_desc': 'Ricevi codici tramite email',
    'recommended': 'Consigliato',
    'most_secure': 'Metodo più sicuro',
    'scan_qr_instructions':
        'Scansiona questo codice QR con la tua app authenticator (Google Authenticator, Authy, ecc.) o inserisci la chiave manualmente.',
    'manual_entry_key': 'Chiave di Inserimento Manuale',
    'copied_to_clipboard': 'Copiato negli appunti',
    'send_code': 'Invia Codice',
    'enter_authenticator_code':
        'Inserisci il codice a 6 cifre dalla tua app authenticator',
    'enter_sms_code': 'Inserisci il codice inviato al tuo telefono',
    'enter_email_code': 'Inserisci il codice inviato alla tua email',
    'resend_code': 'Reinvia Codice',
    'verify': 'Verifica',
    'two_factor_success_message':
        'Il tuo account è ora protetto con l\'autenticazione a due fattori',
    'sms_sent': 'Codice SMS inviato con successo',
    'email_sent': 'Codice email inviato con successo',
    'sms_setup_desc':
        'Invieremo un codice di verifica al tuo numero di telefono',
    'email_setup_desc': 'Invieremo un codice di verifica alla tua email',
    'verification_code_sent_to':
        'Il codice di verifica verrà inviato a questo contatto',
    'sms_2fa_instructions':
        'Un codice di verifica verrà inviato al tuo numero di telefono registrato',
    'email_2fa_instructions':
        'Un codice di verifica verrà inviato al tuo indirizzo email registrato',

    // 2FA Deactivation
    'deactivation_warning':
        'Sei sicuro di voler disattivare l\'Autenticazione a Due Fattori? Questo renderà il tuo account meno sicuro. Dovrai verificare la tua identità.',
    'verify_identity_to_deactivate':
        'Inserisci il codice di verifica per disattivare 2FA',
    'security_warning': 'Avviso di Sicurezza',
    'security_risks': 'Rischi di Sicurezza',
    'deactivating_will_result': 'La disattivazione del 2FA comporterà:',
    'risk_unauthorized_access':
        'Aumento del rischio di accesso non autorizzato',
    'risk_account_takeover': 'Maggiore vulnerabilità al furto dell\'account',
    'risk_data_breach': 'Ridotta protezione contro le violazioni dei dati',
    'risk_identity_theft': 'Maggiore esposizione al furto d\'identità',
    'understand_risks': 'Comprendo i rischi e voglio procedere',
    'enter_code_to_confirm':
        'Inserisci il tuo codice di verifica per confermare la disattivazione',
    'open_authenticator_app': 'Apri la tua app authenticator per il codice',
    'two_factor_deactivated': '2FA Disattivato',
    'two_factor_deactivated_message':
        'L\'autenticazione a due fattori è stata disabilitata per il tuo account',
    'reactivate_anytime':
        'Puoi riattivare 2FA in qualsiasi momento nelle impostazioni',

    // OTP Resend
    'please_wait_to_resend': 'Attendi {seconds} secondi prima di reinviare',

    // Success/Error messages
    '2fa_activated_successfully': '2FA attivato con successo',
    '2fa_deactivated_successfully': '2FA disattivato con successo',
    'otp_sent_successfully': 'OTP inviato con successo',
    'failed_to_activate_2fa': 'Impossibile attivare 2FA',
    'failed_to_deactivate_2fa': 'Impossibile disattivare 2FA',
    'failed_to_update_2fa_status': 'Impossibile aggiornare lo stato 2FA',
    'user_not_found': 'Utente non trovato',
    'please_select_2fa_method': 'Seleziona un metodo 2FA',

    // Info messages
    '2fa_adds_security':
        '2FA aggiunge un ulteriore livello di sicurezza al tuo account',
    'enable_2fa_for_security':
        'Abilita 2FA per aggiungere un ulteriore livello di sicurezza',

    // First Login Setup (Italian)
    'first_login_setup': 'Configurazione Primo Accesso',
    'secure_your_account':
        'Proteggi il tuo account con una nuova password e l\'autenticazione a due fattori',
    'change_password': 'Cambia Password',
    'two_factor_auth': 'Autenticazione a Due Fattori',
    'create_strong_password': 'Crea una password forte e unica',
    'first_login_password_change':
        'Per motivi di sicurezza, devi cambiare la password al primo accesso',
    'current_password': 'Password Attuale',
    'new_password': 'Nuova Password',
    'confirm_password': 'Conferma Nuova Password',
    'passwords_no_match': 'Le password non corrispondono',
    'passwords_match': 'Le password corrispondono',
    'password_requirements': 'Requisiti Password:',
    'password_length': 'Almeno 8 caratteri',
    'password_uppercase': 'Contiene lettera maiuscola',
    'password_lowercase': 'Contiene lettera minuscola',
    'password_number': 'Contiene numero',
    'password_special': 'Contiene carattere speciale',
    'valid_password': 'Password valida! Pronto per continuare',
    'continue_to_2fa': 'Continua alla Configurazione 2FA',
    'complete_fields':
        'Completa tutti i campi e soddisfa i requisiti della password',
    'add_extra_security': 'Aggiungi un ulteriore livello di sicurezza',
    '2fa_recommended':
        'L\'autenticazione a due fattori Ã¨ altamente consigliata per proteggere il tuo account',
    'enable_2fa': 'Abilita Autenticazione a Due Fattori',
    '2fa_description':
        'Richiedi un codice di verifica dal tuo telefono quando accedi',
    'qr_code_placeholder': 'Codice QR',
    'scan_qr_code': 'Scansiona questo codice QR con la tua app authenticator',
    'verification_code': 'Codice di Verifica',
    'enter_code_from_app':
        'Inserisci il codice a 6 cifre dalla tua app authenticator',
    'complete_setup': 'Completa Configurazione',
    'skip_for_now': 'Salta per ora',
    'enter_current_password': 'Inserisci la tua password attuale',
    'enter_new_password': 'Inserisci e conferma la tua nuova password',
    'password_requirements_not_met':
        'La password non soddisfa tutti i requisiti',
    'password_changed': 'Password cambiata con successo',
    'enter_verification_code': 'Inserisci il codice di verifica a 6 cifre',
    '2fa_enabled': 'Autenticazione a due fattori abilitata con successo',
    'complete': 'Completa',

    // Home Screen (Italian)
    'home': 'Casa',
    'home_page': 'Pagina Iniziale',
    'residence': 'Residenza',
    'failed_to_load_residences': 'Impossibile caricare le residenze',
    'no_residences_available': 'Nessuna residenza disponibile',
    'failed_to_load_home_data': 'Impossibile caricare i dati della home',
    'failed_to_logout': 'Impossibile disconnettersi',
    'failed_to_pick_file': 'Impossibile selezionare il file',
    'please_select_due_date_first': 'Seleziona prima la data di scadenza',
    'please_select_residence': 'Seleziona una residenza',
    'maintenance_created_successfully': 'Manutenzione creata con successo',
    'task_reverted_successfully': 'Attività riportata in sospeso',
    'task_marked_completed_successfully': 'Attività segnata come completata',
    'failed_to_update_task_status': 'Impossibile aggiornare lo stato',
    'failed_to_schedule_visit': 'Impossibile programmare la visita',
    'schedule_updated_successfully': 'Programma aggiornato con successo',
    'failed_to_update_schedule': 'Impossibile aggiornare il programma',
    'maintenance_deleted_successfully': 'Manutenzione eliminata con successo',
    'failed_to_open_dialer': 'Impossibile aprire il telefono. Chiama manualmente.',
    'good_night_scene_activated': 'Scena Buonanotte attivata',
    'good_morning_scene_activated': 'Scena Buongiorno attivata',
    'leaving_home_scene_activated': 'Scena Uscita di casa attivata',
    'welcome': 'Benvenuto,',
    'construction_progress': 'Avanzamento Costruzione',
    'your_home_is_being_built': 'La tua nuova casa sta prendendo forma',
    'view_all_buildings': 'Visualizza Tutti gli Edifici',
    'latest_notifications': 'Ultime Notifiche',
    'analytics': 'Analisi',
    'residents': 'Residenti',
    'building': 'Edificio',
    'residence_insights_desc': 'Visualizza statistiche',
    'manage_community_desc': 'Gestisci la comunità',
    'manage_buildings_desc': 'Gestisci le proprietà',
    'no_notifications': 'Nessuna notifica',
    'whats_new': "Novità:",
    'ai_document_analysis':
        'CasaZero AI ora supporta l\'analisi dei documenti!',

    // Construction Status (Italian)
    'completed': 'Completato',
    'in_progress': 'In Corso',
    'pending': 'In Attesa',
    'percent_complete': '% Completato',

    // Feed Item Types (Italian)
    'maintenance': 'Manutenzione',
    'document': 'Documento',
    'announcement': 'Annuncio',

    // Time Ago (Italian)
    'years_ago': 'anni fa',
    'months_ago': 'mesi fa',
    'days_ago': 'giorni fa',
    'hours_ago': 'ore fa',
    'minutes_ago': 'minuti fa',
    'just_now': 'Proprio ora',

    // Status (Italian)
    'active': 'Attivo',
    'inactive': 'Inattivo',
    'under_construction': 'In Costruzione',

    // Errors (Italian)
    'something_went_wrong': 'Qualcosa è andato storto',
    'network_error': 'Errore di rete. Riprova.',
    'failed_to_load_devices': 'Impossibile caricare i dispositivi',
    'device_removed_successfully': 'Dispositivo rimosso con successo',
    'failed_to_remove_device': 'Impossibile rimuovere il dispositivo',
    'delete_functionality_coming_soon': 'Funzionalità di eliminazione in arrivo',
    'viewDocument': 'Visualizza Documento',
    'connection_timeout':
        'Timeout di connessione. Controlla la tua connessione internet.',

    // ---------------- DOCUMENTS SCREEN (Italian) ----------------
    'searchDocuments': 'Cerca documenti...',
    'allCategories': 'Tutte le Categorie',
    'myDocuments': 'I Miei Documenti',
    'ownershipLegal': 'Proprietà e Legale',
    'technicalBuilding': 'Tecnico ed Edilizio',
    'energyEnvironmental': 'Energia e Ambiente',
    'complianceSafety': 'Conformità e Sicurezza',
    'administrativeMaintenance': 'Amministrativo e Manutenzione',
    'noDocumentsFound': 'Nessun documento trovato',
    'tryAdjustingSearch': 'Prova a modificare la ricerca',
    'noDocumentsYet': 'Nessun documento ancora',
    'adminWillUpload': 'Il tuo amministratore caricherà i documenti qui',
    'addDocument': 'Aggiungi Documento',
    'title': 'Titolo',
    'description': 'Descrizione',
    'upload': 'Carica',
    'downloadDocument': 'Scarica Documento',
    'downloading': 'Download in corso...',
    'downloadComplete': 'Download Completato',
    'downloadFailed': 'Download Fallito',
    'downloadSuccess': 'Documento scaricato con successo',
    'downloadError': 'Impossibile scaricare il documento',

    // OPEN FILE KEYS  ← ADD HERE
    'openFile': 'Apri',
    'openFileFailed': 'Impossibile Aprire File',
    'openFileError': 'Impossibile aprire il file',
    'fileNotFound': 'File non trovato sul dispositivo',
    'noAppToOpen': 'Nessuna app disponibile per aprire questo tipo di file',
    'openWith': 'Apri con',
    'fileDownloadedSuccessfully': 'File scaricato con successo: {fileName}',
    'fileNotFoundInStorage': 'File non trovato nella memoria locale. Scarica di nuovo.',
    'fileEmptyPleaseDownloadAgain': 'Il file è vuoto. Scarica di nuovo.',
    'fileNotSavedCorrectly': 'Il file non è stato salvato correttamente. Riprova.',
    'noFileDataReceived': 'Nessun dato del file ricevuto dal server',
    'invalidDocumentId': 'ID documento non valido',
    'anErrorOccurred': 'Si è verificato un errore',
    'documentUrlNotAvailable': 'URL del documento non disponibile',
    'deleteFailed': 'Eliminazione Fallita',
    'documentDeleted': 'Documento Eliminato',
    'failedToDeleteDocument': 'Impossibile eliminare il documento',
    'errorDeletingDocument': 'Si è verificato un errore durante l\'eliminazione del documento',
    'documentDeletedSuccessfully': '{title} è stato eliminato con successo',
    'failedToFetchCategories': 'Impossibile recuperare le categorie',
    'errorFetchingCategories': 'Si è verificato un errore durante il recupero delle categorie',
    'failedToFetchDocuments': 'Impossibile recuperare i documenti',
    'errorFetchingDocuments': 'Si è verificato un errore durante il recupero dei documenti',
    'invalidDocumentCategorySelected': 'Categoria documento non valida selezionata',

    'permissionDenied': 'Permesso Negato',
    'permissionDeniedMessage':
        'È necessario il permesso di archiviazione per scaricare i file',
    'openSettings': 'Apri Impostazioni',

    // ADD DOCUMENT DIALOG - NEW KEYS (ITALIAN)
    'optional': 'Facoltativo',
    'documentType': 'Tipo di Documento',
    'selectType': 'Seleziona tipo',
    'documentTitlePlaceholder': 'Inserisci il titolo del documento',
    'documentDescPlaceholder': 'Aggiungi note o descrizione',
    'clickToUpload': 'Clicca per caricare il file',
    'dragDropHint': 'o trascina e rilascia qui',
    'supportedFormats': 'Formati supportati: PDF, DOC, DOCX, JPG, PNG',
    'filePickError': 'Errore nella selezione del file',
    'documentUploadSuccess': 'Documento caricato con successo',
    'documentUploadError': 'Errore nel caricamento del documento',
    'uploading': 'Caricamento...',

    // ---------------- MAINTENANCE SCREEN (Italian) ----------------
    'all': 'Tutto',
    'facoltative': 'Facoltative',
    'obbligatorie': 'Obbligatorie',
    'condominiali': 'Condominiali',
    'personal': 'Personali',
    'maintenanceTasks': 'Attività di Manutenzione',
    'tasksDueOrOverdue': 'attività in scadenza o scadute',
    'pendingStatus': 'In Attesa',
    'inProgressStatus': 'In Corso',
    'completedStatus': 'Completato',
    'overdueStatus': 'Scaduto',
    'lockedStatus': 'Bloccato',
    'unlockedStatus': 'Sbloccato',
    'frequency': 'Frequenza',
    'nextDue': 'Prossima Scadenza',
    'lastCompleted': 'Ultimo Completato',
    'dueDateLabel': 'Scadenza',
    'due': 'Dovuta',
    'startDate': 'Scadenza',
    'endDate': 'Data Fine',
    'lastMaintenanceLabel': 'Ultima',
    'fullDescription': 'Descrizione Completa',
    'attachments': 'Allegati',
    'contacts': 'Contatti',
    'itemName': 'Nome Articolo',
    'company': 'Azienda',
    'recommendedCompany': 'Azienda Consigliata',
    'markComplete': 'Segna Completato',
    'revertBack': 'Torna indietro',
    'scheduleVisit': 'Programma',
    'askAI': 'Chiedi AI',
    'viewDetails': 'Visualizza Dettagli',
    // Frequency mappings for API values
    'frequencyWeekly': 'Settimanale',
    'frequencyMonthly': 'Mensile',
    'frequencyQuarterly': 'Trimestrale',
    'frequencyEvery6Months': 'Ogni 6 mesi',
    'frequencyAnnually': 'Annuale',
    'frequencyEvery3Months': 'Ogni 3 mesi',
    'frequencyEvery12Months': 'Ogni 12 mesi',
    'frequencyEvery18Months': 'Ogni 18 mesi',
    'frequencyOneTime': 'Progetto una tantum',
    'noDescriptionAvailable': 'Nessuna descrizione disponibile',
    'createTask': 'Crea Attività',
    'createMaintenanceTask': 'Crea Attività di Manutenzione',
    'createTaskDescription':
        'Crea un\'attività di manutenzione personale da tracciare',
    'titleLabel': 'Titolo',
    'titlePlaceholder': 'es., Sostituzione filtri',
    'categoryLabel': 'Categoria',
    'selectCategory': 'Seleziona categoria',
    'appliances': 'Elettrodomestici',
    'hvac': 'HVAC',
    'plumbing': 'Idraulica',
    'electrical': 'Elettrico',
    'cleaning': 'Pulizia',
    'other': 'Altro',
    'frequencyLabel': 'Frequenza',
    'selectFrequency': 'Seleziona frequenza',
    'weekly': 'Settimanale',
    'monthly': 'Mensile',
    'quarterly': 'Trimestrale',
    'biannually': 'Ogni 6 mesi',
    'annually': 'Annuale',
    'custom': 'Personalizzato',
    'notesOptional': 'Note (Opzionale)',
    'addDetails': 'Aggiungi dettagli aggiuntivi...',
    'attachmentOptional': 'Allegato (Opzionale)',
    'attachFile': 'Allega file o foto',
    'create': 'Crea',
    'noMaintenanceTasks': 'Nessuna Attività di Manutenzione',
    'createFirstTask':
        'Crea la tua prima attività di manutenzione per iniziare',

    // ---------------- AI SCREEN (Italian) ----------------
    'casaZeroAI': 'CasaZero AI',
    'yourIntelligentAssistant': 'Il tuo assistente intelligente',
    'askAnything': 'Chiedimi qualsiasi cosa sulla tua casa...',
    'recentTickets': 'Ticket di Supporto Recenti',
    'viewAllTickets': 'Visualizza Tutti i Ticket',
    'exampleQuestions': 'Esempi di Domande:',
    'energyCategory': 'Energia',
    'documentsCategory': 'Documenti',
    'maintenanceCategory': 'Manutenzione',
    'open': 'Aperto',
    'resolved': 'Risolto',

    // ---------------- SMART HOME SCREEN (Italian) ----------------
    'smartHome': 'Casa Intelligente',
    'devicesActive': 'dispositivi attivi',
    'roomAll': 'Tutte le Stanze',
    'roomLiving': 'Soggiorno',
    'roomBedroom': 'Camera da Letto',
    'roomKitchen': 'Cucina',
    'roomEntrance': 'Ingresso',
    'deviceOn': 'Acceso',
    'deviceOff': 'Spento',
    'deviceLocked': 'Bloccato',
    'deviceUnlocked': 'Sbloccato',
    'brightness': 'Luminosità',
    'position': 'Posizione',
    'temperature': 'Temperatura',
    'quickActions': 'Azioni Rapide',
    'commonScenarios': 'Scenari comuni',
    'goodNight': 'Buonanotte',
    'turnOffAllLights': 'Spegni tutte le luci',
    'goodMorning': 'Buongiorno',
    'turnOnAllLights': 'Accendi tutte le luci',
    'leavingHome': 'Uscendo di Casa',
    'lockAllDoors': 'Blocca tutte le porte',
    'outside': 'Esterno',
    'humidity': 'Umidità',
    'viewOnlyMode':
        'Modalità solo visualizzazione. Contatta l\'amministratore per l\'accesso al controllo dei dispositivi.',
    'goodNightActivated': 'Scena Buonanotte attivata',
    'goodMorningActivated': 'Scena Buongiorno attivata',
    'leavingHomeActivated': 'Scena Uscendo di Casa attivata',

    // ---------------- HUB SCREEN (Italian) ----------------
    'exploreFeatures':
        'Esplora tutte le funzionalità intelligenti di CasaZero per gestire la tua casa',
    'domotica': 'Domotica',
    'chatCondominio': 'Chat Condominio',
    'assistenza': 'Assistenza',

    // 2FA Deactivation - Security Warnings
    // 'security_warning': 'Avviso di Sicurezza',
    'deactivate_two_factor_warning':
        'La disattivazione dell\'autenticazione a due fattori ridurrà significativamente la sicurezza del tuo account. Si prega di considerare i rischi prima di procedere.',

    // Security Risks
    //     'security_risks': 'Rischi per la Sicurezza',
    //     'deactivating_will_result': 'La disattivazione dell\'autenticazione a due fattori comporterÃ :',
    'increase_vulnerability': 'Aumento della Vulnerabilità',
    'increase_vulnerability_desc':
        'Il tuo account diventa più suscettibile ad accessi non autorizzati e attacchi informatici.',
    'unauthorized_access': 'Accesso Non Autorizzato',
    'unauthorized_access_desc':
        'Senza 2FA, chiunque conosca la tua password può accedere al tuo account.',
    'data_breach_risk': 'Rischio di Violazione dei Dati',
    'data_breach_risk_desc':
        'Maggiore probabilità che informazioni sensibili vengano compromesse.',
    'identity_theft': 'Furto d\'Identità',
    'identity_theft_desc':
        'Maggiore rischio che le tue informazioni personali vengano rubate e utilizzate in modo improprio.',

    // Better Alternatives
    'better_alternatives': 'Alternative Migliori',
    'alternative_switch_method':
        'Passa a un metodo 2FA diverso (SMS, Email, Authenticator)',
    'alternative_update_backup':
        'Aggiorna i tuoi codici di backup o le opzioni di recupero',
    'alternative_contact_support':
        'Contatta il supporto se hai problemi con 2FA',

    // Deactivation Actions
    'continue_deactivation': 'Continua con la Disattivazione',
    'confirm_deactivation': 'Conferma Disattivazione',
    'confirm_deactivation_message':
        'Questa azione rimuoverà l\'autenticazione a due fattori dal tuo account. Puoi riattivarla in qualsiasi momento, ma il tuo account sarà meno sicuro fino a quando non lo farai.',
    'proceed': 'Procedi',

    'deactivate_two_factor': 'Disattiva Autenticazione a Due Fattori',
    'verify_to_deactivate': 'Verifica per disattivare',

    // Verification Step
    'enter_current_two_factor_code':
        'Inserisci il codice a 6 cifre corrente dal tuo metodo di autenticazione a due fattori',
    'verifying': 'Verifica in corso...',
    'invalid_o_t_p': 'Codice di verifica non valido. Riprova.',
    'verification_failed':
        'Verifica fallita. Controlla il tuo codice e riprova.',

    // OTP Verification Screen - Italian Translations
    // Add these to the itIT map in app_translations.dart

    // Identity Verification
    'verify_identity': 'Verifica la Tua Identità',

    // Authentication Methods
    'email_authentication': 'Autenticazione Email',
    'sms_authentication': 'Autenticazione SMS',
    'two_factor_authentication': 'Autenticazione a Due Fattori',

    // OTP Instructions
    'otp_email_instruction':
        'Abbiamo inviato un codice di verifica a 6 cifre alla tua email',
    'otp_sms_instruction':
        'Abbiamo inviato un codice di verifica a 6 cifre al tuo numero di telefono',
    'otp_authenticator_instruction':
        'Apri la tua app authenticator e inserisci il codice a 6 cifre',
    'otp_verification_instruction':
        'Inserisci il codice di verifica a 6 cifre per continuare',

    // Contact Information
    'sent_to_email': 'Codice inviato a',
    'sent_to_phone': 'Codice inviato a',
    //'open_authenticator_app': 'Apri la tua app authenticator',

    // Code Input
    'enter_6_digit_code': 'Inserisci codice di verifica',
    'enter_otp_code': 'Inserisci il codice di verifica',
    'otp_must_be_6_digits': 'Il codice di verifica deve essere di 6 cifre',

    // Validation & Errors
    'invalid_otp_code': 'Codice di verifica non valido. Riprova',
    'failed_to_send_otp': 'Impossibile inviare il codice di verifica',

    // Resend Functionality
    'resend_code_in': 'Reinvia codice tra {seconds}s',
    'please_wait_before_resend':
        'Attendi {seconds} secondi prima di richiedere un nuovo codice',

    // Actions
    'verify_continue': 'Verifica e Continua',
    'cancel_logout': 'Annulla ed Esci',

    // Cancellation Dialog
    'cancel_verification': 'Annulla Verifica',
    'cancel_verification_message':
        'Sei sicuro di voler annullare? Verrai disconnesso.',

    // First Login Setup - Italian Translations
    // Add these to the itIT map in app_translations.dart

    // ============== MAIN SCREEN ==============
    // Setup Screen Headers
    //     'first_login_setup': 'Configurazione Iniziale',
    //     'secure_your_account': 'Proteggi il tuo account con una nuova password e l\'autenticazione a due fattori',
    //     'two_factor_auth': 'Autenticazione a Due Fattori',

    // ============== PASSWORD CHANGE STEP ==============
    // Password Change Section
    //     'change_password': 'Cambia Password',
    //     'create_strong_password': 'Crea una password forte e unica',
    //     'first_login_password_change': 'Per motivi di sicurezza, devi cambiare la password al primo accesso',

    // Password Fields
    //     'current_password': 'Password Attuale',
    //     'new_password': 'Nuova Password',
    //     'confirm_password': 'Conferma Nuova Password',

    // Password Validation
    //     'password_requirements': 'Requisiti Password:',
    //     'password_requirements_not_met': 'La password non soddisfa tutti i requisiti',
    //     'valid_password': 'Password valida! Pronta per continuare',
    //     'password_changed': 'Password cambiata con successo',

    // Form Actions
    //     'complete_fields': 'Completa tutti i campi e soddisfa i requisiti della password',
    //     'complete': 'Completa',

    // ============== TWO-FACTOR AUTHENTICATION SETUP ==============
    // 2FA Setup Headers
    'choose_security_method': 'Scegli il tuo metodo di sicurezza',
    'configure_method': 'Configura autenticazione',
    '2fa_security_notice':
        'L\'autenticazione a due fattori aggiunge un ulteriore livello di sicurezza al tuo account',

    // Authentication Methods
    'email_2fa': 'Autenticazione Email',
    'email_2fa_desc': 'Ricevi codici di verifica via email',

    // 'email_2fa_instructions': 'Invieremo un codice di verifica al tuo indirizzo email',
    'sms_2fa': 'Autenticazione SMS',
    'sms_2fa_desc': 'Ricevi codici di verifica tramite messaggio di testo',

    // 'sms_2fa_instructions': 'Inserisci il tuo numero di telefono per ricevere codici di verifica via SMS',
    'authenticator_2fa': 'App Authenticator',
    'authenticator_2fa_desc':
        'Usa Google Authenticator, Microsoft Authenticator o qualsiasi app TOTP',

    // QR Code & Manual Entry
    'show_manual_entry':
        'Non riesci a scansionare? Mostra chiave di inserimento manuale',
    'hide_manual_entry': 'Nascondi chiave di inserimento manuale',
    'secret_copied': 'Chiave segreta copiata negli appunti',

    // Verification Code
    //     'verification_code': 'Codice di Verifica',
    //     'enter_verification_code': 'Inserisci il codice di verifica a 6 cifre',
    'invalid_verification_code': 'Codice di verifica non valido',
    'verification_code_sent': 'Il codice di verifica è stato inviato',

    // Phone Number
    'enter_phone_number': 'Inserisci il tuo numero di telefono',

    // Code Sending
    'send_verification_code': 'Invia Codice di Verifica',
    'resend_in': 'Reinvia tra',

    // Actions
    'verify_enable': 'Verifica e Abilita',
    // 'skip_for_now': 'Salta per ora',

    // Success & Error Messages
    //     '2fa_enabled': 'Autenticazione a due fattori abilitata con successo',
    'failed_to_generate_qr': 'Impossibile generare il codice QR',
    'qr_code_error': 'Errore codice QR',
    'verification_code_sent_on_verify':
        'Un codice di verifica verrà inviato quando tocchi Verifica qui sotto',
    // 'failed_to_send_otp': 'Impossibile inviare il codice di verifica',

    // Success State
    //     'two_factor_deactivated': 'Autenticazione a Due Fattori Disattivata',
    //     'two_factor_deactivated_message': 'Il tuo account Ã¨ ora meno sicuro. Ti consigliamo vivamente di riattivare 2FA il prima possibile.',
    //     'reactivate_anytime': 'Puoi riattivare 2FA in qualsiasi momento nelle impostazioni di Sicurezza',
  };
}
