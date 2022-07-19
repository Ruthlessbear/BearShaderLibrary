Shader "LkqShader/Fresnel/Scan1"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _RimMin("RimMin", Range(-1, 1)) = 0.0
        _RimMax("RimMax", Range(0, 2)) = 1.0
        _InnerColor("Inner Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimIntensity("Rim Intensity", Float) = 1.0
        _FlowTilling("Flow Tilling", Vector) = (1, 1, 0, 0)
        _FlowSpeed("Flow Speed", Vector) = (1, 1, 0, 0)
        _FlowTex("Flow Tex", 2D) = "white"{}
        _FlowIntensity("Flow Intensity", Float) = 0.5
        _InnerAlpha("Inner Alpha", Range(0.0, 1.0)) = 0.0
    }
    SubShader
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Transparent"
        }

        Cull Off
        ZWrite Off
        Blend SrcAlpha One

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float _RimMin;
        float _RimMax;
        float4 _InnerColor;
        float4 _RimColor;
        float _RimIntensity;
        float4 _FlowTilling;
        float4 _FlowSpeed;
        float _FlowIntensity;
        float _InnerAlpha;
        float4 _MainTex_ST;
        float4 _FlowTex_ST;
        CBUFFER_END
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_FlowTex);
        SAMPLER(sampler_FlowTex);

        struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 pos : SV_POSITION;
            float3 pos_world : TEXCOORD1;
            float3 normal_world : TEXCOORD2;
            float3 pivot_world : TEXCOORD3;
        };

        v2f Vert(appdata v)
        {
            v2f o;
            o.pos = TransformObjectToHClip(v.vertex);
            o.pos_world = TransformObjectToWorld(v.vertex);
            o.normal_world = TransformObjectToWorldNormal(v.normal);
            o.pivot_world = TransformObjectToWorld(float3(0.0 ,0.0, 0.0));
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            
            return o;
        }

        float4 Frag(v2f i) : SV_TARGET
        {
            half3 normal_world = normalize(i.normal_world);
            half3 view_world = (_WorldSpaceCameraPos - i.pos_world);

            half NdotV = saturate(dot(normal_world, view_world));
            half fresnal = 1.0 - NdotV;
            fresnal = smoothstep(_RimMin, _RimMax, fresnal);
            half emiss = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).r;
            emiss = pow(emiss, 5.0);

            half final_fresnal = saturate(fresnal + emiss);

            half3 final_rim_color = lerp(_InnerColor.xyz, _RimColor.xyz * _RimIntensity, fresnal);
            half final_rim_alpha = final_fresnal;
            
            //流光
            //世界坐标系下顶点-世界坐标下模型空间原点
            half2 uv_scan = (i.pos_world.xy - i.pivot_world.xy) * _FlowTilling.xy;
            uv_scan = uv_scan + _Time.y * _FlowSpeed.xy;
            float4 flow_color = SAMPLE_TEXTURE2D(_FlowTex, sampler_FlowTex, uv_scan) * _FlowIntensity;
            
            float3 final_col = final_rim_color + flow_color.xyz;
            float final_alpha = saturate(final_rim_alpha + flow_color.a + _InnerAlpha);
            return float4(final_col, final_alpha);
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
