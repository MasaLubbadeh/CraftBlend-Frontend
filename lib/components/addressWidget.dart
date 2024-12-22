import 'package:craft_blend_project/pages/googleMapsPage.dart';
import 'package:flutter/material.dart';
import '../pages/googleMapsPage.dart';
import '../pages/search_page.dart';

class AddressWidget extends StatelessWidget {
  final String address;

  const AddressWidget({Key? key, required this.address}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapPage()),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Icon(Icons.location_on, color: Colors.white70),
              const SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.split(",")[0], // City Center
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color.fromARGB(113, 238, 238, 238)),
                  ),
                  Text(
                    address.split(",")[1], // Al-Sharawiya
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(113, 238, 238, 238),
                    ),
                  ),
                ],
              ),
              IconButton(
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.search, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SearchPage(),
                      transitionsBuilder: (_, animation, __, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);

                        return SlideTransition(
                            position: offsetAnimation, child: child);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
