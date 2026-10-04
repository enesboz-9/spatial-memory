import 'package:flutter/material.dart';

import '../../core/models/environment.dart';
import '../../core/models/game_object.dart';

abstract final class Environments {
  /// Mechanic: DIRECTION. Antennas and dishes must point the right way.
  static const Environment spaceStation = Environment(
    id: 'space_station',
    name: 'Space Station',
    icon: Icons.rocket_launch,
    backgroundColor: Color(0xFF0B1230),
    background: BackgroundStyle.stars,
    mechanic: EnvironmentMechanic.direction,
    directionSteps: 8,
    ruleHint: 'Antennas and dishes have a direction. Remember where they point.',
    placeHint: 'Tap a placed object with an arrow to turn it.',
    objectPool: [
      ObjectDefinition(id: 'computer', label: 'Computer', icon: Icons.computer),
      ObjectDefinition(
        id: 'battery',
        label: 'Battery',
        icon: Icons.battery_charging_full,
      ),
      ObjectDefinition(
        id: 'helmet',
        label: 'Helmet',
        icon: Icons.sports_motorsports,
      ),
      ObjectDefinition(id: 'toolbox', label: 'Toolbox', icon: Icons.handyman),
      ObjectDefinition(
        id: 'satellite',
        label: 'Satellite',
        icon: Icons.satellite_alt,
        isDirectional: true,
      ),
      ObjectDefinition(id: 'book', label: 'Book', icon: Icons.menu_book),
      ObjectDefinition(id: 'coffee', label: 'Coffee', icon: Icons.coffee),
      ObjectDefinition(id: 'cable', label: 'Cable', icon: Icons.cable),
      ObjectDefinition(id: 'monitor', label: 'Monitor', icon: Icons.monitor),
      ObjectDefinition(
        id: 'antenna',
        label: 'Antenna',
        icon: Icons.settings_input_antenna,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'flashlight',
        label: 'Flashlight',
        icon: Icons.flashlight_on,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'camera',
        label: 'Camera',
        icon: Icons.photo_camera,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'headset',
        label: 'Headset',
        icon: Icons.headset,
      ),
      ObjectDefinition(
        id: 'keyboard',
        label: 'Keyboard',
        icon: Icons.keyboard,
      ),
      ObjectDefinition(
        id: 'chip',
        label: 'Chip',
        icon: Icons.memory,
      ),
      ObjectDefinition(
        id: 'watch',
        label: 'Watch',
        icon: Icons.watch,
      ),
      ObjectDefinition(
        id: 'rocket',
        label: 'Rocket',
        icon: Icons.rocket,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'solar_panel',
        label: 'Solar panel',
        icon: Icons.solar_power,
      ),
    ],
  );

  /// Mechanic: RELATIVE. Some objects stand a set distance from another one.
  static const Environment island = Environment(
    id: 'island',
    name: 'Island',
    icon: Icons.sailing,
    backgroundColor: Color(0xFF0E5A8A),
    background: BackgroundStyle.sea,
    mechanic: EnvironmentMechanic.relative,
    ruleHint: 'Some objects stand a set distance from another. Remember it.',
    placeHint: 'Partner objects also score by their distance from each other.',
    relationPairs: [
      RelationPair(anchorId: 'palm_tree', childId: 'treasure_chest'),
      RelationPair(anchorId: 'boat', childId: 'anchor'),
      RelationPair(anchorId: 'rock', childId: 'flag'),
      RelationPair(anchorId: 'umbrella', childId: 'campfire'),
    ],
    objectPool: [
      ObjectDefinition(id: 'palm_tree', label: 'Palm tree', icon: Icons.park),
      ObjectDefinition(
        id: 'treasure_chest',
        label: 'Treasure chest',
        icon: Icons.inventory_2,
      ),
      ObjectDefinition(id: 'boat', label: 'Boat', icon: Icons.sailing),
      ObjectDefinition(id: 'anchor', label: 'Anchor', icon: Icons.anchor),
      ObjectDefinition(
        id: 'umbrella',
        label: 'Umbrella',
        icon: Icons.beach_access,
      ),
      ObjectDefinition(id: 'compass', label: 'Compass', icon: Icons.explore),
      ObjectDefinition(id: 'flag', label: 'Flag', icon: Icons.flag),
      ObjectDefinition(id: 'map', label: 'Map', icon: Icons.map),
      ObjectDefinition(id: 'rock', label: 'Rock', icon: Icons.landscape),
      ObjectDefinition(
        id: 'campfire',
        label: 'Campfire',
        icon: Icons.local_fire_department,
      ),
      ObjectDefinition(
        id: 'fish',
        label: 'Fish',
        icon: Icons.set_meal,
      ),
      ObjectDefinition(
        id: 'surfboard',
        label: 'Surfboard',
        icon: Icons.surfing,
      ),
      ObjectDefinition(
        id: 'sun',
        label: 'Sun',
        icon: Icons.wb_sunny,
      ),
      ObjectDefinition(
        id: 'bottle',
        label: 'Bottle',
        icon: Icons.liquor,
      ),
      ObjectDefinition(
        id: 'lantern',
        label: 'Lantern',
        icon: Icons.lightbulb_outline,
      ),
      ObjectDefinition(
        id: 'camera',
        label: 'Camera',
        icon: Icons.photo_camera,
      ),
      ObjectDefinition(
        id: 'waves',
        label: 'Waves',
        icon: Icons.waves,
      ),
      ObjectDefinition(
        id: 'binoculars',
        label: 'Binoculars',
        icon: Icons.visibility,
      ),
    ],
  );

  /// Mechanic: COLOR. The three bottles look the same except for their color.
  static const Environment laboratory = Environment(
    id: 'laboratory',
    name: 'Laboratory',
    icon: Icons.science,
    backgroundColor: Color(0xFF263238),
    background: BackgroundStyle.laboratory,
    mechanic: EnvironmentMechanic.color,
    ruleHint: 'Same shape, different color. Remember which color was where.',
    placeHint: 'Every bottle has its own spot. Check the labels.',
    objectPool: [
      ObjectDefinition(
        id: 'bottle_red',
        label: 'Red bottle',
        icon: Icons.science,
        tint: Color(0xFFE53935),
      ),
      ObjectDefinition(
        id: 'bottle_blue',
        label: 'Blue bottle',
        icon: Icons.science,
        tint: Color(0xFF1E88E5),
      ),
      ObjectDefinition(
        id: 'bottle_green',
        label: 'Green bottle',
        icon: Icons.science,
        tint: Color(0xFF43A047),
      ),
      ObjectDefinition(id: 'microscope', label: 'Microscope', icon: Icons.biotech),
      ObjectDefinition(id: 'syringe', label: 'Syringe', icon: Icons.vaccines),
      ObjectDefinition(
        id: 'thermometer',
        label: 'Thermometer',
        icon: Icons.thermostat,
      ),
      ObjectDefinition(id: 'notebook', label: 'Notebook', icon: Icons.menu_book),
      ObjectDefinition(id: 'computer', label: 'Computer', icon: Icons.computer),
      ObjectDefinition(id: 'lamp', label: 'Lamp', icon: Icons.lightbulb),
      ObjectDefinition(
        id: 'scale',
        label: 'Scale',
        icon: Icons.scale,
      ),
      ObjectDefinition(
        id: 'timer',
        label: 'Timer',
        icon: Icons.timer,
      ),
      ObjectDefinition(
        id: 'droplet',
        label: 'Droplet',
        icon: Icons.opacity,
      ),
      ObjectDefinition(
        id: 'calculator',
        label: 'Calculator',
        icon: Icons.calculate,
      ),
      ObjectDefinition(
        id: 'magnifier',
        label: 'Magnifier',
        icon: Icons.search,
      ),
      ObjectDefinition(
        id: 'clipboard',
        label: 'Clipboard',
        icon: Icons.assignment,
      ),
      ObjectDefinition(
        id: 'burner',
        label: 'Burner',
        icon: Icons.local_fire_department,
      ),
      ObjectDefinition(
        id: 'gloves',
        label: 'Gloves',
        icon: Icons.back_hand,
      ),
      ObjectDefinition(
        id: 'battery',
        label: 'Battery',
        icon: Icons.battery_full,
      ),
    ],
  );

  /// Mechanic: DIRECTION. Vehicles must face the right way (4 headings).
  static const Environment city = Environment(
    id: 'city',
    name: 'City',
    icon: Icons.location_city,
    backgroundColor: Color(0xFF2B2F36),
    background: BackgroundStyle.streets,
    mechanic: EnvironmentMechanic.direction,
    directionSteps: 4,
    ruleHint: 'Vehicles have a heading. Remember which way each one faces.',
    placeHint: 'Tap a placed vehicle to turn it.',
    objectPool: [
      ObjectDefinition(
        id: 'car',
        label: 'Car',
        icon: Icons.directions_car,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'bus',
        label: 'Bus',
        icon: Icons.directions_bus,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'taxi',
        label: 'Taxi',
        icon: Icons.local_taxi,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'truck',
        label: 'Truck',
        icon: Icons.local_shipping,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'bicycle',
        label: 'Bicycle',
        icon: Icons.pedal_bike,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'scooter',
        label: 'Scooter',
        icon: Icons.electric_scooter,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'traffic_light',
        label: 'Traffic light',
        icon: Icons.traffic,
      ),
      ObjectDefinition(id: 'building', label: 'Building', icon: Icons.apartment),
      ObjectDefinition(
        id: 'hydrant',
        label: 'Hydrant',
        icon: Icons.fire_hydrant_alt,
      ),
      ObjectDefinition(
        id: 'parking',
        label: 'Parking',
        icon: Icons.local_parking,
      ),
      ObjectDefinition(id: 'tree', label: 'Tree', icon: Icons.park),
      ObjectDefinition(
        id: 'motorcycle',
        label: 'Motorcycle',
        icon: Icons.two_wheeler,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'shuttle',
        label: 'Shuttle',
        icon: Icons.airport_shuttle,
        isDirectional: true,
      ),
      ObjectDefinition(
        id: 'gas_station',
        label: 'Gas station',
        icon: Icons.local_gas_station,
      ),
      ObjectDefinition(
        id: 'bench',
        label: 'Bench',
        icon: Icons.event_seat,
      ),
      ObjectDefinition(
        id: 'cafe',
        label: 'Cafe',
        icon: Icons.local_cafe,
      ),
      ObjectDefinition(
        id: 'stop_sign',
        label: 'Stop sign',
        icon: Icons.stop_circle,
      ),
      ObjectDefinition(
        id: 'mailbox',
        label: 'Mailbox',
        icon: Icons.mail,
      ),
    ],
  );

  /// Mechanic: CLUSTER. Some objects belong together and stand close.
  static const Environment camp = Environment(
    id: 'camp',
    name: 'Camp',
    icon: Icons.cabin,
    backgroundColor: Color(0xFF2E5D34),
    background: BackgroundStyle.meadow,
    mechanic: EnvironmentMechanic.cluster,
    ruleHint: 'Some objects belong together. Remember which ones were close.',
    placeHint: 'Keep objects that belong together close, as they were.',
    clusters: [
      ['tent', 'backpack', 'flashlight'],
      ['campfire', 'coffee', 'firewood'],
    ],
    objectPool: [
      ObjectDefinition(id: 'tent', label: 'Tent', icon: Icons.festival),
      ObjectDefinition(id: 'backpack', label: 'Backpack', icon: Icons.backpack),
      ObjectDefinition(
        id: 'flashlight',
        label: 'Flashlight',
        icon: Icons.flashlight_on,
      ),
      ObjectDefinition(
        id: 'campfire',
        label: 'Campfire',
        icon: Icons.local_fire_department,
      ),
      ObjectDefinition(id: 'coffee', label: 'Coffee', icon: Icons.coffee),
      ObjectDefinition(id: 'firewood', label: 'Firewood', icon: Icons.forest),
      ObjectDefinition(id: 'map', label: 'Map', icon: Icons.map),
      ObjectDefinition(id: 'compass', label: 'Compass', icon: Icons.explore),
      ObjectDefinition(id: 'fishing_rod', label: 'Fishing rod', icon: Icons.phishing),
      ObjectDefinition(id: 'cooler', label: 'Cooler', icon: Icons.kitchen),
      ObjectDefinition(
        id: 'boots',
        label: 'Boots',
        icon: Icons.hiking,
      ),
      ObjectDefinition(
        id: 'sleeping_bag',
        label: 'Sleeping bag',
        icon: Icons.hotel,
      ),
      ObjectDefinition(
        id: 'water_bottle',
        label: 'Water bottle',
        icon: Icons.water_drop,
      ),
      ObjectDefinition(
        id: 'radio',
        label: 'Radio',
        icon: Icons.radio,
      ),
      ObjectDefinition(
        id: 'binoculars',
        label: 'Binoculars',
        icon: Icons.visibility,
      ),
      ObjectDefinition(
        id: 'music',
        label: 'Music',
        icon: Icons.music_note,
      ),
      ObjectDefinition(
        id: 'saw',
        label: 'Saw',
        icon: Icons.carpenter,
      ),
      ObjectDefinition(
        id: 'cookie',
        label: 'Cookies',
        icon: Icons.cookie,
      ),
    ],
  );

  static const List<Environment> all = [
    spaceStation,
    island,
    laboratory,
    city,
    camp,
  ];
}
