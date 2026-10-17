#pragma once
#include <cmath>
#include <cstdint>

namespace PSY {

struct FVector {
    float X, Y, Z;
    FVector() : X(0), Y(0), Z(0) {}
    FVector(float x, float y, float z) : X(x), Y(y), Z(z) {}
    FVector operator+(const FVector& o) const { return {X+o.X, Y+o.Y, Z+o.Z}; }
    FVector operator-(const FVector& o) const { return {X-o.X, Y-o.Y, Z-o.Z}; }
    FVector operator*(float s) const { return {X*s, Y*s, Z*s}; }
    float Length() const { return std::sqrt(X*X + Y*Y + Z*Z); }
};

struct FRotator {
    float Pitch, Yaw, Roll;
};

struct FMinimalViewInfo {
    FVector   Location;
    FRotator  Rotation;
    float     FOV;
};

static inline FVector RotateVector(const FRotator& r, const FVector& v) {
    float SP = std::sin(r.Pitch * 3.14159265f/180.f), CP = std::cos(r.Pitch * 3.14159265f/180.f);
    float SY = std::sin(r.Yaw   * 3.14159265f/180.f), CY = std::cos(r.Yaw   * 3.14159265f/180.f);
    float SR = std::sin(r.Roll  * 3.14159265f/180.f), CR = std::cos(r.Roll  * 3.14159265f/180.f);

    FVector out;
    out.X = CP * CY * v.X + CP * SY * v.Y - SP * v.Z;
    out.Y = (SR*SP*CY - CR*SY) * v.X + (SR*SP*SY + CR*CY) * v.Y + SR*CP * v.Z;
    out.Z = (CR*SP*CY + SR*SY) * v.X + (CR*SP*SY - SR*CY) * v.Y + CR*CP * v.Z;
    return out;
}

static inline bool WorldToScreen(const FVector& world, const FMinimalViewInfo& pov, float screenW, float screenH, float& out_x, float& out_y) {
    FVector delta = world - pov.Location;
    FRotator inv = { -pov.Rotation.Pitch, -pov.Rotation.Yaw, -pov.Rotation.Roll };
    FVector cam = RotateVector(inv, delta);

    if (cam.X < 1.0f) return false;

    float fovRad = pov.FOV * 3.14159265f / 180.f;
    float focal = (screenH * 0.5f) / std::tan(fovRad * 0.5f);

    out_x = screenW * 0.5f + (cam.Y / cam.X) * focal;
    out_y = screenH * 0.5f - (cam.Z / cam.X) * focal;
    return true;
}
}
