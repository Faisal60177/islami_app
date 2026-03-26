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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.04;

    return Scaffold(
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
            padding: EdgeInsets.all(padding),
            child: BlocBuilder<LocationCubit, LocationState>(
              builder: (context, state) {
                return Stack(
                  children: [
                    // Main Column content
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AppBar replacement
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.02),
                                  child: Icon(Icons.arrow_back, color: Colors.white, size: screenWidth * 0.07),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Text(
                                "Set Up Location",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Search bar + button
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF004953),
                                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                  ),
                                  child: TextField(
                                    controller: searchController,
                                    onSubmitted: (value) => context.read<LocationCubit>().searchLocation(value),
                                    style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045),
                                    decoration: InputDecoration(
                                      hintText: "Search City",
                                      hintStyle: TextStyle(color: Colors.white54, fontSize: screenWidth * 0.045),
                                      prefixIcon: Icon(Icons.search, color: Colors.white, size: screenWidth * 0.06),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              ElevatedButton(
                                onPressed: () => context.read<LocationCubit>().searchLocation(searchController.text),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018, horizontal: screenWidth * 0.04),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                                  elevation: 4,
                                ),
                                child: Text(
                                  "Search",
                                  style: TextStyle(fontSize: screenWidth * 0.045),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.025),

                          // Saved / Current Location Card
                          if (state is LocationLoaded)
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
                              color: const Color(0xFF1E4D2B),
                              elevation: 6,
                              child: ListTile(
                                leading: Icon(Icons.location_on, color: Colors.red, size: screenWidth * 0.07),
                                title: Text(
                                  "${state.location.city}, ${state.location.country}",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: screenWidth * 0.05),
                                ),
                              ),
                            ),
                          SizedBox(height: screenHeight * 0.02),

                          // GPS button
                          if (state is LocationLoaded)
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: state is LocationLoading ? null : () => context.read<LocationCubit>().getGPSLocation(),
                                icon: state is LocationLoading
                                    ? SizedBox(
                                  width: screenWidth * 0.06,
                                  height: screenWidth * 0.06,
                                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                                    : Icon(Icons.gps_fixed, color: Colors.white, size: screenWidth * 0.06),
                                label: Padding(
                                  padding: EdgeInsets.only(left: screenWidth * 0.01),
                                  child: Text(
                                    state is LocationLoading ? "Locating..." : "Use Current Location",
                                    style: TextStyle(fontSize: screenWidth * 0.045),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018, horizontal: screenWidth * 0.05),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
                                  elevation: 4,
                                ),
                              ),
                            ),

                          SizedBox(height: screenHeight * 0.03),

                          // Search Results
                          if (state is LocationSearchResults)
                            Expanded(
                              child: ListView.separated(
                                itemCount: state.results.length,
                                separatorBuilder: (_, __) => SizedBox(height: screenHeight * 0.015),
                                itemBuilder: (context, index) {
                                  final LocationModel loc = state.results[index];
                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
                                    color: const Color(0xFF004953),
                                    elevation: 4,
                                    child: ListTile(
                                      leading: const Icon(Icons.place, color: Colors.green),
                                      title: Text(loc.city,style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045)),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                                      onTap: () => context.read<LocationCubit>().selectLocation(loc),
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
                                style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          // 🔹 Overlay loader for GPS fetching
                          if (state is LocationLoading)
                              const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ],
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