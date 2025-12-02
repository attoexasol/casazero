class DocumentModel {
  final String id;
  final String title;
  final String type;
  final String category;
  final String date;
  final String size;
  final List<String> tags;
  final String? status;

  DocumentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.date,
    required this.size,
    required this.tags,
    this.status,
  });

  static final mockDocuments = <DocumentModel>[
    DocumentModel(
      id: 'md1',
      title: 'Appliance Warranty - Dishwasher',
      type: 'PDF',
      category: 'My Documents',
      date: 'Nov 3, 2025',
      size: '1.1 MB',
      tags: ['Personal', 'Guarantees'],
    ),
    DocumentModel(
      id: 'md2',
      title: 'Renovation Invoice - Kitchen',
      type: 'PDF',
      category: 'My Documents',
      date: 'Oct 20, 2025',
      size: '0.8 MB',
      tags: ['Personal', 'Invoices'],
    ),
    DocumentModel(
      id: 'md3',
      title: 'Interior Design Plans',
      type: 'JPG',
      category: 'My Documents',
      date: 'Oct 5, 2025',
      size: '3.2 MB',
      tags: ['Personal', 'Others'],
    ),
    DocumentModel(
      id: '1',
      title: 'Energy Performance Certificate 2025',
      type: 'PDF',
      category: 'Energy & Environmental',
      date: 'Oct 28, 2025',
      size: '2.4 MB',
      tags: ['Energy', 'Compliance'],
      status: 'New',
    ),
    DocumentModel(
      id: '2',
      title: 'Building Technical Specifications',
      type: 'PDF',
      category: 'Technical Building',
      date: 'Sep 15, 2025',
      size: '5.8 MB',
      tags: ['Technical', 'Specifications'],
    ),
    DocumentModel(
      id: '3',
      title: 'Property Deed - Unit 4B',
      type: 'PDF',
      category: 'Ownership & Legal',
      date: 'Aug 10, 2025',
      size: '1.2 MB',
      tags: ['Legal', 'Ownership'],
    ),
    DocumentModel(
      id: '4',
      title: 'HVAC System Drawings',
      type: 'DWG',
      category: 'Technical Building',
      date: 'Jul 22, 2025',
      size: '12.5 MB',
      tags: ['Technical', 'HVAC'],
    ),
    DocumentModel(
      id: '5',
      title: 'Fire Safety Compliance Report',
      type: 'PDF',
      date: 'Jun 30, 2025',
      size: '3.1 MB',
      category: 'Compliance & Safety',
      tags: ['Safety', 'Compliance'],
    ),
  ];
}
