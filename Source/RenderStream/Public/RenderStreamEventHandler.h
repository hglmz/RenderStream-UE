#pragma once

#include "CoreMinimal.h"
#include "RenderStreamEventHandler.generated.h"

USTRUCT(BlueprintType)
struct FStreamInfo
{
    GENERATED_USTRUCT_BODY()

    UPROPERTY(BlueprintReadOnly)
    FString Channel;

    UPROPERTY(BlueprintReadOnly)
    FString Name;

    UPROPERTY(BlueprintReadOnly)
    FBox2D Region;
};


DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FRenderStreamStreamsChangedEvent, const TArray<FStreamInfo>&, StreamInfo);

UCLASS(ClassGroup = (RenderStream), meta = (BlueprintSpawnableComponent))
class ARenderStreamEventHandler : public AActor
{
    GENERATED_BODY()

public:

    void onStreamsChanged(const TArray<FStreamInfo>& StreamInfo) { OnRenderStreamStreamsChanged.Broadcast(StreamInfo); }

protected:

    UPROPERTY(BlueprintAssignable)
    FRenderStreamStreamsChangedEvent OnRenderStreamStreamsChanged;

};
