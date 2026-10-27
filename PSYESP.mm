#include <string>
#import "PSYESP.h"
#import "PSYOffsets.hpp"
#import "PSYMemory.hpp"
#import "PSYMath.hpp"
#import <mach-o/dyld.h>
#import <QuartzCore/QuartzCore.h>

using namespace PSY;

// --- Утилита для чтения FString (никнейма) ---
std::string ReadFString(uint64_t address) {
    struct FString {
        wchar_t* Data;
        int32_t Count;
        int32_t Max;
    } str;
    
    if (!Memory::Read(address, &str, sizeof(FString))) return "";
    if (!str.Data || str.Count <= 0 || str.Count > 50) return "";
    
    wchar_t* buffer = new wchar_t[str.Count + 1];
    if (!Memory::Read((uint64_t)str.Data, buffer, str.Count * sizeof(wchar_t))) {
        delete[] buffer;
        return "";
    }
    buffer[str.Count] = 0;
    
    // Конвертация wchar_t в std::string (UTF-8)
    NSString *nsStr = [NSString stringWithCharacters:(const unichar*)buffer length:str.Count];
    std::string result = [nsStr UTF8String];
    delete[] buffer;
    return result;
}

// --- Структура для хранения UI-элементов одного игрока ---
@interface ESPPlayerUI : NSObject
@property (nonatomic, strong) CAShapeLayer *boxLayer;
@property (nonatomic, strong) CAShapeLayer *lineLayer;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *distLabel;
@property (nonatomic, strong) UIView *healthBarBg;
@property (nonatomic, strong) UIView *healthBarFill;
@end

@implementation ESPPlayerUI
@end

// --- Основной класс ---
@interface PSYESP ()
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) NSMutableArray<ESPPlayerUI*> *uiPool;
@property (nonatomic, assign) uint64_t gameBase;
@property (nonatomic, assign) int frameCounter;
@property (nonatomic, strong) UILabel *debugLabel;
@end

@implementation PSYESP

+ (instancetype)shared {
    static PSYESP *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PSYESP alloc] initWithFrame:[UIScreen mainScreen].bounds];
    });
    return instance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO; // Пропускаем тапы сквозь ESP
        self.backgroundColor = [UIColor clearColor];
        
        _uiPool = [NSMutableArray array];
        
        // Создаем пул из 30 объектов для отрисовки
        for (int i = 0; i < 30; i++) {
            ESPPlayerUI *ui = [[ESPPlayerUI alloc] init];
            
            // Бокс
            ui.boxLayer = [CAShapeLayer layer];
            ui.boxLayer.fillColor = [UIColor clearColor].CGColor;
            ui.boxLayer.strokeColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8].CGColor; // Красный
            ui.boxLayer.lineWidth = 1.0;
            [self.layer addSublayer:ui.boxLayer];
            
            // Линия (Snapline)
            ui.lineLayer = [CAShapeLayer layer];
            ui.lineLayer.fillColor = [UIColor clearColor].CGColor;
            ui.lineLayer.strokeColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3].CGColor;
            ui.lineLayer.lineWidth = 1.0;
            [self.layer addSublayer:ui.lineLayer];
            
            // Ник
            ui.nameLabel = [[UILabel alloc] init];
            ui.nameLabel.textColor = [UIColor whiteColor];
            ui.nameLabel.font = [UIFont boldSystemFontOfSize:10];
            ui.nameLabel.textAlignment = NSTextAlignmentCenter;
            ui.nameLabel.layer.shadowColor = [UIColor blackColor].CGColor;
            ui.nameLabel.layer.shadowRadius = 2.0;
            ui.nameLabel.layer.shadowOpacity = 1.0;
            [self addSubview:ui.nameLabel];
            
            // Дистанция
            ui.distLabel = [[UILabel alloc] init];
            ui.distLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
            ui.distLabel.font = [UIFont systemFontOfSize:9];
            ui.distLabel.textAlignment = NSTextAlignmentCenter;
            ui.distLabel.layer.shadowColor = [UIColor blackColor].CGColor;
            ui.distLabel.layer.shadowRadius = 2.0;
            ui.distLabel.layer.shadowOpacity = 1.0;
            [self addSubview:ui.distLabel];
            
            // ХП бар (Фон)
            ui.healthBarBg = [[UIView alloc] init];
            ui.healthBarBg.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
            [self addSubview:ui.healthBarBg];
            
            // ХП бар (Заполнение)
            ui.healthBarFill = [[UIView alloc] init];
            ui.healthBarFill.backgroundColor = [UIColor greenColor];
            [ui.healthBarBg addSubview:ui.healthBarFill];
            
            // Изначально скрываем
            ui.boxLayer.hidden = YES;
            ui.lineLayer.hidden = YES;
            ui.nameLabel.hidden = YES;
            ui.distLabel.hidden = YES;
            ui.healthBarBg.hidden = YES;
            
            [_uiPool addObject:ui];
        }
        
        // Создаем отладочный лейбл
        self.debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 350, 120)];
        self.debugLabel.numberOfLines = 0;
        self.debugLabel.textColor = [UIColor yellowColor];
        self.debugLabel.font = [UIFont boldSystemFontOfSize:14];
        self.debugLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        [self addSubview:self.debugLabel];

        _gameBase = _dyld_get_image_vmaddr_slide(0);
    }
    return self;
}

- (void)start {
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stop {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)tick {
    self.frameCounter++;
    if (self.frameCounter % 4 != 0) return;

    // Скрываем все перед обновлением
    for (ESPPlayerUI *ui in self.uiPool) {
        ui.boxLayer.hidden = YES;
        ui.lineLayer.hidden = YES;
        ui.nameLabel.hidden = YES;
        ui.distLabel.hidden = YES;
        ui.healthBarBg.hidden = YES;
    }

    if (!self.gameBase) return;

    NSString *dbg = [NSString stringWithFormat:@"Base: %llx\n", self.gameBase];

    // 1. GEngine
    uint64_t gEngine = Memory::Read<uint64_t>(self.gameBase + Engine::GEngine_Offset);
    dbg = [dbg stringByAppendingFormat:@"GEngine: %llx\n", gEngine];
    if (!gEngine) { self.debugLabel.text = dbg; return; }

    // 2. Viewport
    uint64_t gameViewport = Memory::Read<uint64_t>(gEngine + Engine::UEngine_GameViewport);
    dbg = [dbg stringByAppendingFormat:@"Viewport: %llx\n", gameViewport];
    if (!gameViewport) { self.debugLabel.text = dbg; return; }

    // 3. World
    uint64_t uWorld = Memory::Read<uint64_t>(gameViewport + Engine::GameViewport_World);
    dbg = [dbg stringByAppendingFormat:@"World: %llx\n", uWorld];
    if (!uWorld) { self.debugLabel.text = dbg; return; }

    // 4. Level
    uint64_t persistentLevel = Memory::Read<uint64_t>(uWorld + Engine::UWorld_PersistentLevel);
    dbg = [dbg stringByAppendingFormat:@"Level: %llx\n", persistentLevel];
    if (!persistentLevel) { self.debugLabel.text = dbg; return; }

    // 5. Actors
    uint64_t actorsData = Memory::Read<uint64_t>(persistentLevel + Engine::ULevel_Actors);
    int32_t actorsCount = Memory::Read<int32_t>(persistentLevel + Engine::ULevel_Actors + 0x8);
    dbg = [dbg stringByAppendingFormat:@"Actors: %d\n", actorsCount];
    
    // Выводим финальный результат на экран
    self.debugLabel.text = dbg;

    if (!actorsData || actorsCount <= 0 || actorsCount > 10000) return;

    // --- ДАЛЬШЕ ИДЕТ КАМЕРА И ОТРИСОВКА ---
    uint64_t gameInstance = Memory::Read<uint64_t>(uWorld + Engine::UWorld_OwningGameInstance);
    if (!gameInstance) return;
    uint64_t localPlayers = Memory::Read<uint64_t>(gameInstance + Engine::GameInstance_LocalPlayers);
    if (!localPlayers) return;
    uint64_t localPlayer = Memory::Read<uint64_t>(localPlayers);
    if (!localPlayer) return;
    uint64_t pc = Memory::Read<uint64_t>(localPlayer + Engine::LocalPlayer_PlayerController);
    if (!pc) return;
    uint64_t camMgr = Memory::Read<uint64_t>(pc + Engine::PC_PlayerCameraManager);
    if (!camMgr) return;

    FMinimalViewInfo pov;
    Memory::Read(camMgr + Engine::Camera_POV_Location, &pov.Location, sizeof(FVector));
    Memory::Read(camMgr + Engine::Camera_POV_Rotation, &pov.Rotation, sizeof(FRotator));
    Memory::Read(camMgr + Engine::Camera_POV_FOV, &pov.FOV, sizeof(float));

    float screenW = self.bounds.size.width;
    float screenH = self.bounds.size.height;
    int uiIndex = 0;

    for (int i = 0; i < actorsCount; i++) {
        uint64_t actor = Memory::Read<uint64_t>(actorsData + (i * 8));
        if (!actor) continue;

        float health = Memory::Read<float>(actor + STExtra::Character_Health);
        float maxHealth = Memory::Read<float>(actor + STExtra::Character_HealthMax);
        
        if (health <= 0.0f || health > 100.0f || maxHealth <= 0.0f) continue;

        uint64_t rootComp = Memory::Read<uint64_t>(actor + Engine::AActor_RootComponent);
        if (!rootComp) continue;

        FVector worldPos;
        Memory::Read(rootComp + Engine::UScene_RelativeLocation, &worldPos, sizeof(FVector));

        float distMeters = (pov.Location - worldPos).Length() / 100.0f;
        if (distMeters > 400.0f) continue;

        float sx, sy;
        if (WorldToScreen(worldPos, pov, screenW, screenH, sx, sy)) {
            if (uiIndex >= self.uiPool.count) break;
            ESPPlayerUI *ui = self.uiPool[uiIndex];
            
            float boxH = 1050.0f / distMeters;
            float boxW = boxH / 2.0f;
            
            float boxX = sx - (boxW / 2.0f);
            float boxY = sy - boxH;

            // 1. Бокс
            UIBezierPath *boxPath = [UIBezierPath bezierPathWithRect:CGRectMake(boxX, boxY, boxW, boxH)];
            ui.boxLayer.path = boxPath.CGPath;
            ui.boxLayer.hidden = NO;

            // 2. Никнейм
            uint64_t playerState = Memory::Read<uint64_t>(actor + STExtra::BaseCharacter_PlayerState);
            if (playerState) {
                std::string nameStr = ReadFString(playerState + Engine::PS_PlayerName);
                NSString *name = [NSString stringWithUTF8String:nameStr.c_str()];
                if (name.length > 0) {
                    ui.nameLabel.text = name;
                    [ui.nameLabel sizeToFit];
                    ui.nameLabel.center = CGPointMake(sx, boxY - 20); 
                    ui.nameLabel.hidden = NO;
                }
            }

            // 3. ХП-бар
            float hpPct = health / maxHealth;
            CGFloat hpY = boxY - 8;
            ui.healthBarBg.frame = CGRectMake(boxX, hpY, boxW, 4);
            ui.healthBarBg.hidden = NO;
            
            UIColor *hpColor = [UIColor greenColor];
            if (hpPct < 0.2f) hpColor = [UIColor redColor];
            else if (hpPct < 0.5f) hpColor = [UIColor yellowColor];
            
            ui.healthBarFill.backgroundColor = hpColor;
            ui.healthBarFill.frame = CGRectMake(0, 0, boxW * hpPct, 4);

            // 4. Дистанция
            ui.distLabel.text = [NSString stringWithFormat:@"%dm", (int)distMeters];
            [ui.distLabel sizeToFit];
            ui.distLabel.center = CGPointMake(sx, boxY + boxH + 10); 
            ui.distLabel.hidden = NO;

            // 5. Линия
            UIBezierPath *linePath = [UIBezierPath bezierPath];
            [linePath moveToPoint:CGPointMake(screenW / 2.0f, 0)];
            [linePath addLineToPoint:CGPointMake(sx, boxY - 28)]; 
            ui.lineLayer.path = linePath.CGPath;
            ui.lineLayer.hidden = NO;

            uiIndex++;
        }
    }
}

@end
