enum Role {
  client,
  admin,
  manager,
}




class Permissions {
  final bool canAccessAI;
  final bool canAccessSmartHome;
  final bool canAccessChat;
  final bool canCreateTickets;

  final bool canAccessAnalytics;
  final bool canViewUserList;
  final bool canManageBuildings;
  final bool canAccessDocuments;
  final bool canManageMaintenance;
  final bool canDeleteDocuments;
  final bool canSharedDocuments; // <-- This field exists
  final bool canUploadDocuments;

  Permissions({
    required this.canAccessAI,
    required this.canAccessSmartHome,
    required this.canAccessChat,
    required this.canCreateTickets,

    required this.canAccessAnalytics,
    required this.canViewUserList,
    required this.canManageBuildings,
    required this.canAccessDocuments,
    required this.canManageMaintenance,
    required this.canDeleteDocuments,
    required this.canSharedDocuments, // <-- Must be here in constructor
    required this.canUploadDocuments
  });
  static Permissions fromRole(Role role) {
    switch (role) {
      case Role.admin:
        return Permissions(
          canAccessAI: true,
          canAccessSmartHome: true,
          canAccessChat: true,
          canCreateTickets: true,
          canAccessAnalytics: true,
          canViewUserList: true,
          canManageBuildings: true,
          canAccessDocuments: true,
          canManageMaintenance: true,
          canDeleteDocuments: true,
          canSharedDocuments: true,
            canUploadDocuments:true

        );

      case Role.manager:
        return Permissions(
          canAccessAI: true,
          canAccessSmartHome: true,
          canAccessChat: true,
          canCreateTickets: true,
          canAccessAnalytics: true,
          canViewUserList: true,
          canManageBuildings: true,
          canAccessDocuments: true,
          canManageMaintenance: true,
          canDeleteDocuments: true,
          canSharedDocuments: true,
            canUploadDocuments:true
        );

      case Role.client:
      default:
        return Permissions(
          canAccessAI: true,
          canAccessSmartHome: true, // Enable Smart Home for all users
          canAccessChat: true,
          canCreateTickets: true,
          canAccessAnalytics: false,
          canViewUserList: false,
          canManageBuildings: false,
          canAccessDocuments: true,
          canManageMaintenance: false,
          canDeleteDocuments: false,
          canSharedDocuments: true, // Enable share and chat for all users
            canUploadDocuments:true
        );
    }
  }
}
