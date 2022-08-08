Shader "LkqShader/Shadow/InvertedShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex("Noise Texture", 2D) = "white"{}
        _NoiseFacter("Noise Facter", float) = 0.1
    }
    SubShader
    {
        Tags 
        { 
        "RenderPipeline" = "UniversalRenderPipeline"
        "RenderType"= "Opaque"
        "Queue" = "Geometry"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _NoiseTex_ST;
            float _NoiseFacter;
        CBUFFER_END
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_NoiseTex);
        SAMPLER(sampler_NoiseTex);

        struct appdata{
            float4 position:POSITION;
            float2 uv:TEXCOORD;
        };

        struct v2f{
            float4 position:SV_POSITION;
            float4 uv:TEXCOORD;
        };

        v2f Vert(appdata i)
        {
            v2f o;
            o.position = TransformObjectToHClip(i.position);
            o.uv.xy = TRANSFORM_TEX(i.uv, _MainTex);
            o.uv.zw = TRANSFORM_TEX(i.uv, _NoiseTex);

            return o;
        }

        float4 Frag(v2f i):SV_TARGET
        {
            float4 noise_tex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv + _Time.y * _NoiseFacter * float2(1.0f,0.0f));
            float2 floatUV = float2(0.03f, 0) * noise_tex.xy;//可以自定义变量拿系数控制
            float2 shadow_uv = float2(i.uv.x, i.uv.y * -1.0f + 1.0f);//将uv从0,1 变成 1,0
            float4 shadow_tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, shadow_uv + floatUV);//加上偏移扭动采样
            float4 main_tex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, shadow_uv);//原采样
            float4 final = lerp(main_tex, shadow_tex, main_tex.a);//线性插值采样

            return final;
        }

        ENDHLSL
        
        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag
            ENDHLSL
        }
    }
}
