import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/controllers/message_popup_controller.dart';

enum DeviceType { light, climate, security, appliance, blinds }

enum DeviceStatus { on, off, locked, unlocked }

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final String room;
  DeviceStatus status;
  double? value;
  final String? unit;
  final IconData icon;
  final Color color;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.room,
    required this.status,
    this.value,
    this.unit,
    required this.icon,
    required this.color,
  });
}

class SmartHomeScreen extends StatefulWidget {
  final String role; // 'client', 'admin', 'super-admin'

  const SmartHomeScreen({
    super.key,
    required this.role,
  });

  @override
  State<SmartHomeScreen> createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  String _activeRoom = 'all';
  late List<Device> _devices;

  @override
  void initState() {
    super.initState();
    _initializeDevices();
  }

  void _initializeDevices() {
    _devices = [
      Device(
        id: '1',
        name: 'Living Room Lights',
        type: DeviceType.light,
        room: 'living',
        status: DeviceStatus.on,
        value: 75,
        icon: Icons.lightbulb,
        color: Colors.yellow.shade600,
      ),
      Device(
        id: '2',
        name: 'Bedroom Lights',
        type: DeviceType.light,
        room: 'bedroom',
        status: DeviceStatus.off,
        value: 0,
        icon: Icons.lightbulb,
        color: Colors.yellow.shade600,
      ),
      Device(
        id: '3',
        name: 'Thermostat',
        type: DeviceType.climate,
        room: 'living',
        status: DeviceStatus.on,
        value: 22,
        unit: 'Â°C',
        icon: Icons.thermostat,
        color: Colors.orange.shade600,
      ),
      Device(
        id: '4',
        name: 'Air Conditioner',
        type: DeviceType.climate,
        room: 'bedroom',
        status: DeviceStatus.off,
        value: 24,
        unit: 'Â°C',
        icon: Icons.air,
        color: Colors.blue.shade600,
      ),
      Device(
        id: '5',
        name: 'Front Door Lock',
        type: DeviceType.security,
        room: 'entrance',
        status: DeviceStatus.locked,
        icon: Icons.lock,
        color: Colors.green.shade600,
      ),
      Device(
        id: '6',
        name: 'Security Camera',
        type: DeviceType.security,
        room: 'entrance',
        status: DeviceStatus.on,
        icon: Icons.videocam,
        color: Colors.purple.shade600,
      ),
      Device(
        id: '7',
        name: 'Living Room Blinds',
        type: DeviceType.blinds,
        room: 'living',
        status: DeviceStatus.on,
        value: 60,
        icon: Icons.blinds,
        color: Colors.grey.shade600,
      ),
      Device(
        id: '8',
        name: 'Kitchen Lights',
        type: DeviceType.light,
        room: 'kitchen',
        status: DeviceStatus.on,
        value: 90,
        icon: Icons.lightbulb,
        color: Colors.yellow.shade600,
      ),
    ];
  }

  List<Device> get _filteredDevices {
    if (_activeRoom == 'all') return _devices;
    return _devices.where((d) => d.room == _activeRoom).toList();
  }

  int _getActiveDevicesCount() {
    return _devices.where((d) => d.status == DeviceStatus.on).length;
  }

  bool get _canControlDevices {
    // Simplified permission check
    return widget.role == 'admin' || widget.role == 'super-admin';
  }

  void _toggleDevice(String deviceId) {
    setState(() {
      final index = _devices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        final device = _devices[index];
        if (device.type == DeviceType.security) {
          device.status = device.status == DeviceStatus.locked
              ? DeviceStatus.unlocked
              : DeviceStatus.locked;
        } else {
          device.status =
          device.status == DeviceStatus.on ? DeviceStatus.off : DeviceStatus.on;
          device.value = device.status == DeviceStatus.on
              ? (device.value ?? 100)
              : 0;
        }
      }
    });
  }

  void _updateDeviceValue(String deviceId, double value) {
    setState(() {
      final index = _devices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        _devices[index].value = value;
        _devices[index].status =
        value > 0 ? DeviceStatus.on : DeviceStatus.off;
      }
    });
  }

  Color _getDeviceStatusColor(Device device) {
    if (device.type == DeviceType.security) {
      return device.status == DeviceStatus.locked
          ? Colors.green.shade100
          : Colors.red.shade100;
    }
    return device.status == DeviceStatus.on
        ? Colors.green.shade100
        : Colors.grey.shade200;
  }

  Color _getDeviceStatusTextColor(Device device) {
    if (device.type == DeviceType.security) {
      return device.status == DeviceStatus.locked
          ? Colors.green.shade700
          : Colors.red.shade700;
    }
    return device.status == DeviceStatus.on
        ? Colors.green.shade700
        : Colors.grey.shade600;
  }

  String _getDeviceStatusLabel(Device device) {
    if (device.type == DeviceType.security) {
      return device.status == DeviceStatus.locked ? 'Locked' : 'Unlocked';
    }
    return device.status == DeviceStatus.on ? 'On' : 'Off';
  }

  void _executeGoodNightScene() {
    setState(() {
      for (var device in _devices) {
        if (device.type == DeviceType.light) {
          device.status = DeviceStatus.off;
          device.value = 0;
        }
      }
    });
    MessagePopupController.showSuccess(
      messageKey: 'good_night_scene_activated',
      titleKey: 'success',
    );
  }

  void _executeGoodMorningScene() {
    setState(() {
      for (var device in _devices) {
        if (device.type == DeviceType.light) {
          device.status = DeviceStatus.on;
          device.value = 80;
        }
      }
    });
    MessagePopupController.showSuccess(
      messageKey: 'good_morning_scene_activated',
      titleKey: 'success',
    );
  }

  void _executeLeavingHomeScene() {
    setState(() {
      for (var device in _devices) {
        if (device.type == DeviceType.security && device.icon == Icons.lock) {
          device.status = DeviceStatus.locked;
        }
      }
    });
    MessagePopupController.showSuccess(
      messageKey: 'leaving_home_scene_activated',
      titleKey: 'success',
    );
  }

  @override
  Widget build(BuildContext context) {
    // NO SCAFFOLD - This screen is wrapped by MainScaffold
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Quick Stats
            _buildQuickStats(),

            const SizedBox(height: 16),

            // Room Filter
            _buildRoomFilter(),

            const SizedBox(height: 16),

            // Devices Grid
            _buildDevicesList(),

            const SizedBox(height: 16),

            // Quick Actions
            if (_canControlDevices) _buildQuickActions(),

            const SizedBox(height: 16),

            // Weather Info
            _buildWeatherInfo(),

            // View-Only Warning
            if (!_canControlDevices) ...[
              const SizedBox(height: 16),
              _buildViewOnlyWarning(),
            ],
          ],
        ),
      ),

    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.power,
            iconColor: Colors.green.shade600,
            iconBg: Colors.green.shade100,
            value: '${_getActiveDevicesCount()}',
            label: 'Active',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.bolt,
            iconColor: Colors.blue.shade600,
            iconBg: Colors.blue.shade100,
            value: '245W',
            label: 'Usage',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.thermostat,
            iconColor: Colors.orange.shade600,
            iconBg: Colors.orange.shade100,
            value: '22Â°C',
            label: 'Temp',
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomFilter() {
    final rooms = [
      {'id': 'all', 'label': 'All Rooms', 'count': _devices.length},
      {
        'id': 'living',
        'label': 'Living Room',
        'count': _devices.where((d) => d.room == 'living').length
      },
      {
        'id': 'bedroom',
        'label': 'Bedroom',
        'count': _devices.where((d) => d.room == 'bedroom').length
      },
      {
        'id': 'kitchen',
        'label': 'Kitchen',
        'count': _devices.where((d) => d.room == 'kitchen').length
      },
      {
        'id': 'entrance',
        'label': 'Entrance',
        'count': _devices.where((d) => d.room == 'entrance').length
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: rooms.map((room) {
          final isActive = _activeRoom == room['id'];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: isActive
                  ? const Color(0xFF6B8E23)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              elevation: isActive ? 4 : 1,
              shadowColor: isActive
                  ? const Color(0xFF6B8E23).withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _activeRoom = room['id'] as String;
                  });
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '${room['label']} (${room['count']})',
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildDevicesList() {
    return Column(
      children: _filteredDevices.asMap().entries.map((entry) {
        final index = entry.key;
        final device = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildDeviceCard(device),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: (100 + index * 50).ms)
            .slideY(begin: 0.2, delay: (100 + index * 50).ms);
      }).toList(),
    );
  }

  Widget _buildDeviceCard(Device device) {
    final isActive =
        device.status == DeviceStatus.on || device.status == DeviceStatus.locked;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Device Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF6B8E23).withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  device.icon,
                  color: isActive ? device.color : Colors.grey.shade400,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Device Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getDeviceStatusColor(device),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getDeviceStatusLabel(device),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getDeviceStatusTextColor(device),
                            ),
                          ),
                        ),
                        if (device.value != null && device.value! > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${device.value!.round()}${device.unit ?? '%'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Toggle Switch
              Switch(
                value: isActive,
                onChanged: _canControlDevices
                    ? (value) => _toggleDevice(device.id)
                    : null,
                activeThumbColor: const Color(0xFF6B8E23),
              ),
            ],
          ),

          // Device Controls (Slider)
          if (device.value != null && isActive) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  device.type == DeviceType.light
                      ? 'Brightness'
                      : device.type == DeviceType.blinds
                      ? 'Position'
                      : 'Temperature',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${device.value!.round()}${device.unit ?? '%'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF6B8E23),
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: const Color(0xFF6B8E23),
                overlayColor: const Color(0xFF6B8E23).withOpacity(0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: device.value ?? 0,
                onChanged: _canControlDevices
                    ? (value) => _updateDeviceValue(device.id, value)
                    : null,
                min: device.type == DeviceType.climate ? 16 : 0,
                max: device.type == DeviceType.climate ? 30 : 100,
                divisions: device.type == DeviceType.climate ? 14 : 100,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6B8E23).withOpacity(0.1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Common scenarios',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActionButton(
            icon: Icons.nightlight_round,
            label: 'Good Night',
            subtitle: 'Turn off all lights',
            onTap: _executeGoodNightScene,
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            icon: Icons.wb_sunny,
            label: 'Good Morning',
            subtitle: 'Turn on all lights',
            onTap: _executeGoodMorningScene,
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            icon: Icons.lock,
            label: 'Leaving Home',
            subtitle: 'Lock all doors',
            onTap: _executeLeavingHomeScene,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.wb_sunny,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outside',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Text(
                    '18Â°C',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Humidity',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const Text(
                '65%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildViewOnlyWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'View-only mode. Contact your administrator for device control access.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: Colors.orange.shade700,
        ),
      ),
    );
  }
}