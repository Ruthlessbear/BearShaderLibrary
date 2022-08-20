Shader "LkqShader/Parallax/ParallaxMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ParallaxTex ("_Parallax Map", 2D) = "white"{}
        _NormalTex ("Normal Map", 2D) = "white"{}
        _MainColor ("Main Color",Color) = (0, 0, 0, 0)
        _ParallaxStrength("Parallax Strength", Range(0.0, 3)) = 0.5
    }
    SubShader
    {
        Tags 
        { 
        "RenderPipeline" = "UniversalRenderPipeline"
        "RenderType"="Opaque" 
        "Queue" = "Geometry"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float _ParallaxStrength;
            float4 _MainColor;
            float4 _MainTex_ST;
            float4 _ParallaxTex_ST;
            float4 _NormalTex_ST;
        CBUFFER_END
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_ParallaxTex);
        SAMPLER(sampler_ParallaxTex);
        TEXTURE2D(_NormalTex);
        SAMPLER(sampler_NormalTex);

        struct a2v{
            float4 position : POSITION;
            float2 uv : TEXCOORD0;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
        };

        struct v2f{
            float4 position:SV_POSITION;
            float4 uv : TEXCOORD0;
            float3x3 tbn : TEXCOORD1;
            float3 positionWS : TEXCOORD4;
        };

        v2f Vert(a2v v)
        {
            v2f o;
            o.position = TransformObjectToHClip(v.position);
            o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
            o.uv.zw = TRANSFORM_TEX(v.uv, _ParallaxTex);
            o.tbn = float3x3(
                v.tangent.xyz,
                cross(v.tangent, v.normal) * v.tangent.w,
                v.normal
            );
            o.positionWS = TransformObjectToWorld(v.position);

            return o;
        }

        float4 Frag(v2f v) : SV_TARGET0
        {
            float4 parallax_tex = SAMPLE_TEXTURE2D(_ParallaxTex, sampler_ParallaxTex, v.uv.zw);
            float4 normal_tex = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, v.uv.zw);
            float3 normalTS = UnpackNormal(normal_tex);
            Light mainLight = GetMainLight();
            float3 lightDir = normalize(mainLight.direction);
            float3 lightColor = mainLight.color;
            //float3 normalWS = mul(normalTS, v.tbn);
            float3 lightDir_Ts = mul(v.tbn, lightDir);
            float diffuseFactor = saturate(dot(normalize(normalTS), lightDir_Ts));
            //计算投影偏移量
            float3 world_dir = normalize(_WorldSpaceCameraPos.xyz - v.positionWS);
            float3 view_dir = mul(v.tbn, world_dir);
            float2 new_uv = (view_dir.xy / (view_dir.z + 0.42)) * _ParallaxStrength * parallax_tex.g + v.uv.xy;
            
            float4 main_tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, new_uv);

            //计算漫反射
            float4 diffuseColor = (diffuseFactor * 0.5 + 0.5) * main_tex * float4(lightColor.xyz, 1);

            return diffuseColor + _MainColor;
        }

        ENDHLSL

        Pass
        {
           HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag
           ENDHLSL
        }
    }
}
