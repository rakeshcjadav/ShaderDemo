Shader "Unlit/frame_wipe"
{
	Properties
	{
		DiffuseMap("Texture", 2D) = "white" {}
	}
		SubShader
	{
		Tags{ "RenderType" = "Opaque" }
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

	const float PI = 3.1415926535897932384626433832795;

	in vec2 uv;
	out vec4 finalColor;

	vec2 VideoRes = _ScreenParams.xy;

	vec2 DiffuseMapSize = vec2(1920.0, 1080.0);
	//vec2 DiffuseMapSize = vec2(300.0, 300.0);

	vec4 ThemeColor = vec4(255.0 / 255.0, 198.0 / 255.0, 0.0, 1.0);

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

	vec2 ScaleTexCoord(vec2 texCoord, vec2 vScale, vec2 vPivot, vec2 vLocalPivotOffset)
	{
		vec2 inverseScale = vec2(1.0) / vScale;
		return (texCoord - vPivot) * inverseScale + vPivot - vLocalPivotOffset;
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

	float Fun_Sine_Ease_In_Out(float timeElapsed, float timeDuration)
	{
		return -0.5*(cos(timeElapsed / timeDuration * PI) - 1.0);
	}

	float ElasticEaseIn(float timeElapsed, float timeDuration)
	{
		float fRatioDone = 0.0;
		if (timeElapsed == 0.0)
			fRatioDone = 0.0;
		else if ((timeElapsed /= timeDuration) == 1.0)
			fRatioDone = 1.0;
		else
		{
			float p = timeDuration * 0.3;
			float a = 0.6;
			float s = 0.0;
			if (a < 1.0)
			{
				a = 1.0;
				s = p / 4.0;
			}
			else
			{
				s = p / (2.0f*PI) * asin(1.0f / a);
			}
			fRatioDone = -(a*pow(2.0, 15.0*(timeElapsed -= 1.0)) * sin((timeElapsed*timeDuration - s)*(2.0*PI) / p));
		}
		return fRatioDone;
	}

	float ElasticEaseOut(float timeElapsed, float timeDuration)
	{
		float fRatioDone = 0.0;
		if (timeElapsed == 0.0)
			fRatioDone = 0.0;
		else if ((timeElapsed /= timeDuration) == 1.0)
			fRatioDone = 1.0;
		else
		{
			float p = timeDuration * 0.3;
			float a = 0.6;
			float s = 0.0;
			if (a < 1.0)
			{
				a = 1.0;
				s = p / 4.0;
			}
			else
			{
				s = p / (2.0*PI) * asin(1.0 / a);
			}
			fRatioDone = a * pow(2.0, -15.0*timeElapsed) * sin((timeElapsed*timeDuration - s)*(2.0*PI) / p) + 1.0;
		}
		return fRatioDone;
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

	float udRoundBox(vec2 p, vec2 b, float r)
	{
		return length(max(abs(p) - b, 0.0)) - r;
	}

	//---------------------------------------------------------
	// draw rectangle frame with rounded edges
	//---------------------------------------------------------
	float roundedFrame(vec2 pos, vec2 size, float radius, float thickness)
	{
		float d = length(max(abs(uv - pos), size) - size) - radius;
		return smoothstep(1.0, 0.9, abs(d / thickness) * 8.0);
	}

	void main()
	{
		finalColor = vec4(1.0);

		float fStartAngle = Blend(90.0, 270.0, Ratio(0.0, TimeDuration));// 120.0 - Blend(0.0, 150.0, Ratio(TimeDuration / 2.0, TimeDuration / 2.0));
		float fEndAngle = Blend(0.0, 360.0, Ratio(0.0, TimeDuration));// 120.0 - Blend(0.0, 150.0, Ratio(0.0, TimeDuration / 2.0));

		vec2 vCenter = vec2(0.0 + Blend(0.0, 1.0, Ratio(0.0, TimeDuration)), Blend(0.0, 0.15, Ratio(0.0, TimeDuration/2.0))-Blend(0.0, 0.15, Ratio(TimeDuration / 2.0, TimeDuration / 2.0)));
		vec2 vPixel = uv - vCenter;
		float fPixelAngle = atan(vPixel.x, vPixel.y) + PI;

		/*
		if (fEndAngle < fStartAngle)
		{
			float temp = fStartAngle;
			fStartAngle = fEndAngle;
			fEndAngle = temp;
		}
		*/

		if (fStartAngle < 0.0)
			fStartAngle = 360.0 - fStartAngle;
		if (fEndAngle < 0.0)
			fEndAngle = 360.0 - fEndAngle;

		fStartAngle = fStartAngle * PI / 180.0;
		fEndAngle = fEndAngle * PI / 180.0;

		//fStartAngle /= 2.0*PI;
		float l = length(vPixel);
		l = 0.1;
		finalColor.a = smoothstep(fStartAngle-l/2.0, fStartAngle+l/2.0, fPixelAngle);
		if (fEndAngle < fStartAngle)
		{
			if ((fPixelAngle > fStartAngle && fPixelAngle <= 2*PI))// || (fPixelAngle < fEndAngle && fPixelAngle >= 0.0))
			{
				//finalColor.a = 0.5;
			}
		}
		//else if (fPixelAngle > fStartAngle && fPixelAngle < fEndAngle)
		//{
		//	finalColor.a = 0.2;
		//}
		/*else
		{
			fStartAngle = fStartAngle * PI / 180.0;
			fEndAngle = fEndAngle * PI / 180.0;
			float fAngle = fStartAngle;
			if (fPixelAngle < fStartAngle)
			{
				fAngle = fStartAngle;
			}
			else if (fPixelAngle > fEndAngle)
			{
				fAngle = fEndAngle;
			}
			float fAlpha = (1.0 - abs(fAngle - fPixelAngle) * 1 * PI / 2.0);
			finalColor.a = finalColor.a * fAlpha;
		}*/
	}

#endif

	ENDGLSL
	}
	}
}
