class EmergencyContact {
  final String title;
  final String number;
  final String description;
  final String category;

  const EmergencyContact({
    required this.title,
    required this.number,
    required this.description,
    required this.category,
  });
}

class EmergencyContacts {
  static const List<EmergencyContact> contacts = [
    EmergencyContact(
      title: 'National Emergency',
      number: '112',
      description: 'All-in-one national emergency number for police, fire, ambulance',
      category: 'General',
    ),
    EmergencyContact(
      title: 'Police Control Room',
      number: '100',
      description: 'Immediate police emergency assistance',
      category: 'Police',
    ),
    EmergencyContact(
      title: 'Women Helpline',
      number: '1091',
      description: '24/7 dedicated support for women safety & distress',
      category: 'Women Safety',
    ),
    EmergencyContact(
      title: 'Ambulance & Medical',
      number: '108',
      description: 'Emergency medical and trauma transport service',
      category: 'Medical',
    ),
    EmergencyContact(
      title: 'Child Helpline',
      number: '1098',
      description: '24-hour emergency phone outreach service for children',
      category: 'Child Safety',
    ),
    EmergencyContact(
      title: 'Railway Police (GRP)',
      number: '1512',
      description: 'Assistance for train and railway station safety',
      category: 'Transit',
    ),
  ];
}
