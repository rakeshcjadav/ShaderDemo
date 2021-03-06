﻿Shader "Unlit/Collage_Image_Square"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_SecondTex("Texture", 2D) = "white" {}
		_AlphaTex("Texture", 2D) = "white" {}
		_TextTex("Texture", 2D) = "white" {}
		_LineText("Texture", 2D) = "white" {}
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

			uniform sampler2D _AlphaTex;
			uniform sampler2D _TextTex;
			uniform sampler2D _LineText;

			const float PI = 3.1415926535897932384626433832795;

			in vec2 uv;
			out vec4 finalColor;

			vec2 VideoRes = _ScreenParams.xy;
			
			vec2 MapSize_0 = vec2(1000.0, 1000.0);
			vec2 MapSize_1 = vec2(1000.0, 1000.0);
			//vec2 MapSize_2 = vec2(1920.0, 1080.0);
			//vec2 MapSize_3 = vec2(1640.0, 624.0);

			vec2 AlphaMapSize = vec2(220.0, 600.0);
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

			float Fun_QUINTIC_EASE_IN(float timeElapsed, float timeTotal)
			{
				return (timeElapsed /= timeTotal)*timeElapsed*timeElapsed*timeElapsed*timeElapsed;
			}

			float Fun_QUINTIC_EASE_IN_OUT(float timeElapsed, float timeTotal)
			{
				if ((timeElapsed /= timeTotal / 2.0) < 1.0)
					return 0.5*timeElapsed*timeElapsed*timeElapsed*timeElapsed*timeElapsed;
				else
					return 0.5*((timeElapsed -= 2.0)*timeElapsed*timeElapsed*timeElapsed*timeElapsed + 2.0);
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
			};

			vec4 TextureColor(sampler2D DiffuseMap, sampler2D MaskMap, in Input input)
			{
				vec2 vOffset;
				vOffset.x = Blend(input.vStartPos.x, 0.0, Ratio(input.timeStart, input.timeDuration)) +
					Blend(0.0, input.vStartPos.x, Ratio(input.timeStart + 5.0, input.timeDuration));
				vOffset.y = Blend(input.vStartPos.y, 0.0, Ratio(input.timeStart, input.timeDuration)) +
					Blend(0.0, input.vStartPos.y, Ratio(input.timeStart + 5.0, input.timeDuration));

				vec2 vDiffusePos = input.vDiffusePos;
				vec2 vDiffuseScale = input.vDiffuseScale;
				vDiffusePos -= vec2(0.5);

				float fMaskScale_H = input.fMaskScale_H;

				if (input.bScaleMaskAnim == true)
				{
					vOffset.x += Blend(-vDiffusePos.x, 0.0, Ratio(input.timeStart + 0.5, input.timeDuration));
					fMaskScale_H = Blend(1.0, input.fMaskScale_H, Ratio(input.timeStart + 0.5, input.timeDuration));
				}

				if (input.bScaleDiffuseAnim)
					vDiffuseScale = Blend(vDiffuseScale, vDiffuseScale*vec2(1.05), Ratio(input.timeStart, 5.0));

				vec4 color = vec4(0.0);
				vec2 uvScaled = ScaleTexCoord(uv + vDiffusePos + vOffset, vDiffuseScale, input.vDiffuseScalePivot);

				color = texture2D(DiffuseMap, uvScaled);

				if (uvScaled.x < 0.0 || uvScaled.x > 1.0 || uvScaled.y < 0.0 || uvScaled.y > 1.0)
					color = vec4(0.0);

				float fShear = -0.255;

				vec2 vMaskPos = input.vMaskPos;
				vMaskPos -= vec2(0.5);

				vec2 uvMask = ScaleTexCoord(uv + vMaskPos + vOffset, input.vMaskScale);

				uvMask.x = uvMask.x + fShear * (uvMask.y - 0.5) * 2.0;
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

				color = texture2D(_LineText, uvScaled);

				if (uvScaled.x < 0.0 || uvScaled.x > 1.0 || uvScaled.y < 0.0 || uvScaled.y > 1.0)
					color = vec4(0.0);

				return color;
			}

			void main()
			{
				finalColor = vec4(0.0);
				vec4 colorBG = vec4(1.0, 198.0 / 255.0, 0.0, 1.0);

				float timeStart = 0.0;
				if (uv.y < Blend(0.0, 1.0, Ratio(timeStart, 0.5)))
					finalColor = colorBG;

				timeStart += 0.5;
				float fVideoAR = VideoRes.x / VideoRes.y;
				float fImageAR_0 = MapSize_0.x /MapSize_0.y;
				float fImageAR_1 = MapSize_1.x /MapSize_1.y;
				float fTextAR = TextMapSize.x / TextMapSize.y;
				float fMaskAR = AlphaMapSize.x / AlphaMapSize.y;

				Input input1 = Input(vec2(1.0 - 0.165, 0.5), vec2(fImageAR_0 / fVideoAR, 1.0), vec2(0.5),
					vec2(1.0 - 0.165, 0.5), vec2(fMaskAR / fVideoAR, 1.0), vec2(1.0, 0.5),
					1.3, timeStart + 0.4, 0.5, vec2(0.135, 1.0), false, true);
				vec4 colorFirst = TextureColor(_MainTex, _AlphaTex, input1);

				Input input2 = Input(vec2(0.5, 0.5), vec2(fImageAR_1 / fVideoAR, 1.0), vec2(0.5),
					vec2(0.5, 0.5), vec2(fMaskAR / fVideoAR, 1.0), vec2(0.5, 0.5),
					1.0, timeStart + 0.2, 0.5, vec2(-0.135, -1.0), false, true);
				vec4 colorSecond = TextureColor(_SecondTex, _AlphaTex, input2);

				vec4 colorText = vec4(0.0);
				float fTextAlpha = Blend(0.0, 1.0, Ratio(timeStart + 0.6, 0.2)) - Blend(0.0, 1.0, Ratio(TimeDuration - 0.5, 0.5));
				if (fTextAlpha > 0.0)
				{
					Input input4 = Input(vec2(0.5, 0.5), vec2(fTextAR / fVideoAR, 1.0), vec2(0.5),
						vec2(0.165, 0.5), vec2(fMaskAR / fVideoAR, 1.0), vec2(0.5, 0.5),
						1.4, timeStart + 0.5, 0.5, vec2(-0.1, 0.0), true, false);
					colorText = TextureColor(_TextTex, _AlphaTex, input4);

					colorText.a *= fTextAlpha;
				}

				vec4 colorLine = vec4(0.0);
				float fLineAlpha = (Blend(0.0, 1.0, Ratio(timeStart + 0.6, 0.2)) - Blend(0.0, 1.0, Ratio(TimeDuration - 0.5, 0.5)));
				if (fLineAlpha > 0.0)
				{
					colorLine = LineColor(fMaskAR, fVideoAR);
					colorLine.a *= fLineAlpha;
				}

				finalColor.rgb = colorLine.rgb * colorLine.a + finalColor.rgb * (1.0 - colorLine.a);
				finalColor.rgb = colorText.rgb * colorText.a + finalColor.rgb * (1.0 - colorText.a);
				finalColor.rgb = colorFirst.rgb * colorFirst.a + finalColor.rgb * (1.0 - colorFirst.a);
				finalColor.rgb = colorSecond.rgb * colorSecond.a + finalColor.rgb * (1.0 - colorSecond.a);
			}

			#endif

			ENDGLSL
		}
	}
}
