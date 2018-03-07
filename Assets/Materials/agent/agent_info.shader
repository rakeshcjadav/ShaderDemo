Shader "Unlit/agent_info"
{
	Properties
	{
		DiffuseMap ("Texture", 2D) = "white" {}
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

	const float PI = 3.1415926535897932384626433832795;

	in vec2 uv;
	out vec4 finalColor;

	vec2 VideoRes = _ScreenParams.xy;

	vec2 DiffuseMapSize = vec2(300.0, 300.0);
	//vec2 DiffuseMapSize = vec2(300.0, 300.0);

	vec4 ThemeColor = vec4(255.0 / 255.0, 198.0 / 255.0, 0.0, 1.0);

	const float TimeDuration = 3.0;
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
			return ElasticEaseOut(GetTime() - timeStart, timeDuration);
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

		float fVideoAR = VideoRes.x / VideoRes.y;
		float fImageAR = DiffuseMapSize.x / DiffuseMapSize.y;

		vec2 vSquare = vec2(Blend(100.0, 320.0, Ratio(0.0, 1.0))) / VideoRes;

		vec2 uvDiffuse = ScaleTexCoord(uv, vec2(fImageAR / fVideoAR, 1.0)*max(vSquare.x, vSquare.y), vec2(0.5, 0.5), vec2(0.0, 0.0));
		vec4 colorDiffuse = texture2D(DiffuseMap, uvDiffuse);

		if (uvDiffuse.x < 0.0 || uvDiffuse.x > 1.0 || uvDiffuse.y < 0.0 || uvDiffuse.y > 1.0)
			colorDiffuse.a = 0.0;

		float f = length(uvDiffuse - vec2(0.5));
		f = smoothstep(0.2, 0.3, f);
		finalColor.rgb = vec3(1.0-f);

		//finalColor = colorDiffuse;
	}

#endif

	ENDGLSL
	}
	}
}
