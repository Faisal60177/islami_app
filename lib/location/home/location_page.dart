import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:islamic_app/location/cubit/location_cubit.dart';
import 'package:islamic_app/location/cubit/location_state.dart';
import 'package:islamic_app/location/model/location_model.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<LocationCubit>().loadSavedLocation();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // Gradient Background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00693E), Color(0xFF004953)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<LocationCubit, LocationState>(
              builder: (context, state) {
                // Loading
                if (state is LocationInitial || state is LocationLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                // Error
                if (state is LocationError) {
                  return Center(
                      child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.white, fontSize: 16)));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AppBar replacement (custom header)
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Set Up Location",
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF004953),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: searchController,
                              onSubmitted: (value) => context.read<LocationCubit>().searchLocation(value),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Search City",
                                hintStyle: const TextStyle(color: Colors.white54),
                                prefixIcon: const Icon(Icons.search, color: Colors.white),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => context.read<LocationCubit>().searchLocation(searchController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          child: const Text("Search", style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Saved / Current Location
                    if (state is LocationLoaded)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: const Color(0xFF1E4D2B),
                        elevation: 6,
                        child: ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.red, size: 28),
                          title: Text(
                            "${state.location.city}, ${state.location.country}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    //GPS Button for current Location
                    if (state is LocationLoaded)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.read<LocationCubit>().getGPSLocation(),
                            icon: const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.gps_fixed, color: Colors.white),
                            ),
                            label: const Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Text("Use Current Location", style: TextStyle(fontSize: 16)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                          ),
                        ],
                      ),



                    const SizedBox(height: 20),

                    // Search Results
                    if (state is LocationSearchResults)
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.results.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final LocationModel loc = state.results[index];
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              color: const Color(0xFF004953),
                              elevation: 4,
                              child: ListTile(
                                leading: const Icon(Icons.place, color: Colors.green),
                                title: Text(loc.city, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                onTap: () => context.read<LocationCubit>().selectLocation(loc),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                              ),
                            );
                          },
                        ),
                      ),

                    // Permission Denied
                    if (state is LocationPermissionDenied)
                      Center(
                        child: Text(
                          "Location permission denied. Please enable GPS.",
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}