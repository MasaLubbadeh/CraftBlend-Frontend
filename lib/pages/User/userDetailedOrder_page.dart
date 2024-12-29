import 'package:flutter/material.dart';
import 'package:craft_blend_project/configuration/config.dart';

class UserOrderDetailsPage extends StatefulWidget {
  final dynamic order;

  const UserOrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  _UserOrderDetailsPageState createState() => _UserOrderDetailsPageState();
}

class _UserOrderDetailsPageState extends State<UserOrderDetailsPage> {
  late dynamic order;

  @override
  void initState() {
    super.initState();
    assert(widget.order != null, "Order data cannot be null");
    order = widget.order;
  }

  Map<String, dynamic> groupItemsByStore(List<dynamic> items) {
    final Map<String, dynamic> groupedItems = {};

    for (var item in items) {
      final store = item['storeId'];
      if (store == null || store['_id'] == null) continue;

      final storeId = store['_id'];
      if (!groupedItems.containsKey(storeId)) {
        groupedItems[storeId] = {
          'storeDetails': store,
          'items': [],
          'storeTotal': 0.0,
          'deliveryCost': 0.0,
        };
      }

      groupedItems[storeId]['items'].add(item);
      groupedItems[storeId]['storeTotal'] += item['storeTotal'] ?? 0.0;
      groupedItems[storeId]['deliveryCost'] = item['storeDeliveryCost'] ?? 0.0;
    }

    return groupedItems;
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = groupItemsByStore(order['items'] ?? []);
    final double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        toolbarHeight: appBarHeight,
        title: Text(
          "Order Details: #${order['userOrderNumber'] ?? 'N/A'}",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildOrderSummary(groupedItems),
            const SizedBox(height: 20),
            Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Order items:",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: myColor),
              ),
            ),
            ...groupedItems.entries.map((entry) {
              final storeId = entry.key;
              final storeData = entry.value;

              return _buildStoreSection(storeData);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Map<String, dynamic> groupedStores) {
    return Card(
      color: const Color.fromARGB(171, 243, 229, 245),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            const SizedBox(height: 5),
            ...groupedStores.entries.map((entry) {
              final storeDetails = entry.value['storeDetails'];
              final storeName = storeDetails['storeName'] ?? 'Unknown Store';
              final storeLogo = storeDetails['logo'] ?? '';
              final storeTotal = entry.value['storeTotal'];
              final deliveryCost = entry.value['deliveryCost'];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (storeLogo.isNotEmpty)
                      CircleAvatar(
                        backgroundImage: NetworkImage(storeLogo),
                        radius: 20,
                      )
                    else
                      const CircleAvatar(
                        child: Icon(Icons.store, color: myColor),
                        radius: 20,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Store Total: \$${storeTotal.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            "Delivery Cost: \$${deliveryCost.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSection(Map<String, dynamic> storeData) {
    final storeDetails = storeData['storeDetails'];
    final storeName = storeDetails['storeName'] ?? 'Unknown Store';
    final storeLogo = storeDetails['logo'] ?? '';
    final storeStatus = storeData['items'].isNotEmpty
        ? storeData['items'][0]['storeStatus'] ?? 'Unknown'
        : 'Unknown';
    final storeItems = storeData['items'];

    return Card(
      color: const Color.fromARGB(171, 243, 229, 245),
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (storeLogo.isNotEmpty)
                  CircleAvatar(
                    backgroundImage: NetworkImage(storeLogo),
                    radius: 20,
                  )
                else
                  const CircleAvatar(
                    child: Icon(Icons.store, color: myColor),
                    radius: 20,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
                _buildStatusBadge(storeStatus),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              children: storeItems
                  .map<Widget>((item) => _buildProductCard(item))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic item) {
    final product = item['productId'] ?? {};
    final productName = product['name'] ?? 'No Name';
    final productImage = product['image'] ?? '';
    final quantity = item['quantity'] ?? 0;
    final price = item['pricePerUnitWithOptionsCost'] ?? 0.0;

    return Card(
      color: const Color.fromARGB(171, 243, 229, 245),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: myColor.withOpacity(0.2),
                image: productImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(productImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: productImage.isEmpty
                  ? const Icon(Icons.image, size: 40, color: myColor)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text("Quantity: $quantity"),
                  Text("Price: \$${price.toStringAsFixed(2)}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'pending':
        badgeColor = Colors.orange;
        break;
      case 'shipped':
        badgeColor = Colors.blue;
        break;
      case 'delivered':
        badgeColor = Colors.green;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
