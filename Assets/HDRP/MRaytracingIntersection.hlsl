// #ifndef UNITY_RAYTRACING_INTERSECTION_INCLUDED
// #define UNITY_RAYTRACING_INTERSECTION_INCLUDED
//
// // Engine includes
// #include "UnityRayTracingMeshUtils.cginc"
//
// // Raycone structure that defines the stateof the ray
// struct RayCone
// {
//     float width;
//     float spreadAngle;
// };
//
// // Structure that defines the current state of the visibility
// struct RayIntersectionDebug
// {
//     // Distance of the intersection
//     float t;
//     // Barycentrics of the intersection
//     float2 barycentrics;
//     // Index of the primitive
//     uint primitiveIndex;
//     // Index of the instance
//     uint instanceIndex;
// };
//
// // Structure that defines the current state of the visibility
// struct RayIntersectionVisibility
// {
//     // Distance of the intersection
//     float t;
//     // Velocity for the intersection point
//     float velocity;
//     // Cone representation of the ray
//     RayCone cone;
//     // Pixel coordinate from which the initial ray was launched
//     uint2 pixelCoord;
//     // Value that holds the color of the ray or debug data
//     float3 color;
// };
//
// // Structure that defines the current state of the intersection
// struct RayIntersection
// {
//     // Distance of the intersection
//     float t;
//     // Value that holds the color of the ray
//     float3 color;
//     // Cone representation of the ray
//     RayCone cone;
//     // The remaining available depth for the current Ray
//     uint remainingDepth;
//     // Current sample index
//     uint sampleIndex;
//     // Ray counter (used for multibounce)
//     uint rayCount;
//     // Pixel coordinate from which the initial ray was launched
//     uint2 pixelCoord;
//     // Velocity for the intersection point
//     float velocity;
// };
//
// struct AttributeData
// {
//     // Barycentric value of the intersection
//     float2 barycentrics;
// };
//
// // Macro that interpolate any attribute using barycentric coordinates
// #define INTERPOLATE_RAYTRACING_ATTRIBUTE(A0, A1, A2, BARYCENTRIC_COORDINATES) (A0 * BARYCENTRIC_COORDINATES.x + A1 * BARYCENTRIC_COORDINATES.y + A2 * BARYCENTRIC_COORDINATES.z)
//
// // Structure to fill for intersections
// struct IntersectionVertex
// {
//     // Object space normal of the vertex
//     float3 normalOS;
//     // Object space tangent of the vertex
//     float4 tangentOS;
//     // UV coordinates
//     float4 texCoord0;
//     float4 texCoord1;
//     float4 texCoord2;
//     float4 texCoord3;
//     float4 color;
//
// #ifdef USE_RAY_CONE_LOD
//     // Value used for LOD sampling
//     float  triangleArea;
//     float  texCoord0Area;
//     float  texCoord1Area;
//     float  texCoord2Area;
//     float  texCoord3Area;
// #endif
// };
//
// // Fetch the intersetion vertex data for the target vertex
// void FetchIntersectionVertex(uint vertexIndex, out IntersectionVertex outVertex)
// {
//     outVertex.normalOS   = UnityRayTracingFetchVertexAttribute3(vertexIndex, kVertexAttributeNormal);
//
//     #ifdef ATTRIBUTES_NEED_TANGENT
//     outVertex.tangentOS  = UnityRayTracingFetchVertexAttribute4(vertexIndex, kVertexAttributeTangent);
//     #else
//     outVertex.tangentOS  = 0.0;
//     #endif
//
//     #ifdef ATTRIBUTES_NEED_TEXCOORD0
//     outVertex.texCoord0  = UnityRayTracingFetchVertexAttribute4(vertexIndex, kVertexAttributeTexCoord0);
//     #else
//     outVertex.texCoord0  = 0.0;
//     #endif
//
//     #ifdef ATTRIBUTES_NEED_TEXCOORD1
//
//     outVertex.texCoord1  = UnityRayTracingFetchVertexAttribute4(vertexIndex, UnityRayTracingHasVertexAttribute(kVertexAttributeTexCoord1) ? kVertexAttributeTexCoord1 : kVertexAttributeTexCoord0);
//     #else
//     outVertex.texCoord1  = 0.0;
//     #endif
//
//     #ifdef ATTRIBUTES_NEED_TEXCOORD2
//     outVertex.texCoord2  = UnityRayTracingFetchVertexAttribute4(vertexIndex, UnityRayTracingHasVertexAttribute(kVertexAttributeTexCoord2) ? kVertexAttributeTexCoord2 : kVertexAttributeTexCoord0);
//     #else
//     outVertex.texCoord2  = 0.0;
//     #endif
//
//     #ifdef ATTRIBUTES_NEED_TEXCOORD3
//     outVertex.texCoord3  = UnityRayTracingFetchVertexAttribute4(vertexIndex, UnityRayTracingHasVertexAttribute(kVertexAttributeTexCoord3) ? kVertexAttributeTexCoord3 : kVertexAttributeTexCoord0);
//     #else
//     outVertex.texCoord3  = 0.0;
//     #endif
//
//     #ifdef ATTRIBUTES_NEED_COLOR
//     outVertex.color      = UnityRayTracingFetchVertexAttribute4(vertexIndex, kVertexAttributeColor);
//
//     #else
//     outVertex.color  = 0.0;
//     #endif
// }
//
//
// void GetCurrentIntersectionVertex(AttributeData attributeData, out IntersectionVertex outVertex)
// {
//     // Fetch the indices of the currentr triangle
//     uint3 triangleIndices = UnityRayTracingFetchTriangleIndices(PrimitiveIndex());
//
//     // Fetch the 3 vertices
//     IntersectionVertex v0, v1, v2;
//     FetchIntersectionVertex(triangleIndices.x, v0);
//     FetchIntersectionVertex(triangleIndices.y, v1);
//     FetchIntersectionVertex(triangleIndices.z, v2);
//
//     // Compute the full barycentric coordinates
//     float3 barycentricCoordinates = float3(1.0 - attributeData.barycentrics.x - attributeData.barycentrics.y, attributeData.barycentrics.x, attributeData.barycentrics.y);
//
//     // Interpolate all the data
//     outVertex.normalOS   = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.normalOS, v1.normalOS, v2.normalOS, barycentricCoordinates);
//
//     #ifdef ATTRIBUTES_NEED_TANGENT
//     outVertex.tangentOS  = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.tangentOS, v1.tangentOS, v2.tangentOS, barycentricCoordinates);
//     #else
//     outVertex.tangentOS  = 0.0;
//     #endif
//
//     #ifdef ATTRIBUTES_NEED_TEXCOORD0
//     outVertex.texCoord0  = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.texCoord0, v1.texCoord0, v2.texCoord0, barycentricCoordinates);
//     #else
//     outVertex.texCoord0  = 0.0;
//     #endif
//
//     #ifdef ATTRIBUTES_NEED_TEXCOORD1
//     outVertex.texCoord1  = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.texCoord1, v1.texCoord1, v2.texCoord1, barycentricCoordinates);
//     #else
//     outVertex.texCoord1  = 0.0;
//     #endif
//
//     #ifdef ATTRIBUTES_NEED_TEXCOORD2
//     outVertex.texCoord2  = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.texCoord2, v1.texCoord2, v2.texCoord2, barycentricCoordinates);
//     #else
//     outVertex.texCoord2  = 0.0;
//     #endif
//
//     #ifdef ATTRIBUTES_NEED_TEXCOORD3
//     outVertex.texCoord3  = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.texCoord3, v1.texCoord3, v2.texCoord3, barycentricCoordinates);
//     #else
//     outVertex.texCoord3  = 0.0;
//     #endif
//
//     #ifdef ATTRIBUTES_NEED_COLOR
//     outVertex.color      = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.color, v1.color, v2.color, barycentricCoordinates);
//     #else
//     outVertex.color      = 0.0;
//     #endif
//
// #ifdef USE_RAY_CONE_LOD
//     // Compute the lambda value (area computed in object space)
//     outVertex.triangleArea  = length(cross(v1.positionOS - v0.positionOS, v2.positionOS - v0.positionOS));
//     outVertex.texCoord0Area = abs((v1.texCoord0.x - v0.texCoord0.x) * (v2.texCoord0.y - v0.texCoord0.y) - (v2.texCoord0.x - v0.texCoord0.x) * (v1.texCoord0.y - v0.texCoord0.y));
//     outVertex.texCoord1Area = abs((v1.texCoord1.x - v0.texCoord1.x) * (v2.texCoord1.y - v0.texCoord1.y) - (v2.texCoord1.x - v0.texCoord1.x) * (v1.texCoord1.y - v0.texCoord1.y));
//     outVertex.texCoord2Area = abs((v1.texCoord2.x - v0.texCoord2.x) * (v2.texCoord2.y - v0.texCoord2.y) - (v2.texCoord2.x - v0.texCoord2.x) * (v1.texCoord2.y - v0.texCoord2.y));
//     outVertex.texCoord3Area = abs((v1.texCoord3.x - v0.texCoord3.x) * (v2.texCoord3.y - v0.texCoord3.y) - (v2.texCoord3.x - v0.texCoord3.x) * (v1.texCoord3.y - v0.texCoord3.y));
// #endif
// }
//
// // Compute the proper world space geometric normal from the intersected triangle
// void GetCurrentIntersectionGeometricNormal(AttributeData attributeData, out float3 geomNormalWS)
// {
//     uint3 triangleIndices = UnityRayTracingFetchTriangleIndices(PrimitiveIndex());
//     float3 p0 = UnityRayTracingFetchVertexAttribute3(triangleIndices.x, kVertexAttributePosition);
//     float3 p1 = UnityRayTracingFetchVertexAttribute3(triangleIndices.y, kVertexAttributePosition);
//     float3 p2 = UnityRayTracingFetchVertexAttribute3(triangleIndices.z, kVertexAttributePosition);
//
//     geomNormalWS = normalize(mul(cross(p1 - p0, p2 - p0), (float3x3)WorldToObject3x4()));
// }
//
// #endif // UNITY_RAYTRACING_INTERSECTION_INCLUDED





#ifndef UNITY_RAYTRACING_INTERSECTION_INCLUDED
#define UNITY_RAYTRACING_INTERSECTION_INCLUDED

// Engine includes
#include "UnityRayTracingMeshUtils.cginc"

// Raycone structure that defines the stateof the ray
struct RayCone
{
    float width;
    float spreadAngle;
};

// Structure that defines the current state of the visibility
struct RayIntersectionDebug
{
 
    float t;                // Distance of the intersection
    float2 barycentrics;    // Barycentrics of the intersection
    uint primitiveIndex;
    uint instanceIndex;
};

// Structure that defines the current state of the visibility
struct RayIntersectionVisibility
{
 
    float t;                // Distance of the intersection
    float velocity;            // Velocity for the intersection point
    RayCone cone;            // Cone representation of the ray
    uint2 pixelCoord;        // Pixel coordinate from which the initial ray was launched
    float3 color;            // Value that holds the color of the ray or debug data
};

// Structure that defines the current state of the intersection
struct RayIntersection
{
    float t;                // Distance of the intersection
    float3 color;            // Value that holds the color of the ray
    RayCone cone;            // Cone representation of the ray
    uint remainingDepth;    // The remaining available depth for the current Ray
    uint sampleIndex;
    uint rayCount;
    uint2 pixelCoord;        // Pixel coordinate from which the initial ray was launched
    float velocity;            // Velocity for the intersection point
};

struct AttributeData
{
    float2 barycentrics; // Barycentric value of the intersection
    float3 normalOS; // For RayTraceProcedurally
};

// Macro that interpolate any attribute using barycentric coordinates
#define INTERPOLATE_RAYTRACING_ATTRIBUTE(A0, A1, A2, BARYCENTRIC_COORDINATES) (A0 * BARYCENTRIC_COORDINATES.x + A1 * BARYCENTRIC_COORDINATES.y + A2 * BARYCENTRIC_COORDINATES.z)

// Structure to fill for intersections
struct IntersectionVertex
{
    float3 normalOS;
    float4 tangentOS;
    float4 texCoord0;
    float4 texCoord1;
    float4 texCoord2;
    float4 texCoord3;
    float4 color;
#ifdef USE_RAY_CONE_LOD
    float  triangleArea;
    float  texCoord0Area;
    float  texCoord1Area;
    float  texCoord2Area;
    float  texCoord3Area;
#endif
};


struct AABB
{
    float3 min;
    float3 max;
};

StructuredBuffer<AABB> _AABBs;


void ReadSphere( out float3 pos, out float radius )
{
    AABB aabb = _AABBs[ PrimitiveIndex() ];
    pos = (aabb.min + aabb.max) * 0.5;
    radius = ( aabb.max.x - aabb.min.x ) * 0.5;
}


float HitSphere( float3 center, float radius, float3 ro, float3 rd )
{
    float3 oc = ro - center;
    float a = dot(rd, rd);
    float b = 2.0 * dot(oc, rd);
    float c = dot(oc,oc) - radius*radius;
    float discriminant = b*b - 4*a*c;
    if( discriminant < 0.0 ) {
        return -1.0;
    } else {
        float numerator = -b - sqrt(discriminant);
        return numerator > 0.0 ? numerator / (2.0 * a) : -1;
    }
}


// Fetch the intersetion vertex data for the target vertex
void FetchIntersectionVertex(uint vertexIndex, out IntersectionVertex outVertex)
{
    float3 sphereCenter;
    float sphereRadius;
    ReadSphere( sphereCenter, sphereRadius );

    float3 ro = ObjectRayOrigin();
    float3 rd = ObjectRayDirection();

    float hitDist = HitSphere( sphereCenter, sphereRadius, ro, rd );
    outVertex.normalOS = 0;
    if( hitDist >= 0.0 ) outVertex.normalOS = normalize( ro + hitDist * rd - sphereCenter );

    outVertex.tangentOS  = 0.0;
    outVertex.texCoord0  = 0.0;
    outVertex.texCoord1  = 0.0;
    outVertex.texCoord2  = 0.0;
    outVertex.texCoord3  = 0.0;
    outVertex.color  = 0.0;
}

void GetCurrentIntersectionVertex(AttributeData attributeData, out IntersectionVertex outVertex)
{
    outVertex.normalOS = attributeData.normalOS;

    //float3 rd = ObjectRayOrigin();
    float3 rd = float3( 0, 1, 0 ); // The HDRP does not provide RayIntersection to this function :(

    outVertex.tangentOS  = float4( normalize( cross( cross( attributeData.normalOS, rd ), attributeData.normalOS ) ), 1 );
    outVertex.texCoord0  = 0.0;
    outVertex.texCoord1  = 0.0;
    outVertex.texCoord2  = 0.0;
    outVertex.texCoord3  = 0.0;
    outVertex.color      = 0.0;
}


// Compute the proper world space geometric normal from the intersected triangle
void GetCurrentIntersectionGeometricNormal( AttributeData attr, out float3 geomNormalWS )
{
    geomNormalWS = mul( (float3x3) UNITY_MATRIX_I_M, attr.normalOS ); // World to object attr.normalOS;
}



[shader("intersection")]
void IntersectionMain()
{
    // float3 sphereCenter;
    // float sphereRadius;
    //ReadSphere( sphereCenter, sphereRadius );
    float3 sphereCenter = 0.;
    float sphereRadius = 0.15 * abs(frac(_Time.y/2)-0.5) + 0.2; 

    float3 ro = ObjectRayOrigin();
    float3 rd = ObjectRayDirection();
 
    float hitDist = HitSphere( sphereCenter, sphereRadius, ro, rd );
    if( hitDist >= 0.0 ) {
        AttributeData attr;
        attr.barycentrics = 0.0;
        attr.normalOS = normalize( ro + hitDist * rd - sphereCenter );
        ReportHit( hitDist, 0, attr );
    }
}


#endif // UNITY_RAYTRACING_INTERSECTION_INCLUDED