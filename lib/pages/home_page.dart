import 'package:closeai/controllers/provider_controller.dart';
import 'package:closeai/pages/home_page/nav_rail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_state_controller.dart';
import '../models/provider.dart';

class HomePage extends GetResponsiveView<AppStateController> {
  HomePage({super.key});

  @override
  Widget builder() {
    final ProviderController providerController = Get.find();
    return Scaffold(
      body: Row(
        children: [
          NavRail(),
          VerticalDivider(thickness: 1),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      providerController.addProvider(Provider()..name = 'test');
                    },
                    child: Text('Test'),
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(thickness: 1),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Obx(() {
                return ListView.builder(
                  itemCount: providerController.providers.length,
                  itemBuilder: (ctx, index) {
                    return ListTile(
                      title: Text(
                        providerController.providers[index].value.name,
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          providerController.removeProvider(index);
                        },
                        icon: Icon(Icons.delete_rounded),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
