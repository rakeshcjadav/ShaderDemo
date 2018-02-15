Shader "Unlit/Collage"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_SecondTex("Texture", 2D) = "white" {}
		_ThirdTex("Texture", 2D) = "white" {}
		_AlphaTex("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
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
			uniform sampler2D _SecondTex;
			uniform sampler2D _ThirdTex;

			uniform sampler2D _AlphaTex;

			const float PI = 3.1415926535897932384626433832795;

			in vec2 uv;
			out vec4 finalColor;

			vec2 VideoRes = _ScreenParams.xy;
			//vec2 AlphaMap_Size = vec2(820.0, 624.0);
			vec2 AlphaMap_Size = vec2(440.0, 624.0);

			vec2 DiffuseMapSize_0 = vec2(1000.0, 1000.0);
			vec2 DiffuseMapSize_1 = vec2(1920.0, 1080.0);
			vec2 DiffuseMapSize_2 = vec2(1920.0, 1080.0);

			const float TimeDuration = 7.0;
			const float TimeTransition = 0.5;

			float GetTime()
			{
				return mod(_Time.y, TimeDuration);
			}

			vec2 ScaleTexCoord(vec2 texCoord, vec2 vScale)
			{
				vec2 inverseScale = vec2(1.0) / vScale;
				return (texCoord - vec2(0.5, 0.5)) * inverseScale + vec2(0.5, 0.5);
			}

			vec2 ScaleTexCoord(vec2 texCoord, vec2 vScale, vec2 vPivot)
			{
				vec2 inverseScale = vec2(1.0) / vScale;
				return (texCoord - vPivot) * inverseScale + vPivot;
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
				return (timeElapsed /= timeTotal)*timeElapsed*timeElapsed*timeElapsed*timeElapsed;
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

			vec2 Blend(vec2 a, vec2 b, float fRatio)
			{
				return mix(a, b, fRatio);
			}

			vec4 TextureColor(sampler2D map, vec2 vPos, vec2 vScale, vec2 vScaleMask, float fScale, float fPivotX, float timeStart, vec2 vStartPos, float bScale)
			{

				vec2 vOffset;
				vOffset.x = Blend(vStartPos.x, 0.0, Ratio(timeStart, 0.5));
				vOffset.y = Blend(vStartPos.y, 0.0, Ratio(timeStart, 0.5));

				vPos -= vec2(0.5);

				if (bScale == 1.0)
				{
					vOffset.x += Blend(-vPos.x, 0.0, Ratio(timeStart + 0.5, 0.5));
					fScale = Blend(1.0, fScale, Ratio(timeStart + 0.5, 0.5));
				}

				vScale = Blend(vScale, vScale*vec2(1.05), Ratio(timeStart, 5.0));

				vec4 color = vec4(0.0);
				vec2 uvScaled = ScaleTexCoord(uv + vPos + vOffset, vScale, vec2(0.5, 0.5));

				color = texture2D(map, uvScaled);

				if (uvScaled.x < 0.0 || uvScaled.x > 1.0 || uvScaled.y < 0.0 || uvScaled.y > 1.0)
					color = vec4(0.0);

				float fShear = -0.255;
				
				vec2 uvMask = ScaleTexCoord(uv + vPos + vOffset, vScaleMask);
								
				uvMask.x = uvMask.x + fShear * (uvMask.y - 0.5) * 2.0;
				uvMask = ScaleTexCoord(uvMask, vec2(fScale, 1.0), vec2(fPivotX, 0.5));

				color *= texture2D(_AlphaTex, uvMask);

				if (uvMask.x < 0.0 || uvMask.x > 1.0 || uvMask.y < 0.0 || uvMask.y > 1.0)
					color *= vec4(0.0);

				return color;
			}

			void main()
			{
				finalColor = vec4(1.0, 198.0 / 255.0, 0.0, 1.0);

				float fVideoAR = VideoRes.x / VideoRes.y;
				float fImageAR_0 = DiffuseMapSize_0.x / DiffuseMapSize_0.y;
				float fImageAR_1 = DiffuseMapSize_1.x / DiffuseMapSize_1.y;
				float fImageAR_2 = DiffuseMapSize_2.x / DiffuseMapSize_2.y;
				float fMaskAR = AlphaMap_Size.x / AlphaMap_Size.y;

				vec4 colorFirst = TextureColor(_MainTex, vec2(1.0-0.13, 0.5), vec2(fImageAR_0 / fVideoAR, 1.0), vec2(fMaskAR / fVideoAR, 1.0), 1.3, 1.0, 0.4, vec2(0.135, 1.0), 0.0);
				vec4 colorSecond = TextureColor(_SecondTex, vec2(0.75-0.125, 0.5), vec2(fImageAR_1 / fVideoAR, 1.0), vec2(fMaskAR / fVideoAR, 1.0), 1.0, 0.5, 0.2, vec2(-0.135, -1.0), 0.0);
				vec4 colorThird = TextureColor(_ThirdTex, vec2(0.11, 0.5), vec2(fImageAR_2 / fVideoAR, 1.0), vec2(fMaskAR / fVideoAR, 1.0), 1.3, 0.0, 0.0, vec2(0.135, 1.0), 1.0);

				
				finalColor = colorFirst * colorFirst.a + finalColor * (1.0 - colorFirst.a);
				finalColor = colorThird * colorThird.a + finalColor * (1.0 - colorThird.a);
				finalColor = colorSecond * colorSecond.a + finalColor * (1.0 - colorSecond.a);
				
			}

			#endif

			ENDGLSL
		}
	}
}
