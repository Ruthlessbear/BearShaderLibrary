Shader "ShaderLearn1/WaterToon"
{
    Properties
    {
        _DepthGradientShallow("Depth Gradient Shallow",Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep("Depth Gradient Shallow",Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("_Depth Max",Float) = 1
        _SurfaceNoise("Noise",2D) = "White"{}
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777
        _FoamDistanceMin("Foam Distance Min",Float)=0.04
        _FoamDistanceMax("Foam Distance Max",Float) = 0.4
        _SurfaceNoiseScroll("Surface Noise Scroll",Vector)=(0.03,0.03,0,0)
        _SurfaceDistortion("Surface Distortion",2D) = "White"{}
        _SurfaceDistortionAmount("Surface Distortion Amount",Float) = 0.4
        _FoamColor("Foam Color",Color)=(1,1,1,1)
    }
    SubShader
    {
        LOD 100

        Pass
        {
            Tags{"Queue"="Transparent"}
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define SMOOTHSTEP_AA 0.01

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 noiseUV : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPosition:TEXCOORD1;
                float2 distortUV:TEXCOORD2;
                float3 viewNormal:NORMAL;
            };

            sampler2D _CameraDepthTexture;
            fixed4 _DepthGradientShallow;
            fixed4 _DepthGradientDeep;
            float _DepthMaxDistance;
            sampler2D _SurfaceNoise;
            float4 _SurfaceNoise_ST;
            float _SurfaceNoiseCutoff;
            float _FoamDistanceMin;
            float _FoamDistanceMax;
            float2 _SurfaceNoiseScroll;
            sampler2D _SurfaceDistortion;
            float4 _SurfaceDistortion_ST;
            float _SurfaceDistortionAmount;
            sampler2D _CameraNormalsTexture;
            float4 _FoamColor;

            //自定义混合
            float4 alphaBlend(float4 top,float4 bottom)
            {
                float3 color = (top.rgb * top.a) + (bottom.rgb * (1-top.a));
                float alpha= top.a + bottom.a * (1 - top.a);
                return float4(color, alpha);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.noiseUV = TRANSFORM_TEX(v.uv, _SurfaceNoise);
                o.distortUV = TRANSFORM_TEX(v.uv, _SurfaceDistortion);
                o.viewNormal = COMPUTE_VIEW_NORMAL;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                //通过相机开启的深度纹理_CameraDepthTexture，进行采样
                //采样获取的值是(0,1)之间非线性的，对其进行转换为线性
                float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition)).r;
                float existingDepthLinear = LinearEyeDepth(existingDepth01);
                //获取摄像机下_CameraNormalsTexture视图空间法线采样
                float3 existingNormal = tex2Dproj(_CameraNormalsTexture, UNITY_PROJ_COORD(i.screenPosition));
                //水面法线与视图空间法线点乘，若垂直则值为0，阈值变高，若同方向且平行，值为1，则阈值降低
                float3 normalDot = saturate(dot(i.viewNormal, existingNormal));

                //i.screenPosition.w为水面深度，根据深度纹理与水面深度相减获得差值
                float deapthDifference = existingDepthLinear - i.screenPosition.w;

                float waterLerpValue = saturate(deapthDifference / _DepthMaxDistance);
                fixed4 waterLerpColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterLerpValue);

                //采样失真纹理，使波纹的运动更加丰富
                float2 distortSampler = (tex2D(_SurfaceDistortion, i.distortUV).xy * 2.0 - 1.0) * _SurfaceDistortionAmount;

                //_Time对noise贴图进行偏移，实现波纹流动效果
                float2 noiseUV = float2(i.noiseUV.x + distortSampler.x+_Time.y * _SurfaceNoiseScroll.x, i.noiseUV.y + distortSampler.y + _Time.y * _SurfaceNoiseScroll.y);
                //对噪声贴图采样
                float surfaceNoiseSample = tex2D(_SurfaceNoise, noiseUV).r;

                //根据水深调制噪声值，使在水边缘地区的域值较低从而达到海岸线的效果
                float foamDistance = lerp(_FoamDistanceMax, _FoamDistanceMin, normalDot);
                float foamDepthDifference01 = saturate(deapthDifference / foamDistance);
                float surfaceNoiseCutOff = foamDepthDifference01 * _SurfaceNoiseCutoff;
                //设定_SurfaceNoiseCutoff阈值进行截取
                //float surfaceNoise = surfaceNoiseSample > surfaceNoiseCutOff ? 1 : 0;
                //抗锯齿处理
                float surfaceNoise = smoothstep(surfaceNoiseCutOff - SMOOTHSTEP_AA, surfaceNoiseCutOff + SMOOTHSTEP_AA, surfaceNoiseSample);

                //修改水纹颜色
                float4 surfaceNoiseColor = _FoamColor;
                surfaceNoiseColor.a *= surfaceNoise;
    
                return alphaBlend(surfaceNoiseColor, waterLerpColor);
            }
            ENDCG
        }
    }
}