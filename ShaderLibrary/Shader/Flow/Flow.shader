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

            //�Զ�����
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
                
                //ͨ������������������_CameraDepthTexture�����в���
                //������ȡ��ֵ��(0,1)֮������Եģ��������ת��Ϊ����
                float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition)).r;
                float existingDepthLinear = LinearEyeDepth(existingDepth01);
                //��ȡ�������_CameraNormalsTexture��ͼ�ռ䷨�߲���
                float3 existingNormal = tex2Dproj(_CameraNormalsTexture, UNITY_PROJ_COORD(i.screenPosition));
                //ˮ�淨������ͼ�ռ䷨�ߵ�ˣ�����ֱ��ֵΪ0����ֵ��ߣ���ͬ������ƽ�У�ֵΪ1������ֵ����
                float3 normalDot = saturate(dot(i.viewNormal, existingNormal));

                //i.screenPosition.wΪˮ����ȣ��������������ˮ����������ò�ֵ
                float deapthDifference = existingDepthLinear - i.screenPosition.w;

                float waterLerpValue = saturate(deapthDifference / _DepthMaxDistance);
                fixed4 waterLerpColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterLerpValue);

                //����ʧ������ʹ���Ƶ��˶����ӷḻ
                float2 distortSampler = (tex2D(_SurfaceDistortion, i.distortUV).xy * 2.0 - 1.0) * _SurfaceDistortionAmount;

                //_Time��noise��ͼ����ƫ�ƣ�ʵ�ֲ�������Ч��
                float2 noiseUV = float2(i.noiseUV.x + distortSampler.x+_Time.y * _SurfaceNoiseScroll.x, i.noiseUV.y + distortSampler.y + _Time.y * _SurfaceNoiseScroll.y);
                //��������ͼ����
                float surfaceNoiseSample = tex2D(_SurfaceNoise, noiseUV).r;

                //����ˮ���������ֵ��ʹ��ˮ��Ե��������ֵ�ϵʹӶ��ﵽ�����ߵ�Ч��
                float foamDistance = lerp(_FoamDistanceMax, _FoamDistanceMin, normalDot);
                float foamDepthDifference01 = saturate(deapthDifference / foamDistance);
                float surfaceNoiseCutOff = foamDepthDifference01 * _SurfaceNoiseCutoff;
                //�趨_SurfaceNoiseCutoff��ֵ���н�ȡ
                //float surfaceNoise = surfaceNoiseSample > surfaceNoiseCutOff ? 1 : 0;
                //����ݴ���
                float surfaceNoise = smoothstep(surfaceNoiseCutOff - SMOOTHSTEP_AA, surfaceNoiseCutOff + SMOOTHSTEP_AA, surfaceNoiseSample);

                //�޸�ˮ����ɫ
                float4 surfaceNoiseColor = _FoamColor;
                surfaceNoiseColor.a *= surfaceNoise;
    
                return alphaBlend(surfaceNoiseColor, waterLerpColor);
            }
            ENDCG
        }
    }
}