Shader "Unlit/SimpleShader"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Marker("Texture", 2D) = "white" {}
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
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
	uniform sampler2D _Marker;

	uniform float _ScaleRange;

	const float PI = 3.1415926535897932384626433832795;
	const float fPadding = 0.000;

	in vec2 uv;
	out vec4 finalColor;

	vec2 VideoRes = _ScreenParams.xy;
	//vec2 MapSize_0 = vec2(1000.0, 1000.0);
	//vec2 MapSize_0 = vec2(1640.0, 924.0);
	vec2 MapSize_0 = vec2(1000.0, 1080.0);

	const float TimeDuration = 4.0;
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
			return Fun_QUINTIC_EASE_IN(GetTime() - timeStart, timeDuration);
	}

	float Blend(float a, float b, float fRatio)
	{
		return mix(a, b, fRatio);
	}

	vec4 TextureColor(sampler2D map, vec2 vScale)
	{
		//vec2 uv = gl_TexCoord[0].st;
		vec4 color = vec4(0.0);
		vec2 uvScaled = ScaleTexCoord(uv, vScale);
		if (vScale.x < 1.0)
			uvScaled.x -= (1.0 - 1.0 / vScale.x) / 2.0;
		if (vScale.x <= 0.7)
			uvScaled.x -= 0.5 * (0.7 - vScale.x)/vScale.x;

		color = texture2D(map, uvScaled);

		if (uvScaled.x < 0.0 || uvScaled.x > 1.0 || uvScaled.y < 0.0 || uvScaled.y > 1.0)
			color = vec4(0.0);

		float fShadowLengh = 0.2;
		float fShadowOpacity = 0.5;
		float fShadow = 0.0;
		fShadow += smoothstep(-fShadowLengh, 0.0, uvScaled.x)*fShadowOpacity;
		fShadow -= smoothstep(1.0, 1.0 + fShadowLengh, uvScaled.x)*fShadowOpacity;
		color.a = max(color.a, fShadow*fShadow);

		vec4 colorScaled;
		vec2 uvScaled2 = ScaleTexCoord(uv, vScale*vec2(3.0));
		colorScaled = texture2D(map, uvScaled2) *vec4(0.3, 0.3, 0.3, 1.0);

		if (uvScaled2.x < 0.0 || uvScaled2.x > 1.0 || uvScaled2.y < 0.0 || uvScaled2.y > 1.0)
			colorScaled = vec4(0.0);

		color = color * color.a + colorScaled * (1.0 - color.a);
		//color.rgb = color.rgb * color.a + colorScaled.rgb * (1.0 - color.a);
		//color.a = max(color.a, colorScaled.a);

		return color;
	}

	void main()
	{
		finalColor = vec4(0.0);

		float fVideoAspectRatio = VideoRes.x / VideoRes.y;
		float fImageAspectRatio = MapSize_0.x / MapSize_0.y;
		vec2 vScale = vec2(1.0);
		vScale.x = fImageAspectRatio / fVideoAspectRatio;

		finalColor += TextureColor(_MainTex, vScale);

		vec4 colorMarker = texture2D(_Marker, uv);

		finalColor = colorMarker * colorMarker.a + finalColor * (1.0 - colorMarker.a);
		//finalColor.rgb = finalColor.rgb * finalColor.a + ThemeColor.rgb * (1.0 - finalColor.a);
		//finalColor.a = 1.0;

		//vec3 colorBlend = vec3(0.0);

		// Blend user defined color
		//colorBlend = ColorBlend(finalColor.rgb, DiffuseColor.rgb, DiffuseColorBlendOp);
		//finalColor.rgb = mix(finalColor.rgb, colorBlend.rgb, DiffuseColor.a);
		//if (uv.x > 0.7)
		//	finalColor.rgb = vec3(0.0);

		finalColor = vec4(finalColor.rgb, finalColor.a);
	}

#endif

	ENDGLSL
		}
	}
}
