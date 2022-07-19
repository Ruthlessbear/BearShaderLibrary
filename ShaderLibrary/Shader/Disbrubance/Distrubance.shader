Shader "LkqShader/Distrubance/Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex("Noise Texture", 2D) = "white"{}
        _DistrubanceSpeed("Distrubance Speed", Range(0.01,1)) = 0.05
        _XOffset("X Offset", Range(-1, 1)) = 0
        _YOffset("Y Offset", Range(-1, 1)) = 0
        _WaterSpeed("Water Speed", Range(0.04, 1)) = 0.05 
        _BlendColor("Blend Color", COLOR) = (1,1,1,1)
    }
    SubShader
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Transparent"
        }

        Cull Off
        ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"    

        CBUFFER_START(UnityPerMaterial)
            float _DistrubanceSpeed;
            float _XOffset;
            float _YOffset;
            float4 _BlendColor;
            float4 _MainTex_ST;
            float4 _NoiseTex_ST;
            float _WaterSpeed;
        CBUFFER_END
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_NoiseTex);
        SAMPLER(sampler_NoiseTex);



        struct appdata{
            float4 position:POSITION;
            float2 uv:TEXCOORD0;
        };

        struct v2f{
            float4 position:SV_POSITION;
            float2 uv:TEXCOORD0;
        };

        v2f Vert(appdata v)
        {
            v2f o;
            o.position = TransformObjectToHClip(v.position);
            o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
            //可按一定比例增加偏移量，水流方向
            o.uv += float2(_XOffset, _YOffset) * _Time.y;
            return o;
        }

        float4 Frag(v2f i):SV_TARGET
        {
            //对噪声图偏移采样，_DistrubanceSpeed控制噪声采样幅度 对应波纹抖动幅度
            float2 noise_uv = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv + _Time.xy * _DistrubanceSpeed).xy;
            //根据偏移量采样原贴图，_WaterSpeed控制水流采样幅度，越大越凝集
            float4 result_color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + noise_uv * _WaterSpeed);
            //可以混合颜色
            return result_color * _BlendColor;
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
