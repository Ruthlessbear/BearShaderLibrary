Shader "LkqShader/AlphaRender/TwoPanelAlpha"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1, 1, 1, 1)
        _AlphaScale("Alpha Scale", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags
        { 
        "RenderPipeline" = "UniversalRenderPipeline"
        "Queue" = "Transparent" 
        "RenderType" = "Transparent"
        }
       
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  

        CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float _AlphaScale;
            float4 _MainTex_ST;
        CBUFFER_END
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct appdata
        {
            float4 position:POSITION;
            float2 uv:TEXCOORD0;
        };

        struct v2f
        {
            float4 position:SV_POSITION;
            float2 uv:TEXCOORD0;
        };

        v2f Vert(appdata v)
        {
            v2f o;
            o.position = TransformObjectToHClip(v.position);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);

            return o;
        } 

        float4 Frag(v2f i):SV_TARGET
        {
            float4 tex_color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

            return float4(tex_color.xyz, _AlphaScale) * _Color;
        }

        ENDHLSL

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

            Cull Front
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode" = "SRPDefaultUnlit"}

            Cull Back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            ENDHLSL
        }
    }
}
