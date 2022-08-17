Shader "LkqShader/Blur/GaussianBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurFactor("Blur Factor", Range(0, 20)) = 1
    }
    SubShader
    {
        Tags 
        { 
        "RenderPipeline"="UniversalRenderPipeline" 
        "RenderType" = "Opaque"
        "Queue" = "Geometry"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  

        CBUFFER_START(UnityPerMaterial)
            float _BlurFactor;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
        CBUFFER_END
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        
        struct appdata{
            float4 position:POSITION;
            float2 uv:TEXCOORD;
        };

        struct v2f{
            float4 position:SV_POSITION;
            float2 uv:TEXCOORD;
        };

        v2f Vert(appdata v)
        {
            v2f o;
            o.position = TransformObjectToHClip(v.position);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);

            return o;
        }

        float4 Frag(v2f v):SV_TARGET
        {
            float width[3] = {
                6,
                4,
                1
            };

            float4 tex = float4(0, 0, 0, 0);
            
            for(int i = -2; i <= 2; i++)
            {
                for(int j = -2; j <= 2; j++)
                {
                    tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, v.uv + float2(_MainTex_TexelSize.x * i,_MainTex_TexelSize.y * j) * _BlurFactor) * width[abs(i)] * width[abs(j)];
                }
            }

            return float4((tex / 256).xyz, 1);
        }
        ENDHLSL

        Pass
        {
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag
            ENDHLSL
        }
    }
}
