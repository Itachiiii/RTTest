using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using System.Collections.Generic;

[ExecuteInEditMode]
public class RayTracingProceduralIntersection : MonoBehaviour
{
    public RayTracingShader rayTracingShader = null;

    public Material proceduralMaterial = null;

    private uint cameraWidth = 0;
    private uint cameraHeight = 0;

    private RenderTexture rayTracingOutput = null;

    private RayTracingAccelerationStructure raytracingAccelerationStructure = null;

    private MaterialPropertyBlock properties = null;

    private GraphicsBuffer aabbList = null;
    private GraphicsBuffer aabbColors = null;

    private const int aabbCount = 10;

    public struct AABB
    {
        public Vector3 min;
        public Vector3 max;
    }

    private void CreateRaytracingAccelerationStructure()
    {
        if (raytracingAccelerationStructure == null)
        {
            RayTracingAccelerationStructure.RASSettings settings = new RayTracingAccelerationStructure.RASSettings();
            settings.rayTracingModeMask = RayTracingAccelerationStructure.RayTracingModeMask.Everything;
            settings.managementMode = RayTracingAccelerationStructure.ManagementMode.Manual;
            settings.layerMask = 255;

            raytracingAccelerationStructure = new RayTracingAccelerationStructure(settings);
        }
    }

    private void ReleaseResources()
    {
        if (raytracingAccelerationStructure != null)
        {
            raytracingAccelerationStructure.Release();
            raytracingAccelerationStructure = null;
        }

        if (rayTracingOutput)
        {
            rayTracingOutput.Release();
            rayTracingOutput = null;
        }

        if (aabbList != null)
        {
            aabbList.Release();
            aabbList = null;
        }

        if (aabbColors != null)
        {
            aabbColors.Release();
            aabbColors = null;
        }

        cameraWidth = 0;
        cameraHeight = 0;
    }

    private void CreateResources()
    {
        CreateRaytracingAccelerationStructure();

        if (cameraWidth != Camera.main.pixelWidth || cameraHeight != Camera.main.pixelHeight)
        {
            if (rayTracingOutput)
                rayTracingOutput.Release();

            rayTracingOutput = new RenderTexture(Camera.main.pixelWidth, Camera.main.pixelHeight, 0, RenderTextureFormat.ARGBHalf);
            rayTracingOutput.enableRandomWrite = true;
            rayTracingOutput.Create();

            cameraWidth = (uint)Camera.main.pixelWidth;
            cameraHeight = (uint)Camera.main.pixelHeight;
        }

        if (aabbList == null)
        {
            aabbList = new GraphicsBuffer(GraphicsBuffer.Target.Structured, aabbCount, 6 * sizeof(float));

            AABB[] aabbs = new AABB[aabbCount];
            for (int i = 0; i < aabbCount; i++)
            {
                AABB aabb = new AABB();

                Vector3 center = new Vector3(-4 + 8 * (float)i / (float)(aabbCount - 1), 0, 4);
                Vector3 size = new Vector3(0.2f, 6.0f, 0.2f);

                aabb.min = center - size;
                aabb.max = center + size;

                aabbs[i] = aabb;
            }
            aabbList.SetData(aabbs);
        }

        if (aabbColors == null)
        {
            aabbColors = new GraphicsBuffer(GraphicsBuffer.Target.Structured, aabbCount, 4 * sizeof(float));

            Color[] colors = new Color[aabbCount];

            for (int i = 0; i < aabbCount; i++)
            {
                colors[i] = new Vector4(1.0f - (i / (float)(aabbCount - 1)), i / (float)(aabbCount - 1), 0, 1);
            }

            aabbColors.SetData(colors);
        }

        if (properties == null)
        {
            properties = new MaterialPropertyBlock();
        }
    }

    void OnDestroy()
    {
        ReleaseResources();
    }

    void OnDisable()
    {
        ReleaseResources();
    }

    private void Update()
    {
        CreateResources();
    }

    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (!SystemInfo.supportsRayTracing)
        {
            Debug.Log("The RayTracing API is not supported by this GPU or by the current graphics API.");
            Graphics.Blit(src, dest);
            return;
        }
        
        if (rayTracingShader == null)
        {
            Debug.Log("Please set a RayTracingShader (check Main Camera).");
            Graphics.Blit(src, dest);
            return;
        }
        
        if (proceduralMaterial == null)
        {
            Debug.Log("Please set a Material for procedural AABBs (check Main Camera).");
            Graphics.Blit(src, dest);
            return;
        }
        
        if (raytracingAccelerationStructure == null)
            return;
        
        CommandBuffer cmdBuffer = new CommandBuffer();
        
        raytracingAccelerationStructure.ClearInstances();
        
        List<Material> materials = new List<Material>();
        
        MeshRenderer[] renderers = FindObjectsOfType<MeshRenderer>();
        foreach (MeshRenderer r in renderers)
        {
            r.GetSharedMaterials(materials);
        
            int matCount = Mathf.Max(materials.Count, 1);
        
            RayTracingSubMeshFlags[] subMeshFlags = new RayTracingSubMeshFlags[matCount];
        
            // Assume all materials are opaque (anyhit shader is disabled) otherwise Material types (opaque, transparent) must be handled here.
            for (int i = 0; i < matCount; i++)
                subMeshFlags[i] = RayTracingSubMeshFlags.Enabled | RayTracingSubMeshFlags.ClosestHitOnly;
        
            raytracingAccelerationStructure.AddInstance(r, subMeshFlags);
        }
        
        properties.SetBuffer("g_AABBs", aabbList);
        properties.SetBuffer("g_Colors", aabbColors);
        
        // Create a procedural geometry instance based on a AABB list. The GraphicsBuffer contains static data.
        raytracingAccelerationStructure.AddInstance(aabbList, aabbCount, false, Matrix4x4.identity, proceduralMaterial, true, properties);
        
        cmdBuffer.BuildRayTracingAccelerationStructure(raytracingAccelerationStructure);
        
        cmdBuffer.SetRayTracingShaderPass(rayTracingShader, "Test");
        
        // Input
        cmdBuffer.SetRayTracingAccelerationStructure(rayTracingShader, Shader.PropertyToID("g_SceneAccelStruct"), raytracingAccelerationStructure);
        cmdBuffer.SetRayTracingMatrixParam(rayTracingShader, Shader.PropertyToID("g_InvViewMatrix"), Camera.main.cameraToWorldMatrix);
        cmdBuffer.SetRayTracingFloatParam(rayTracingShader, Shader.PropertyToID("g_Zoom"), Mathf.Tan(Mathf.Deg2Rad * Camera.main.fieldOfView * 0.5f));
        
        // Output
        cmdBuffer.SetRayTracingTextureParam(rayTracingShader, Shader.PropertyToID("g_Output"), rayTracingOutput);
        
        cmdBuffer.DispatchRays(rayTracingShader, "MainRayGenShader", cameraWidth, cameraHeight, 1);
        
        Graphics.ExecuteCommandBuffer(cmdBuffer);
        
        cmdBuffer.Release();
        
        Graphics.Blit(rayTracingOutput, dest);
        
    }
}
