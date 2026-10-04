local ls = require("luasnip")
local s, i = ls.snippet, ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s(
        "ueprop",
        fmt("UPROPERTY({})\n{} {};", {
            i(1, 'EditAnywhere, BlueprintReadWrite, Category = "Gameplay"'),
            i(2, "float"),
            i(0, "Speed = 600.0f"),
        })
    ),
    s(
        "uefunc",
        fmt("UFUNCTION({})\n{} {}({});", {
            i(1, 'BlueprintCallable, Category = "Gameplay"'),
            i(2, "void"),
            i(3, "DoAction"),
            i(0, ""),
        })
    ),
    s("uelog", fmt('UE_LOG(LogTemp, {}, TEXT("{}"));', { i(1, "Log"), i(0, "Message") })),
    s(
        "ueactor",
        fmt(
            [[#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "{}.generated.h"

UCLASS()
class {} A{} : public AActor
{{
GENERATED_BODY()

public:
A{}();

protected:
virtual void BeginPlay() override;
{}
}};
]],
            { i(1, "MyActor"), i(2, "MYGAME_API"), i(3, "MyActor"), i(4, "MyActor"), i(0, "") }
        )
    ),
}
