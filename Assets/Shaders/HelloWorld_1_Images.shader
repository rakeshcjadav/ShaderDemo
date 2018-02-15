Shader "Unlit/HelloWorld_1_Images"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_SecTex("Second", 2D) = "white" {}
		_ThirdTex("Third", 2D) = "white" {}
		_FourthTex("Fourth", 2D) = "white" {}
		_FifthTex("Fifth", 2D) = "white" {}
		_colorOutline("OutlineColor", Color) = (1.0, 1.0, 0.0, 1.0)
	}
		SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100

		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			GLSLPROGRAM

			#include "UnityCG.glslinc"

			#ifdef VERTEX

			out vec2 uv;
			void main()
			{
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				uv = gl_MultiTexCoord0.xy;
			}

			#endif

			#ifdef FRAGMENT
					
			uniform sampler2D _MainTex;
			uniform sampler2D _SecTex;
			uniform sampler2D _ThirdTex;
			uniform sampler2D _FourthTex;
			uniform sampler2D _FifthTex;
			uniform vec4 _colorOutline;

			const float PI = 3.1415926535897932384626433832795;
			const float fPadding = 0.003;

			float VideoRes = _ScreenParams.x / _ScreenParams.y;

			const int nFrames = 1;				// Five frame support only
			const float TimeDuration = 5.0;
			const float TimeTransition = 1.0;

			in vec2 uv;
			out vec4 finalColor;

			float GetTime()
			{
				return mod(_Time.y, TimeDuration);  // _Time.y + 4.0; //
			}

			vec2[nFrames] GetEmptyArray()
			{
				return vec2[nFrames](vec2(0.0));
			}

			vec2[nFrames] GetFrames()
			{
				vec2[nFrames] frames = GetEmptyArray();

				float fFrame = 1.0 / nFrames;
						
				for (int i = 0; i < nFrames; i++)
				{
					float fStartPadding = fPadding;
					float fEndPadding = fPadding;
					if (i == 0)
						fStartPadding = 0.0;
					else if (i == nFrames - 1)
						fEndPadding = 0.0;
					frames[i] = vec2(i*fFrame + fStartPadding, (i + 1)*fFrame - fEndPadding);
				}
				return frames;
			}

			vec2[nFrames] GetFrameTimes()
			{
				float timeFrame = (TimeDuration - TimeTransition - TimeTransition) / nFrames;

				vec2 timeFrames[nFrames] = GetEmptyArray();
				for (int i = 0; i < nFrames; i++)
					timeFrames[i] = vec2(TimeTransition + i * timeFrame, TimeTransition + (i + 1)*timeFrame - TimeTransition);

				return timeFrames;
			}

			vec2 ScaleTexCoord(vec2 texCoord, vec2 vScale)
			{
				vec2 inverseScale = vec2(1.0) / vScale;
				return (texCoord - vec2(0.5)) * inverseScale + vec2(0.5);
			}

			vec2[nFrames] GetUVScales()
			{
				return vec2[nFrames](vec2(1.77489177 / VideoRes, 1.0));
			}
			
			float Fun_Sine_Ease_In_Out(float timeElapsed, float timeTotal)
			{
				return -0.5*(cos(timeElapsed / timeTotal * PI) - 1.0);
			}

			float Ratio(float timeStart, float timeDuration)
			{
				if (GetTime() < timeStart)
					return 0.0;
				else if (GetTime() > timeStart + timeDuration)
					return 1.0;
				else
					return Fun_Sine_Ease_In_Out(GetTime() - timeStart, timeDuration);
			}

			float Blend(float a, float b, float fRatio)
			{
				return mix(a, b, fRatio);
			}

			float Blending(float fStart, float fEnd, float fValueEnd)
			{
				float f = 0.0;
				if (GetTime() < fStart)
					f = 0.0;
				else if (GetTime() > fEnd)
					f = 0.0;
				else if (GetTime() >= fStart && GetTime() <= fEnd - TimeTransition)
					f = Blend(0.0, fValueEnd, Ratio(fStart, TimeTransition));
				else
					f = Blend(fValueEnd, 0.0, Ratio(fEnd - TimeTransition, TimeTransition));
					
				return f;
			}

			float Blending(vec2 timeFrame, float fValueStart, float fValueEnd)
			{
				float fStart = timeFrame.x;
				float fEnd = timeFrame.y;
				float f = 0.0;
				if (GetTime() < fStart)
					f = fValueStart;
				else if (GetTime() > fEnd)
					f = fValueStart;
				else if (GetTime() >= fStart && GetTime() <= fEnd - TimeTransition)
					f = Blend(fValueStart, fValueEnd, Ratio(fStart, fEnd - fStart - TimeTransition));
				else
					f = Blend(fValueEnd, fValueStart, Ratio(fEnd - TimeTransition, TimeTransition));

				return f;
			}

			vec4 TextureColor(sampler2D map, vec2 vScale, vec2 vOffset, vec2 bounds)
			{
				vec4 color = vec4(0.0);
				vec2 uvScaled = ScaleTexCoord(uv + vOffset, vScale);
				if (uv.x > bounds.x && uv.x < bounds.y)
					color = texture2D(map, uvScaled);

				if (uvScaled.x < 0.0 || uvScaled.x > 1.0 || uvScaled.y < 0.0 || uvScaled.y > 1.0)
					color.a = 0.0;

				vec4 colorScaled;
				vec2 uvScaled2 = ScaleTexCoord(uv + vOffset, vScale*vec2(3.0));
				if (uv.x > bounds.x && uv.x < bounds.y)
					colorScaled = texture2D(map, uvScaled2) *vec4(0.3, 0.3, 0.3, 1.0);

				if (uvScaled2.x < 0.0 || uvScaled2.x > 1.0 || uvScaled2.y < 0.0 || uvScaled2.y > 1.0)
					colorScaled.a = 0.0;

				if (uv.x < 0.0 + fPadding * 2.0 || uv.x > 1.0 - fPadding * 2.0)
				{
					colorScaled.a = 0.0;
					color.a = 0.0;
				}

				color.rgb = color.rgb * color.a + colorScaled.rgb * (1.0 - color.a);
				color.a = max(color.a, colorScaled.a);

				if (uv.y < 0.0 + fPadding * 2.0 * VideoRes || uv.y > 1.0 - fPadding * 2.0 * VideoRes)
					color.a = 0.0;

				return color;
			}

			void main()
			{
				finalColor = vec4(0.0);

				vec2[nFrames] frames = GetFrames();
				vec2[nFrames] UVs = GetUVScales();

				vec2[nFrames] timeFrames = GetFrameTimes();

				float fScale = 1.1;

				finalColor += TextureColor(_MainTex, UVs[0]*Blending(vec2(0.0, TimeDuration), 1.0, fScale), vec2(0.0, 0.0), vec2(0.0, 1.0));
				
				finalColor.rgb = finalColor.rgb * finalColor.a + _colorOutline.rgb * (1.0 - finalColor.a);
				finalColor.a = 1.0;
			}

			#endif

			ENDGLSL
			/*
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 uvOrg : TEXCOORD1;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler2D _SecTex;
			sampler2D _ThirdTex;
			sampler2D _ForthTex;
			sampler2D _FifthTex;
			float4 _MainTex_ST;
			float4 _SecTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				if (uvOrg.x < 0.0 || uvOrg.x > 0.2)
					col = fixed4(0.0, 0.0, 0.0, 0.0);

				fixed4 colSec = tex2D(_SecTex, i.uv);
				if (uvOrg.x < 0.2|| uvOrg.x > 0.4)
					colSec = fixed4(0.0, 0.0, 0.0, 0.0);

				fixed4 colThi = tex2D(_ThirdTex, i.uv);
				if (uvOrg.x < 0.4 || uvOrg.x > 0.6)
					colThi = fixed4(0.0, 0.0, 0.0, 0.0);

				fixed4 colFor = tex2D(_ForthTex, i.uv);
				if (uvOrg.x < 0.6 || uvOrg.x > 0.8)
					colFor = fixed4(0.0, 0.0, 0.0, 0.0);

				fixed4 colFif = tex2D(_FifthTex, i.uv);
				if (uvOrg.x < 0.8 || uvOrg.x > 1.0)
					colFif = fixed4(0.0, 0.0, 0.0, 0.0);
				
				
				col.rgb = col.rgb * col.a + colSec.rgb * (1.0 - col.a);
				col.a += colSec.a;

				col.rgb = col.rgb * col.a + colThi.rgb * (1.0 - col.a);
				col.a += colThi.a;

				col.rgb = col.rgb * col.a + colFor.rgb * (1.0 - col.a);
				col.a += colFor.a;

				col.rgb = col.rgb * col.a + colFif.rgb * (1.0 - col.a);
				col.a += colFif.a;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
			*/
		}
	}
}
