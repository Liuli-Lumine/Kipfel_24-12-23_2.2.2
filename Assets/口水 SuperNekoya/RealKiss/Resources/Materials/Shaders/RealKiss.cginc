#include "UnityShaderVariables.cginc"

// #define REALKISS_DPS_IMPL true

#ifdef REALKISS_DPS_IMPL
#include "Assets/RalivDynamicPenetrationSystem/Plugins/RalivDPS_Functions.cginc"
#endif

#define REALKISS_EPS 0.001
#define REALKISS_LENGTH_MAX 20
#define IS_KISS_SYSTEM_OK(LIGHT_CHECK_RESULT) (length(LIGHT_CHECK_RESULT) > REALKISS_EPS && length(LIGHT_CHECK_RESULT) < REALKISS_LENGTH_MAX)

struct RealKissParameters
{
    float gravitySize;
    float4 pointA;
    float4 pointB;
};

#ifdef REALKISS_DPS_IMPL
void realkiss_light_position(inout float3 light_position, in int orificeChannel)
{
    int orificeType;
    float3 noop1;
    float3 noop2;
    float noop3;
    
    GetBestLights(orificeChannel, orificeType, light_position, noop1, noop2, noop3);
}
#else

#define REALKISS_COLOR_EPS 0.01
#define IS_KISS_SYSTEM_LIGHT_COLOR_COMPONENT(COLOR_COMPONENT) (COLOR_COMPONENT < REALKISS_COLOR_EPS && COLOR_COMPONENT != 0)
#define IS_KISS_SYSTEM_LIGHT(LIGHT_ID) (IS_KISS_SYSTEM_LIGHT_COLOR_COMPONENT(unity_LightColor[LIGHT_ID].r) && IS_KISS_SYSTEM_LIGHT_COLOR_COMPONENT(unity_LightColor[LIGHT_ID].g) && IS_KISS_SYSTEM_LIGHT_COLOR_COMPONENT(unity_LightColor[LIGHT_ID].b) && length(mul(unity_WorldToObject, float4(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i], 1))) < REALKISS_LENGTH_MAX)

void realkiss_light_position(inout float3 light_position, in int orificeChannel)
{
    light_position = float3(0, 0, 0);
    for(int i = 3; i >= 0; i--)
    {
        if (IS_KISS_SYSTEM_LIGHT(i))
        {
            light_position = mul(unity_WorldToObject, float4(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i], 1)).xyz;
        }
    }
}
#endif

void realkiss_vert(inout float4 vertex, in float weight, in float gravitySize, in float4 pointA, in float4 pointB, in int orificeChannel)
{
    float3 light_position;
    realkiss_light_position(light_position, orificeChannel);
    const float3 originA = pointA.xyz;
    const float3 originB = pointB.xyz;
    const float weightA = clamp(1 - weight, 0, 1);
    const float weightB = clamp(weight, 0, 1);
    const float3 boneALocalPosition = vertex.xyz - originA;
    const float3 boneBLocalPosition = vertex.xyz - originB;

    const float3 a = float3(0, 0, 0);
    const float3 b = light_position;

    
    if (IS_KISS_SYSTEM_OK(light_position))
    {
        vertex = float4((boneALocalPosition + a) * weightA + (boneBLocalPosition + b) * weightB, 1);

        // 重力シミュレーション
        const float a = 2.1268;
        const float gravityAtten = (cosh(a * (weightB * 2 - 1)) / a - 1 - 1) * gravitySize;
        //const float gravityAtten = (pow(weightB * 2 - 1, 2) - 1) * gravitySize;
        const float3 gravityVector = mul((float3x3)unity_WorldToObject, float3(0, 1, 0));
        vertex += float4(gravityVector * gravityAtten, 0);
    } else {
        vertex.xyz = float3(0, 0, 0);
    }
}
