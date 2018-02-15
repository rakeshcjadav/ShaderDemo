Shader "Unlit/HelloWorld"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_SecTex("Second", 2D) = "white" {}
		_ThirdTex("Third", 2D) = "white" {}
		_ForthTex("Forth", 2D) = "white" {}
		_FifthTex("Fifth", 2D) = "white" {}
		_ScaleRange("ScaleRange", Range(1.0, 5.0)) = 1.0
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
			uniform sampler2D _ForthTex;
			uniform sampler2D _FifthTex;

			uniform float _ScaleRange;

			const float PI = 3.1415926535897932384626433832795;
			const float fPadding = 0.000;

			in vec2 uv;
			out vec4 finalColor;

			float VideoRes = _ScreenParams.x / _ScreenParams.y;

			const float TimeDuration = 4.0;
			const float TimeTransition = 0.5;

			float GetTime()
			{
				return mod(_Time.y, TimeDuration);
			}

			vec2 ScaleTexCoord(vec2 texCoord, vec2 vScale)
			{
				vec2 inverseScale = vec2(1.0) / vScale;
				return (texCoord - vec2(0.5)) * inverseScale + vec2(0.5);
			}

			vec2 RotateTexCoord(vec2 texCoord, float fAngle)
			{
				float fRadian = fAngle * PI / 180.0;
				vec2 uvrot;
				texCoord -= vec2(0.5);
				uvrot.x = texCoord.x * cos(fRadian) - texCoord.y * sin(fRadian);
				uvrot.y = texCoord.x * sin(fRadian) + texCoord.y * cos(fRadian);
				uvrot += vec2(0.5);
				return uvrot;
			}

			float Fun_Sine_Ease_In_Out(float timeElapsed, float timeTotal)
			{
				return -0.5*(cos(timeElapsed / timeTotal * PI) - 1.0);
			}

			float Fun_QUINTIC_EASE_IN(float timeElapsed, float timeTotal)
			{
				return (timeElapsed/=timeTotal)*timeElapsed*timeElapsed*timeElapsed*timeElapsed;
			}

			float Ratio(float timeStart, float timeDuration)
			{
				if (GetTime() < timeStart)
					return 0.0;
				else if (GetTime() > timeStart + timeDuration)
					return 1.0;
				else
					return Fun_QUINTIC_EASE_IN(GetTime() - timeStart, timeDuration);
			}

			float Blend(float a, float b, float fRatio)
			{
				return mix(a, b, fRatio);
			}

			void main()
			{	
				finalColor = texture2D(_MainTex, uv);// vec4(0.0, 0.0, 0.0, 1.0);
				vec4 ThemeColor = vec4(1.0);

				vec2 scaleMain = vec2(_ScaleRange);
				vec2 scaleProp = vec2(120.0 / _ScreenParams.x, 120.0 / _ScreenParams.y) * vec2(Blend(0.6, 1.0, Ratio(0.2, 0.8)));

				float f = 0.1;
				vec2 vOffset = vec2(scaleProp.x * 0.15, scaleProp.y * 0.15) * scaleMain;
				vec2 vPos = vec2(0.5, 0.0);
				vPos = vec2(scaleProp.x *vPos.x, scaleProp.y *vPos.y)*scaleMain;
				scaleProp *= scaleMain;

				vec2 uvProp1 = ScaleTexCoord(uv + vPos + vOffset, scaleProp);
				uvProp1 = RotateTexCoord(uvProp1, Blend(0.0, 0.0, Ratio(0.1, 1.0)));

				vec4 propColor1 = texture2D(_SecTex, uvProp1);
				if (uvProp1.x < 0.0 || uvProp1.x > 1.0 || uvProp1.y < 0.0 || uvProp1.y > 1.0)
					propColor1.a = 0.0;

				vec2 uvProp2 = ScaleTexCoord(uv + vPos - vOffset, scaleProp);
				uvProp2 = RotateTexCoord(uvProp2, Blend(000.0, 0.0, Ratio(0.1, 1.0)));

				vec4 propColor2 = texture2D(_SecTex, uvProp2);

				if (uvProp2.x < 0.0 || uvProp2.x > 1.0
					|| uvProp2.y < 0.0 || uvProp2.y > 1.0)
					propColor2.a = 0.0;

				finalColor = propColor1 * propColor1.a + finalColor * (1.0 - propColor1.a);
				finalColor = propColor2 * propColor2.a + finalColor * (1.0 - propColor2.a);
				finalColor.rgb *= ThemeColor.rgb;

				//finalColor.rgb = mix(finalColor.rgb, propColor.rgb, propColor.a);
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
