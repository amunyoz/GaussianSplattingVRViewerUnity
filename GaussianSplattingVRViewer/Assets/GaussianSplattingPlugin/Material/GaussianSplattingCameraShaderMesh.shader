Shader"GaussianSplatting/CameraShaderMesh"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _GaussianSplattingTexLeftEye("Left Eye", 2D) = "white" {}
        _GaussianSplattingTexRightEye("Right Eye", 2D) = "white" {}
    }
    SubShader
    {
Cull Off

ZWrite Off

ZTest LEqual

Blend SrcAlpha OneMinusSrcAlpha
//Blend One One 

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

#include "UnityCG.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
};

v2f vert(appdata v)
{
    v2f o;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;
    
    return o;
}

sampler2D _GaussianSplattingTexLeftEye;
sampler2D _GaussianSplattingTexRightEye;
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);
half4 _MainTex_ST;


fixed4 frag(v2f i) : SV_Target
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
    
    fixed4 gcol = fixed4(0, 0, 0, 1);
    if (unity_StereoEyeIndex == 0)
    {
        gcol = tex2D(_GaussianSplattingTexLeftEye, i.uv);
    }
    else
    {
        gcol = tex2D(_GaussianSplattingTexRightEye, i.uv);
    }

    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
    float currentDepth = Linear01Depth(i.vertex.z / i.vertex.w);

#if defined(UNITY_REVERSED_Z)
    currentDepth = 1.0f - currentDepth;
    depth = 1.0f - depth;
#endif

    // Si la profundidad del splat es menor o igual a la profundidad almacenada, mostramos el splat.
    if (currentDepth <= depth)
    {
        return gcol;
    }
    else
    {
        return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, UnityStereoScreenSpaceUVAdjust(i.uv, _MainTex_ST));
    }
}

            ENDCG
        }
    }
}
