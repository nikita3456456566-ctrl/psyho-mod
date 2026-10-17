#pragma once
#include <cstdint>

namespace PSY {
    constexpr uint64_t GEngine_Offset = 0x10ACEB420;

    namespace Engine {
        constexpr uint64_t UEngine_GameViewport = 0x0810;
        constexpr uint64_t GameViewport_World = 0x0078;

        constexpr uint64_t UWorld_PersistentLevel = 0x0030;
        constexpr uint64_t UWorld_OwningGameInstance = 0x0180;

        constexpr uint64_t GameInstance_LocalPlayers = 0x0048;
        constexpr uint64_t LocalPlayer_PlayerController = 0x0030;

        constexpr uint64_t PC_AcknowledgedPawn = 0x0528;
        constexpr uint64_t PC_PlayerCameraManager = 0x0548;

        constexpr uint64_t PS_PlayerName = 0x04B8;
        constexpr uint64_t PS_Score = 0x04AC;

        constexpr uint64_t CameraManager_CameraCache = 0x0520;
        constexpr uint64_t Camera_POV_Location = 0x0530;
        constexpr uint64_t Camera_POV_Rotation = 0x053C;
        constexpr uint64_t Camera_POV_FOV = 0x0548;

        constexpr uint64_t ULevel_Actors = 0x00A0;
        constexpr uint64_t AActor_RootComponent = 0x0208;
        constexpr uint64_t UScene_RelativeLocation = 0x01E4;
    }

    namespace STExtra {
        constexpr uint64_t Character_Health = 0x0E60;
        constexpr uint64_t Character_HealthMax = 0x0E64;
        constexpr uint64_t BaseCharacter_PlayerState = 0x2410;
    }
}
