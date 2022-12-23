Shader "Mawntee/Screen/LCD Pixel Grid - AudioLink v0.69.420.1"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "black" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.55
        _Metallic ("Metallic", Range(0,1)) = 0.825

        [Header(UV)]
        [Space]
        _uvScale("UV Scale", float) = 1
        _AssWidth("Aspect Ratio Width", float) = 16
        _AssHeight("Aspect Ratio Height", float) = 9
        [Space]

        [Header(Screen params)]
        [Space]
        [IntRange]_Grid ("Pixel Size", Range(1,100)) = 10
        _DistanceOne ("Pix Fade Close", Float) = 0.5 // In metres
        //_DistanceZero ("LCD Fade Far", Float) = 3.75
        _DistancePix ("Pix Fade Far", Float) = 4.25
        _DistanceScan ("Scanline Far", Float) = 4.5
        _Chro ("Chomatic aberration", Range(0,1.69)) = 0.22
        _screenBrightness ("Screen Brightness", Range(0,2)) = 1.0
        _Emission ("Emission", Range(0,2)) = 0.42069
        [Space(20)]
        
        [Header(AudioLink Stuff)]
        [Header(Flash)]
        [Space(5)]
        _ALFlashMult("Multiplier", Range(0, 2.0)) = 0.0
        _ALFlashSmoothing("Smoothing", Range(0, 1)) = 0.69
        [Toggle]_ALFlashToggle("Add/Replace (off/on)", Float) = 0
        [Enum(BASS, 0, LOW MID, 1, HIGH MID, 2, TREBLE, 3)]_ALFlashBand("Band", Range(0, 3)) = 0
        _ALDelay("Delay", Range(0, 10)) = 0.0

        [Header(Colour)]
        [Space(5)]
        [Toggle]_ALColToggle("Affects Both Base Image & Emission", Float) = 0
        [KeywordEnum(OFF, THEME0, THEME1, THEME2, THEME3, ColorChord)]_ALThemeColor("AudioLink Colour Selection", Range(0, 5)) = 0
        [Enum(A, 0, B, 1, C, 2, D, 3)]_ALCCRange("Auto Colour Channel", Range(0, 3)) = 0
        _ALCCIntensity ("Colour Intensity", Range(0,1)) = 0.69

        [Header(Chomatic aberration)]
        [Space(5)]
        _ALChroMult ("Multiplier", Range(0,4.20)) = 1.22
        _ALChroSmoothing("Smoothing", Range(0, 1)) = 0.375
        [Toggle]_ALChroToggle("Add/Replace (off/on)", Float) = 0
        [Enum(BASS, 0, LOW MID, 1, HIGH MID, 2, TREBLE, 3)]_ALChroBand("Band", Range(0, 3)) = 0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0
        #include "Assets/AudioLink/Shaders/AudioLink.cginc"

        #pragma shader_feature_local _ALTHEMECOLOR_OFF _ALTHEMECOLOR_THEME0 _ALTHEMECOLOR_THEME1 _ALTHEMECOLOR_THEME2 _ALTHEMECOLOR_THEME3 _ALTHEMECOLOR_COLORCHORD

        #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))

        sampler2D _MainTex;

        struct Input
        {
            half2 uv_MainTex;
            half3 worldPos;
        };

        half _screenBrightness;
        half _minScreenBrightness;
        half _scanlineSize;
        half _DistanceOne;
        half _DistancePix;
        half _DistanceScan;
        half _DistanceZero;
        half _Glossiness;
        half _Metallic;
        half _uvScale;
        half _y;
        half _Chro;
        half _Grid;
        half _Emission;
        int _ALColToggle;
        int _AssHeight;
        int _AssWidth;
        half _NormVal;

        //AudioLink
        half _ALFlashMult;
        half _ALFlashSmoothing;
        int _ALFlashToggle;
        half _ALFlashBand;
        half _ALChroMult;
        half _ALChroSmoothing;
        int _ALChroToggle;
        half _ALChroBand;
        half _ALThemeColor;
        half _ALFinalCol;
        half _ALCCRange;
        half _ALCCIntensity;
        half _ALDelay;

        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here

        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input i, inout SurfaceOutputStandard o)
        {

        // AudioLink Garbage
        _ALChroMult = _ALChroMult * _ALChroMult * 0.420;

        half _ALFlash = (lerp(AudioLinkLerp( ALPASS_AUDIOLINK + float2( _ALDelay, _ALFlashBand ) ).r, AudioLinkLerp( ALPASS_FILTEREDAUDIOLINK + float2( _ALDelay, _ALFlashBand ) ).r, _ALFlashSmoothing) * _ALFlashMult);
        half _ALChro  = (lerp(AudioLinkLerp( ALPASS_AUDIOLINK + float2( _ALDelay, _ALChroBand ) ).r, AudioLinkLerp( ALPASS_FILTEREDAUDIOLINK + float2( _ALDelay, _ALChroBand ) ).r, _ALChroSmoothing) * _ALChroMult);

        float3 ALcolor;
        #ifdef _ALTHEMECOLOR_OFF
                ALcolor = _Color.rgb;
        #elif defined(_ALTHEMECOLOR_THEME0)
                ALcolor = AudioLinkData(ALPASS_THEME_COLOR0).rgb;
        #elif defined(_ALTHEMECOLOR_THEME1)
                ALcolor = AudioLinkData(ALPASS_THEME_COLOR1).rgb;
        #elif defined(_ALTHEMECOLOR_THEME2)
                ALcolor = AudioLinkData(ALPASS_THEME_COLOR2).rgb;
        #elif defined(_ALTHEMECOLOR_THEME3)
                ALcolor = AudioLinkData(ALPASS_THEME_COLOR3).rgb;
        #elif defined(_ALTHEMECOLOR_COLORCHORD)
                ALcolor =  AudioLinkData(ALPASS_CCCOLORS + uint2(_ALCCRange + 1, 0));
        #endif

        if (_ALChroToggle != 0)
            {
                _Chro *= _ALChro;
            }
            if (_ALFlashToggle == 0)
            {
                _Chro += _ALChro;
            }
        _Chro *= 0.01;

        //Distance
        //half dist = distance(_WorldSpaceCameraPos, i.worldPos);
        //half alpha = saturate((dist - _DistanceOne) / (_DistanceZero-_DistanceOne));
        //half alpha2 = saturate((dist - exp2(_DistanceOne)) / _DistancePix-_DistanceOne);
        //half scandist = saturate((dist - _DistanceZero) / _DistanceScan-_DistanceOne);

        half dist = distance(_WorldSpaceCameraPos, i.worldPos);
        half alpha = saturate((dist - _DistanceOne) / (_DistancePix-_DistanceOne));
        half alpha2 = saturate((dist - exp2(_DistanceOne)) / _DistancePix-_DistanceOne);
        half scandist = saturate((dist - _DistancePix) / _DistanceScan-_DistanceOne);

        //Pixel and UV setup
        half2 _Pixels = 100;
        _Pixels.xy = _Pixels.xy / abs(_Grid*0.1)*10;
       
        //uv
        float2 uvScaled = i.uv_MainTex.xy;
        half3x3 m = (half3x3)UNITY_MATRIX_MV;
    		half3 objectScale = half3(
    		    length(half3(m[0][0], m[1][0], m[2][0])),
    		    length(half3(m[0][1], m[1][1], m[2][1])),
    		    length(half3(m[0][2], m[1][2], m[2][2]))
    		);
        uvScaled.x = (((uvScaled.x - 0.5) * ((_AssHeight*objectScale.x*0.1) * _uvScale)) + 0.5);
        uvScaled.y = (((uvScaled.y - 0.5) * ((_AssWidth *objectScale.z*0.1) * _uvScale)) + 0.5);

        half2 pixUV = round(uvScaled * _Pixels.xy + 0.5) / _Pixels.xy;
        half2 uv = lerp(pixUV,uvScaled.xy,alpha2);

        //LCD / rgb pixel effect - shoutout iq
	    half2 cor;
        half pixelation = _Grid*0.1;
        pixelation *= 0.001;
	    cor.x =  uvScaled.x/pixelation;
	    cor.y = (uvScaled.y+pixelation*1.5*glsl_mod(floor(cor.x),2.0))/(pixelation*3.0);
    
	    half2 ico = floor(cor);
	    half2 fco = frac(cor);
    
	    half3 pix = step( 1.5, glsl_mod(half3(0.0,1.0,2.0) + ico.x, 3.0 ));
        //half3 ima = tex2D(_MainTex,pixelation*ico*half2(1.0,3.0)).xyz; 

        half2 ShittyPISSuv = pixelation*ico*half2(1.0,3.0);

	    half3 ima = half3(tex2D(_MainTex,half2(ShittyPISSuv.x + _Chro, ShittyPISSuv.y)).x, tex2D(_MainTex,ShittyPISSuv).y,tex2D(_MainTex,half2(ShittyPISSuv.x - _Chro, ShittyPISSuv.y)).z); 

	    half3 col = pix*dot( pix, ima );

        col *= step( abs(fco.x-0.5), 0.4 );
        col *= step( abs(fco.y-0.5), 0.4 );
    
	    col *= 1.2;
	    fixed4 d = half4(col, 0.0 );
        fixed4 dEmis = half4(col, 0.0 );


        //final distant clean image filtering - shoutout iq
        half2 q = 0.5;
        half3 col2;
        half4 oricol = tex2D(_MainTex, uvScaled.xy);

        //_scanlineSize *= 0.1;
        col2.r = tex2D(_MainTex,half2(uv.x+_Chro,uv.y)).x;
        col2.g = tex2D(_MainTex,half2(uv.x+0.000,uv.y)).y;
        col2.b = tex2D(_MainTex,half2(uv.x-_Chro,uv.y)).z;

        _scanlineSize = lerp(0.8,1,scandist);
        half opScan = glsl_mod(1,_scanlineSize);

        col2 = clamp(col2*0.5+0.5*col2*col2*1.2,0.0,1.0);
        col2 *= 0.5 + 0.5*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y);
        col2 *= half3(_scanlineSize+0.05,_scanlineSize+0.15,_scanlineSize+0.05);
        col2 *= _scanlineSize+opScan*sin(3.0*_Time.y+uv.y*1000.0);
        col2 *= 0.96+0.01*sin(110.0*_Time.y);
        col2 = lerp(col2, oricol.rgb, clamp(-2.0+2.0*q.x+3.0, 0.0, 0.0));

        fixed4 a = fixed4(col2,oricol.a);
        fixed4 aEmis = fixed4(col2,oricol.a);
            if (_ALFlashToggle != 0)
            {
                aEmis *= _ALFlash; dEmis *= _ALFlash; 
            }
            if (_ALFlashToggle == 0)
            {
                aEmis += a * _ALFlash; dEmis += d*_ALFlash; 
            }
 
        half3 preCol = lerp(1, ALcolor, _ALCCIntensity) * _screenBrightness;
            float3 finalcol;
            if (_ALColToggle != 0)
            {
                finalcol = lerp(d, a, alpha)* preCol;
            }
            if (_ALColToggle == 0)
            {
                finalcol = lerp(d, a, alpha)* _screenBrightness;
            }



        float3 finalEmis = (lerp(dEmis, aEmis, alpha)* preCol) * _Emission;
            o.Albedo = finalcol;
            o.Emission = finalEmis;

            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = a.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}