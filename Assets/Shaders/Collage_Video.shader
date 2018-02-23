Shader "Unlit/Collage_Video"
{
	Properties
	{
		DiffuseMap ("Texture", 2D) = "white" {}
		AphaMap("Texture", 2D) = "white" {}
		AphaMap2("Texture", 2D) = "white" {}
		TextMap("Texture", 2D) = "white" {}
		LineMap("Texture", 2D) = "white" {}
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

			uniform sampler2D DiffuseMap;
			uniform sampler2D AphaMap;
			uniform sampler2D AphaMap2;
			uniform sampler2D TextMap;
			uniform sampler2D LineMap;

			const float PI = 3.1415926535897932384626433832795;

			in vec2 uv;
			out vec4 finalColor;

			vec2 VideoRes = _ScreenParams.xy;

			//vec2 MapSize_0 = vec2(1920.0, 1080.0);
			//vec2 MapSize_0 = vec2(1000.0, 1000.0);
			vec2 MapSize_0 = vec2(820.0, 624.0);
			//vec2 MapSize_0 = vec2(1640.0, 624.0);
			
			vec2 AlphaMapSize = vec2(1210.0, 624.0);
			vec2 AlphaMapSize2 = vec2(624.0, 624.0);
			vec2 TextMapSize = VideoRes;
			vec2 LineMapSize = vec2(80.0, 8.0);

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

			struct Input
			{
				vec2 vDiffusePos;
				vec2 vDiffuseScale;

				float fDiffuseScale;

				vec2 vDiffuseScalePivot;

				vec2 vMaskPos;
				vec2 vMaskScale;

				vec2 vMaskScalePivot;

				float fMaskScale_H;

				float timeStart;
				float timeDuration;

				vec2 vStartPos;

				bool bScaleMaskAnim;
				bool bScaleDiffuseAnim;

				float fShear;
			};

			vec4 TextureColor(sampler2D DiffuseMap, sampler2D MaskMap, in Input input)
			{
				vec2 vOffset;
				vOffset.x = Blend(input.vStartPos.x, 0.0, Ratio(input.timeStart, 0.5));// +Blend(0.0, input.vStartPos.x, Ratio(TimeDuration - 0.5, 0.5));

				vec2 vDiffusePos = input.vDiffusePos;
				vec2 vDiffuseScale = input.vDiffuseScale * input.fDiffuseScale;
				vDiffusePos -= vec2(0.5);

				float fMaskScale_H = input.fMaskScale_H;

				if (input.bScaleMaskAnim == true)
				{
					vOffset.x += Blend(-vDiffusePos.x, 0.0, Ratio(input.timeStart + 0.5, input.timeDuration));
					fMaskScale_H = Blend(1.0, input.fMaskScale_H, Ratio(input.timeStart + 0.5, input.timeDuration));
				}

				if(input.bScaleDiffuseAnim)
					vDiffuseScale = Blend(vDiffuseScale, vDiffuseScale*vec2(1.05), Ratio(input.timeStart, TimeDuration));

				vec4 color = vec4(0.0);
				vec2 uvScaled = ScaleTexCoord(uv + vDiffusePos + vOffset, vDiffuseScale, input.vDiffuseScalePivot);

				color = texture2D(DiffuseMap, uvScaled);

				if (uvScaled.x < 0.0 || uvScaled.x > 1.0 || uvScaled.y < 0.0 || uvScaled.y > 1.0)
					color = vec4(0.0);

				vec2 vMaskPos = input.vMaskPos;
				vMaskPos -= vec2(0.5);

				vec2 uvf = uv;
				uvf.x = uv.x + input.fShear * (uv.y - 1.0);// (uv.y - 0.5) * 2.0;
				vec2 uvMask = ScaleTexCoord(uvf + vMaskPos + vOffset, input.vMaskScale);

				uvMask = ScaleTexCoord(uvMask, vec2(fMaskScale_H, 1.0), input.vMaskScalePivot);

				color *= texture2D(MaskMap, uvMask);

				if (uvMask.x < 0.0 || uvMask.x > 1.0 || uvMask.y < 0.0 || uvMask.y > 1.0)
					color *= vec4(0.0);

				return color;
			}

			vec4 LineColor(float fMaskAR, float fVideoAR)
			{
				vec2 vLinePos = vec2(0.5, 0.2);
				vec2 vLineScale = LineMapSize / VideoRes;
				vLinePos = vec2(0.5) - vLinePos;
				vec2 vOffset = vLineScale * vec2(0.5, 0.0);
				vec4 color = vec4(0.0);
				vec2 uvScaled = ScaleTexCoord(uv + vLinePos - vOffset, vLineScale);

				color = texture2D(LineMap, uvScaled);

				if (uvScaled.x < 0.0 || uvScaled.x > 1.0 || uvScaled.y < 0.0 || uvScaled.y > 1.0)
					color = vec4(0.0);

				return color;
			}

			void main()
			{
				finalColor = vec4(0.0);
				vec4 colorBG = vec4(1.0, 198.0 / 255.0, 0.0, 1.0);
				finalColor = colorBG;

				float timeStart = 0.0;
				float fVideoAR = VideoRes.x / VideoRes.y;
				float fImageAR_0 = MapSize_0.x / MapSize_0.y;
				float fImageAR_3 = TextMapSize.x / TextMapSize.y;
				float fMaskAR = AlphaMapSize.x / AlphaMapSize.y;
				float fMaskAR2 = AlphaMapSize2.x / AlphaMapSize2.y;

				float fShear = -0.13;// Blend(0.0, , Ratio(timeStart, 2.0));;

				float fMaskScale = fImageAR_0 / fVideoAR;
				float fImagePos_X = (0.5 - (fImageAR_0 / fVideoAR)*0.5);
				if (fMaskScale > 0.5)
				{
					fMaskScale = 0.5;
					fImagePos_X = 0.25;
				}
					
				Input input1 = Input(vec2(0.5 + fImagePos_X, 0.5), vec2(fImageAR_0 / fVideoAR, 1.0), 1.0, vec2(0.5, 0.5),
								vec2(0.5 + (0.5 - fMaskScale*0.5), 0.5), vec2(fMaskScale, 1.0), vec2(1.0, 0.5),
								1.6, timeStart + 0.1, 0.5, vec2(1.0, 0.0), false, true, fShear);
				vec4 colorFirst = TextureColor(DiffuseMap, AphaMap2, input1);

				Input input2 = Input(vec2(0.64, 0.5), vec2(fImageAR_0 / fVideoAR, 1.0), 3.0, vec2(0.5, 0.5),
							vec2(0.64, 0.5), vec2(1.0, 1.0), vec2(1.0, 0.5),
							1.3, timeStart + 0.2, 0.5, vec2(1.0, 0.0), false, true, fShear);
				vec4 colorSecond = TextureColor(DiffuseMap, AphaMap, input2);

				colorSecond.a *= 0.5;

				Input input4 = Input(vec2(0.5, 0.5), vec2(fImageAR_3 / fVideoAR, 1.0), 1.0, vec2(0.5),
								vec2(0.115, 0.5), vec2(fMaskAR / fVideoAR, 1.0), vec2(0.5, 0.5),
								1.3, timeStart + 0.3, 0.5, vec2(-0.05, 0.0), true, false, 0.0);
				vec4 colorFourth = TextureColor(TextMap, AphaMap, input4);

				colorFourth.a *= Blend(0.0, 1.0, Ratio(timeStart + 0.3, 0.5)) - Blend(0.0, 1.0, Ratio(TimeDuration - 0.7, 0.5));

				//vec4 colorLine = LineColor(fMaskAR, fVideoAR);

				//colorLine.a *= (Blend(0.0, 1.0, Ratio(timeStart + 0.6, 0.2)) - Blend(0.0, 1.0, Ratio(TimeDuration - 0.5, 0.5)));
				
				colorFirst.a *= Blend(1.0, 0.0, Ratio(TimeDuration - 0.5, 0.5));
				colorSecond.a *= Blend(1.0, 0.0, Ratio(TimeDuration - 0.5, 0.5));

				//finalColor.rgb = colorLine.rgb * colorLine.a + finalColor.rgb * (1.0 - colorLine.a);
				finalColor.rgb = colorFourth.rgb * colorFourth.a + finalColor.rgb * (1.0 - colorFourth.a);
				finalColor.rgb = colorSecond.rgb * colorSecond.a + finalColor.rgb * (1.0 - colorSecond.a);
				finalColor.rgb = colorFirst.rgb * colorFirst.a + finalColor.rgb * (1.0 - colorFirst.a);
			}

			#endif

			ENDGLSL
		}
	}
}
