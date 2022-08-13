using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CombineMesh : MonoBehaviour
{
    void Start()
    {
        MeshFilter[] filters = GetComponentsInChildren<MeshFilter>();
        MeshRenderer[] renderers = GetComponentsInChildren<MeshRenderer>();
        CombineInstance[] combines = new CombineInstance[filters.Length];
        Material[] materials = new Material[filters.Length];

        for(int i = 0; i < filters.Length; i++)
        {
            materials[i] = renderers[i].material;
            combines[i].mesh = filters[i].mesh;
            combines[i].transform = filters[i].transform.localToWorldMatrix;

            renderers[i].enabled = false;
            if (filters[i].gameObject != this.gameObject)
                Destroy(filters[i].gameObject);
        }

        transform.GetComponent<MeshFilter>().mesh = new Mesh();
        //公用一个Material的时候mergeSubMeshes为true
        transform.GetComponent<MeshFilter>().mesh.CombineMeshes(combines, false);
        transform.GetComponent<MeshRenderer>().materials = materials;
        transform.GetComponent<MeshRenderer>().enabled = true;
    }
}
