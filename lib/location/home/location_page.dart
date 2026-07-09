import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/location/cubit/location_cubit.dart';
import 'package:muslim_app/location/cubit/location_state.dart';
import 'package:muslim_app/location/model/location_model.dart';

import '../../settings/cubit/settings_cubit.dart';
import '../../settings/cubit/settings_state.dart';
import '../../settings/l10n/app_localizations.dart';
import '../../settings/theme/app_themes.dart';

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

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        final theme = getThemeById(settings.themeMode);
        final l10n = AppLocalizations(settings.languageCode);

        return Scaffold(
          backgroundColor: theme.background,
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
                        theme.accent.withOpacity(0.18),
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
                        theme.primary.withOpacity(0.14),
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
                    color: theme.textHigh,
                  ),
                ),
              ),

              // ── Main Content ──
              SafeArea(
                child: BlocBuilder<LocationCubit, LocationState>(
                  builder: (context, state) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // ── All scrollable content ──
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: sw * 0.05,
                                  vertical: sh * 0.015,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeader(sw, l10n, theme),
                                    SizedBox(height: sh * 0.035),
                                    _buildSearchBar(context, sw, sh, l10n, theme),
                                    SizedBox(height: sh * 0.025),

                                    if (state is LocationLoaded) ...[
                                      _buildLocationCard(state.location, sw, sh, l10n, theme),
                                      SizedBox(height: sh * 0.02),
                                      _buildGPSButton(context, state, sw, sh, l10n, theme),
                                    ],

                                    if (state is LocationLoading)
                                      _buildLoadingState(sw, sh, l10n, theme),

                                    if (state is LocationPermissionDenied)
                                      _buildPermissionDenied(sw, l10n, theme),

                                    if (state is LocationSearchResults)
                                      _buildSearchResults(context, state, sw, sh, l10n, theme),
                                  ],
                                ),
                              ),
                            ),

                            // ── Pinned Save button at bottom ──
                            if (state is LocationLoaded)
                              Container(
                                padding: EdgeInsets.fromLTRB(
                                  sw * 0.05,
                                  sw * 0.025,
                                  sw * 0.05,
                                  sw * 0.035,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.background,
                                  border: Border(
                                    top: BorderSide(
                                      color: theme.textLow.withOpacity(0.12),
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                child: _buildSaveButton(context, state, sw, sh, l10n, theme),
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
      },
    );
  }

  // ────────────────────────────────────────────────
  Widget _buildHeader(double sw, AppLocalizations l10n, AppThemeOption theme) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(sw * 0.025),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(sw * 0.03),
              border: Border.all(
                color: theme.accent.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.textHigh,
              size: sw * 0.055,
            ),
          ),
        ),
        SizedBox(width: sw * 0.04),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.setUpLocation,
              style: TextStyle(
                color: theme.textHigh,
                fontSize: sw * 0.065,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              l10n.findCityForPrayerTimes,
              style: TextStyle(
                color: theme.textLow,
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
  Widget _buildSearchBar(BuildContext context, double sw, double sh, AppLocalizations l10n, AppThemeOption theme) {
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
                color: theme.surface,
                borderRadius: BorderRadius.circular(sw * 0.04),
                border: Border.all(
                  color: theme.accent.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: searchController,
                onSubmitted: (value) =>
                    context.read<LocationCubit>().searchLocation(value),
                style: TextStyle(
                  color: theme.textHigh,
                  fontSize: sw * 0.042,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: l10n.searchYourCity,
                  hintStyle: TextStyle(
                    color: theme.textLow,
                    fontSize: sw * 0.042,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: sw * 0.04, right: sw * 0.02),
                    child: Icon(
                      Icons.search_rounded,
                      color: theme.accent,
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
                gradient: LinearGradient(
                  colors: [theme.accent, theme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(sw * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: theme.accent.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                l10n.search,
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
  Widget _buildLocationCard(LocationModel location, double sw, double sh, AppLocalizations l10n, AppThemeOption theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: sw * 0.05,
        vertical: sh * 0.022,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.accent.withOpacity(0.22),
            theme.primary.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(sw * 0.05),
        border: Border.all(
          color: theme.accent.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withOpacity(0.12),
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
              color: theme.accent.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.accent.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: theme.accent,
              size: sw * 0.06,
            ),
          ),
          SizedBox(width: sw * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentLocation,
                  style: TextStyle(
                    color: theme.textLow,
                    fontSize: sw * 0.032,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: sh * 0.004),
                Text(
                  "${location.city}, ${location.country}",
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textHigh,
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
              color: theme.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(sw * 0.02),
            ),
            child: Text(
              l10n.activeBadge,
              style: TextStyle(
                color: theme.accent,
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
      BuildContext context, LocationState state, double sw, double sh, AppLocalizations l10n, AppThemeOption theme) {
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
            color: theme.surface,
            borderRadius: BorderRadius.circular(sw * 0.04),
            border: Border.all(
              color: theme.accent.withOpacity(0.30),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.accent.withOpacity(0.1),
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
                  child: CircularProgressIndicator(
                    color: theme.accent,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(
                  Icons.gps_fixed_rounded,
                  color: theme.accent,
                  size: sw * 0.055,
                ),
              SizedBox(width: sw * 0.03),
              Text(
                isLoading ? l10n.loading : l10n.useCurrentLocationGps,
                style: TextStyle(
                  color: isLoading
                      ? theme.textLow
                      : theme.accent,
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
  Widget _buildLoadingState(double sw, double sh, AppLocalizations l10n, AppThemeOption theme) {
    return SizedBox(
      height: sh * 0.5,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: sw * 0.14,
              height: sw * 0.14,
              child: CircularProgressIndicator(
                color: theme.accent,
                strokeWidth: 3,
                backgroundColor: theme.textLow.withOpacity(0.1),
              ),
            ),
            SizedBox(height: sh * 0.025),
            Text(
              l10n.detectingYourLocation,
              style: TextStyle(
                color: theme.textLow,
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
  Widget _buildPermissionDenied(double sw, AppLocalizations l10n, AppThemeOption theme) {
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
            l10n.locationPermissionDeniedTitle,
            style: TextStyle(
              color: theme.textHigh,
              fontSize: sw * 0.045,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sw * 0.015),
          Text(
            l10n.enableGpsPermissionDesc,
            style: TextStyle(
              color: theme.textLow,
              fontSize: sw * 0.037,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildSaveButton(BuildContext context, LocationState state, double sw, double sh, AppLocalizations l10n, AppThemeOption theme) {
    if (state is! LocationLoaded) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () async {
          await context.read<LocationCubit>().saveCurrentLocation();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.locationSavedSuccessfully),
              backgroundColor: theme.accent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: sh * 0.02),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.accent, theme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(sw * 0.04),
            boxShadow: [
              BoxShadow(
                color: theme.accent.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              l10n.save,
              style: TextStyle(
                color: Colors.white,
                fontSize: sw * 0.045,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ────────────────────────────────────────────────
  Widget _buildSearchResults(
      BuildContext context, LocationSearchResults state, double sw, double sh, AppLocalizations l10n, AppThemeOption theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: sh * 0.015, left: sw * 0.01),
          child: Text(
            "${state.results.length} ${l10n.result}${state.results.length != 1 ? 's' : ''} ${l10n.found}",
            style: TextStyle(
              color: theme.textLow,
              fontSize: sw * 0.035,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(sw * 0.04),
                  border: Border.all(
                    color: theme.accent.withOpacity(0.10),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: sw * 0.1,
                      height: sw * 0.1,
                      decoration: BoxDecoration(
                        color: theme.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.place_rounded,
                        color: theme.accent,
                        size: sw * 0.05,
                      ),
                    ),
                    SizedBox(width: sw * 0.04),
                    Expanded(
                      child: Text(
                        loc.city,
                        style: TextStyle(
                          color: theme.textHigh,
                          fontSize: sw * 0.043,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.textLow.withOpacity(0.6),
                      size: sw * 0.055,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}