import 'package:flutter/material.dart';
import '../models/address.dart';
import '../utils/theme.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<Address> _addresses = [
    Address(
      id: '1',
      name: 'Home',
      street: '123 Main Street',
      city: 'New York',
      state: 'NY',
      zipCode: '10001',
      country: 'USA',
      isDefault: true,
    ),
    Address(
      id: '2',
      name: 'Work',
      street: '456 Office Blvd',
      city: 'New York',
      state: 'NY',
      zipCode: '10002',
      country: 'USA',
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddAddressDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _addresses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                return _buildAddressCard(_addresses[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 100,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 24),
          Text(
            'No addresses added',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your shipping addresses here',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showAddAddressDialog,
            child: const Text('Add Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.borderLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  address.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.fullAddress,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showEditAddressDialog(address);
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: address.isDefault
                        ? null
                        : () {
                            setState(() {
                              for (var addr in _addresses) {
                                addr = Address(
                                  id: addr.id,
                                  name: addr.name,
                                  street: addr.street,
                                  city: addr.city,
                                  state: addr.state,
                                  zipCode: addr.zipCode,
                                  country: addr.country,
                                  isDefault: addr.id == address.id,
                                );
                              }
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: address.isDefault
                          ? AppTheme.textMuted
                          : AppTheme.primaryColor,
                    ),
                    child: Text(address.isDefault ? 'Default' : 'Set Default'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog() {
    _showAddressDialog(null);
  }

  void _showEditAddressDialog(Address address) {
    _showAddressDialog(address);
  }

  void _showAddressDialog(Address? address) {
    final isEditing = address != null;
    final nameController = TextEditingController(text: address?.name ?? '');
    final streetController = TextEditingController(text: address?.street ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    final stateController = TextEditingController(text: address?.state ?? '');
    final zipController = TextEditingController(text: address?.zipCode ?? '');
    final countryController = TextEditingController(text: address?.country ?? 'USA');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Address' : 'Add Address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Address Name'),
              ),
              TextField(
                controller: streetController,
                decoration: const InputDecoration(labelText: 'Street Address'),
              ),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: zipController,
                      decoration: const InputDecoration(labelText: 'ZIP Code'),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: countryController,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newAddress = Address(
                id: isEditing ? address.id : DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                street: streetController.text,
                city: cityController.text,
                state: stateController.text,
                zipCode: zipController.text,
                country: countryController.text,
                isDefault: isEditing ? address.isDefault : false,
              );

              setState(() {
                if (isEditing) {
                  final index = _addresses.indexWhere((a) => a.id == address.id);
                  if (index != -1) {
                    _addresses[index] = newAddress;
                  }
                } else {
                  _addresses.add(newAddress);
                }
              });

              Navigator.pop(context);
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}