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

class _LocationPageState extends State<LocationPage>
    with TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    context.read<LocationCubit>().loadSavedLocation();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1F14),
      body: Stack(
        children: [
          // ── Background decorative circles ──
          Positioned(
            top: -sh * 0.12,
            right: -sw * 0.2,
            child: Container(
              width: sw * 0.75,
              height: sw * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00A86B).withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -sh * 0.08,
            left: -sw * 0.25,
            child: Container(
              width: sw * 0.7,
              height: sw * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0077B6).withOpacity(0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Crescent moon decorative top-left ──
          Positioned(
            top: sh * 0.06,
            left: sw * 0.04,
            child: Opacity(
              opacity: 0.07,
              child: Icon(
                Icons.nightlight_round,
                size: sw * 0.32,
                color: Colors.white,
              ),
            ),
          ),

          // ── Main Content ──
          SafeArea(
            child: BlocListener<LocationCubit, LocationState>(
              listener: (context, state) {


                if (state is LocationLoaded) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Location saved successfully ✅"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },

            child: BlocBuilder<LocationCubit, LocationState>(
              builder: (context, state) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.05,
                        vertical: sh * 0.015,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header ──
                          _buildHeader(sw),
                          SizedBox(height: sh * 0.035),

                          // ── Search Bar ──
                          _buildSearchBar(context, sw, sh),
                          SizedBox(height: sh * 0.025),

                          // ── Saved Location Card ──
                          if (state is LocationLoaded) ...[
                            _buildLocationCard(state.location, sw, sh),
                            SizedBox(height: sh * 0.02),

                            // ── GPS Button ──
                            _buildGPSButton(context, state, sw, sh),
                            SizedBox(height: sh * 0.03),
                          ],

                          // ── Loading Indicator ──
                          if (state is LocationLoading)
                            _buildLoadingState(sw, sh),

                          // ── Permission Denied ──
                          if (state is LocationPermissionDenied)
                            _buildPermissionDenied(sw),

                          // ── Search Results ──
                          if (state is LocationSearchResults)
                            _buildSearchResults(context, state, sw, sh),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  Widget _buildHeader(double sw) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(sw * 0.025),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(sw * 0.03),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: sw * 0.055,
            ),
          ),
        ),
        SizedBox(width: sw * 0.04),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Set Up Location",
              style: TextStyle(
                color: Colors.white,
                fontSize: sw * 0.065,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              "Find your city for prayer times",
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: sw * 0.035,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context, double sw, double sh) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(sw * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(sw * 0.04),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: searchController,
                onSubmitted: (value) =>
                    context.read<LocationCubit>().searchLocation(value),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: sw * 0.042,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: "Search your city...",
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: sw * 0.042,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: sw * 0.04, right: sw * 0.02),
                    child: Icon(
                      Icons.search_rounded,
                      color: const Color(0xFF00A86B),
                      size: sw * 0.055,
                    ),
                  ),
                  prefixIconConstraints: BoxConstraints(minWidth: sw * 0.13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: sh * 0.018,
                    horizontal: sw * 0.02,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: sw * 0.03),
          GestureDetector(
            onTap: () =>
                context.read<LocationCubit>().searchLocation(searchController.text),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: sh * 0.018,
                horizontal: sw * 0.05,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A86B), Color(0xFF007A4D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(sw * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A86B).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                "Search",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: sw * 0.042,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  Widget _buildLocationCard(LocationModel location, double sw, double sh) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: sw * 0.05,
        vertical: sh * 0.022,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00A86B).withOpacity(0.22),
            const Color(0xFF005F3B).withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(sw * 0.05),
        border: Border.all(
          color: const Color(0xFF00A86B).withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A86B).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: sw * 0.12,
            height: sw * 0.12,
            decoration: BoxDecoration(
              color: const Color(0xFF00A86B).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00A86B).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: const Color(0xFF4DFFA6),
              size: sw * 0.06,
            ),
          ),
          SizedBox(width: sw * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current Location",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: sw * 0.032,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: sh * 0.004),
                Text(
                  "${location.city}, ${location.country}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.052,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: sw * 0.03,
              vertical: sw * 0.015,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF00A86B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(sw * 0.02),
            ),
            child: Text(
              "Active",
              style: TextStyle(
                color: const Color(0xFF4DFFA6),
                fontSize: sw * 0.03,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  Widget _buildGPSButton(
      BuildContext context, LocationState state, double sw, double sh) {
    final isLoading = state is LocationLoading;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () => context.read<LocationCubit>().getGPSLocation(),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: sh * 0.02),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(sw * 0.04),
            border: Border.all(
              color: Colors.tealAccent.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: sw * 0.055,
                  height: sw * 0.055,
                  child: const CircularProgressIndicator(
                    color: Colors.tealAccent,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(
                  Icons.gps_fixed_rounded,
                  color: Colors.tealAccent,
                  size: sw * 0.055,
                ),
              SizedBox(width: sw * 0.03),
              Text(
                isLoading ? "Locating..." : "Use Current Location (GPS)",
                style: TextStyle(
                  color: isLoading
                      ? Colors.white.withOpacity(0.5)
                      : Colors.tealAccent,
                  fontSize: sw * 0.042,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  Widget _buildLoadingState(double sw, double sh) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: sw * 0.14,
              height: sw * 0.14,
              child: CircularProgressIndicator(
                color: const Color(0xFF00A86B),
                strokeWidth: 3,
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
            SizedBox(height: sh * 0.025),
            Text(
              "Detecting your location...",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: sw * 0.04,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  Widget _buildPermissionDenied(double sw) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sw * 0.06),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(sw * 0.05),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_rounded,
            color: Colors.redAccent.shade100,
            size: sw * 0.12,
          ),
          SizedBox(height: sw * 0.03),
          Text(
            "Location Permission Denied",
            style: TextStyle(
              color: Colors.white,
              fontSize: sw * 0.045,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sw * 0.015),
          Text(
            "Please enable GPS permission in your device cubit.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: sw * 0.037,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  Widget _buildSearchResults(
      BuildContext context, LocationSearchResults state, double sw, double sh) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: sh * 0.015, left: sw * 0.01),
            child: Text(
              "${state.results.length} result${state.results.length != 1 ? 's' : ''} found",
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: sw * 0.035,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: state.results.length,
              separatorBuilder: (_, __) => SizedBox(height: sh * 0.012),
              itemBuilder: (context, index) {
                final LocationModel loc = state.results[index];
                return GestureDetector(
                  onTap: () =>
                      context.read<LocationCubit>().selectLocation(loc),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.045,
                      vertical: sh * 0.018,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(sw * 0.04),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: sw * 0.1,
                          height: sw * 0.1,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A86B).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.place_rounded,
                            color: const Color(0xFF00A86B),
                            size: sw * 0.05,
                          ),
                        ),
                        SizedBox(width: sw * 0.04),
                        Expanded(
                          child: Text(
                            loc.city,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sw * 0.043,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withOpacity(0.3),
                          size: sw * 0.055,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}